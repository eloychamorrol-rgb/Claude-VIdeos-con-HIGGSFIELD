import Foundation

public enum InsightKind: Int, Comparable, Codable, Sendable {
    case alert = 0, warning, info, positive

    public static func < (lhs: InsightKind, rhs: InsightKind) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct Insight: Identifiable, Hashable, Sendable {
    public let id: String
    public let kind: InsightKind
    public let title: String
    public let message: String
    public let symbol: String
    public let categoryId: String?

    public init(id: String, kind: InsightKind, title: String, message: String, symbol: String, categoryId: String? = nil) {
        self.id = id
        self.kind = kind
        self.title = title
        self.message = message
        self.symbol = symbol
        self.categoryId = categoryId
    }
}

public struct HealthScore: Sendable {
    public struct Component: Identifiable, Hashable, Sendable {
        public var id: String { name }
        public let name: String
        public let points: Int
        public let maxPoints: Int
        public let detail: String
    }

    public let score: Int
    public let components: [Component]

    public var label: String {
        switch score {
        case 80...: return "Excelente"
        case 65..<80: return "Buena"
        case 45..<65: return "Regular"
        default: return "Necesita atención"
        }
    }
}

public struct BudgetStatus: Identifiable, Hashable, Sendable {
    public var id: String { budget.categoryId }
    public let budget: Budget
    public let spent: Pesos
    public let projected: Pesos
    public var progress: Double { budget.monthlyLimit > 0 ? Double(spent) / Double(budget.monthlyLimit) : 0 }
    public var remaining: Pesos { budget.monthlyLimit - spent }
}

public struct BudgetLine: Identifiable, Hashable, Sendable {
    public var id: String { categoryId }
    public let categoryId: String
    public let group: CategoryGroup
    public let average: Pesos
    public let suggested: Pesos
}

public struct BudgetPlan: Sendable {
    public let income: Pesos
    public let rule: SplitRule
    public let needsTarget: Pesos
    public let wantsTarget: Pesos
    public let savingsTarget: Pesos
    public let lines: [BudgetLine]

    public var totalSuggested: Pesos { lines.reduce(0) { $0 + $1.suggested } }
    public var projectedSavings: Pesos { income - totalSuggested }
}

public struct SplitBreakdown: Hashable, Sendable {
    public let income: Pesos
    public let needs: Pesos
    public let wants: Pesos
    /// Lo que queda (ingresos - necesidades - deseos).
    public var savings: Pesos { income - needs - wants }
    public var needsShare: Double { income > 0 ? Double(needs) / Double(income) : 0 }
    public var wantsShare: Double { income > 0 ? Double(wants) / Double(income) : 0 }
    public var savingsShare: Double { income > 0 ? Double(savings) / Double(income) : 0 }
}

public struct AdvisorInput: Sendable {
    public var transactions: [Transaction]
    public var accounts: [Account]
    public var budgets: [Budget]
    public var goals: [SavingsGoal]
    public var profile: UserProfile
    public var now: Date

    public init(transactions: [Transaction], accounts: [Account], budgets: [Budget], goals: [SavingsGoal] = [],
                profile: UserProfile, now: Date = Date()) {
        self.transactions = transactions
        self.accounts = accounts
        self.budgets = budgets
        self.goals = goals
        self.profile = profile
        self.now = now
    }
}

/// Asesor financiero basado en reglas transparentes. Recomendaciones educativas, no asesoría regulada.
public struct FinancialAdvisor: Sendable {
    public let engine: AnalyticsEngine
    public let recurring: RecurringDetector
    public let anomalies: AnomalyDetector

    public init(engine: AnalyticsEngine) {
        self.engine = engine
        self.recurring = RecurringDetector(engine: engine)
        self.anomalies = AnomalyDetector(engine: engine)
    }

    private var calendar: FinanceCalendar { engine.calendar }

    // MARK: Datos base

    /// Meses completos recientes (hasta 3) que tienen movimientos.
    public func referenceMonths(_ transactions: [Transaction], now: Date) -> [Period] {
        calendar.completedMonths(before: now, count: 3).filter { month in
            transactions.contains { month.contains($0.date) }
        }
    }

    public func estimatedMonthlyIncome(_ input: AdvisorInput) -> Pesos? {
        if let declared = input.profile.declaredMonthlyIncome, declared > 0 { return declared }
        let incomes = referenceMonths(input.transactions, now: input.now)
            .map { engine.summary(of: input.transactions, in: $0, now: input.now).income }
            .filter { $0 > 0 }
        guard !incomes.isEmpty else { return nil }
        return incomes.reduce(0, +) / incomes.count
    }

    /// Distribución real del último mes completo con datos (o del mes en curso si no hay historial).
    public func split(_ input: AdvisorInput) -> SplitBreakdown? {
        let month = referenceMonths(input.transactions, now: input.now).last
            ?? calendar.period(.month, containing: input.now)
        let summary = engine.summary(of: input.transactions, in: month, now: input.now)
        let income = summary.income > 0 ? summary.income : (estimatedMonthlyIncome(input) ?? 0)
        guard income > 0 else { return nil }
        return SplitBreakdown(income: income, needs: summary.needs, wants: summary.wants)
    }

    public func averageMonthlyNeeds(_ input: AdvisorInput) -> Pesos {
        let months = referenceMonths(input.transactions, now: input.now)
        guard !months.isEmpty else { return 0 }
        let total = months.reduce(0) { $0 + engine.summary(of: input.transactions, in: $1, now: input.now).needs }
        return total / months.count
    }

    public func liquidBalance(_ accounts: [Account]) -> Pesos? {
        let liquid = accounts.filter { $0.kind.isLiquid && !$0.isHidden && $0.currency == engine.currency }
        let balances = liquid.compactMap { $0.availableBalance ?? $0.balance }
        guard !balances.isEmpty else { return nil }
        return balances.reduce(0, +)
    }

    public func budgetStatuses(_ input: AdvisorInput) -> [BudgetStatus] {
        let month = calendar.period(.month, containing: input.now)
        let summary = engine.summary(of: input.transactions, in: month, now: input.now)
        let spentByCategory = Dictionary(uniqueKeysWithValues: summary.byCategory.map { ($0.categoryId, $0.amount) })
        return input.budgets.filter { $0.monthlyLimit > 0 }.map { budget in
            let spent = spentByCategory[budget.categoryId] ?? 0
            let projected = summary.projectedByCategory[budget.categoryId] ?? spent
            return BudgetStatus(budget: budget, spent: spent, projected: projected)
        }
        .sorted { $0.progress > $1.progress }
    }

    // MARK: Plan de presupuesto

    public func suggestedPlan(_ input: AdvisorInput) -> BudgetPlan? {
        guard let income = estimatedMonthlyIncome(input), income > 0 else { return nil }
        let rule = input.profile.splitRule.isValid ? input.profile.splitRule : .fiftyThirtyTwenty
        let months = referenceMonths(input.transactions, now: input.now)
        let averages: [String: Pesos]
        if months.isEmpty {
            // Sin historial completo: se usa el mes en curso proyectado.
            let current = engine.summary(of: input.transactions, in: calendar.period(.month, containing: input.now), now: input.now)
            averages = current.projectedByCategory
        } else {
            averages = engine.averageMonthlySpending(input.transactions, months: months)
        }

        let needsTarget = Int(Double(income) * rule.needs)
        let wantsTarget = Int(Double(income) * rule.wants)
        let savingsTarget = income - needsTarget - wantsTarget

        let positive = averages.filter { $0.value > 0 }
        let needs = positive.filter { engine.category($0.key).group == .needs }
        let wants = positive.filter { engine.category($0.key).group == .wants }

        var lines: [BudgetLine] = []

        // Necesidades: los gastos fijos se mantienen; los flexibles se ajustan al espacio disponible.
        let fixed = needs.filter { CategoryCatalog.fixedNeeds.contains($0.key) }
        let flexible = needs.filter { !CategoryCatalog.fixedNeeds.contains($0.key) }
        let fixedTotal = fixed.values.reduce(0, +)
        let flexibleTotal = flexible.values.reduce(0, +)
        let flexibleRoom = max(0, needsTarget - fixedTotal)
        let flexibleFactor = flexibleTotal > flexibleRoom && flexibleTotal > 0
            ? max(0.8, Double(flexibleRoom) / Double(flexibleTotal)) : 1
        for (id, average) in fixed {
            lines.append(BudgetLine(categoryId: id, group: .needs, average: average, suggested: roundUp(average)))
        }
        for (id, average) in flexible {
            lines.append(BudgetLine(categoryId: id, group: .needs, average: average,
                                    suggested: roundUp(Int(Double(average) * flexibleFactor))))
        }

        // Deseos: se recortan proporcionalmente si superan la meta (como máximo a la mitad).
        let wantsTotal = wants.values.reduce(0, +)
        let wantsFactor = wantsTotal > wantsTarget && wantsTotal > 0
            ? max(0.5, Double(wantsTarget) / Double(wantsTotal)) : 1
        for (id, average) in wants {
            lines.append(BudgetLine(categoryId: id, group: .wants, average: average,
                                    suggested: roundUp(Int(Double(average) * wantsFactor))))
        }

        lines.sort { $0.group != $1.group ? $0.group == .needs : ($0.suggested != $1.suggested ? $0.suggested > $1.suggested : $0.categoryId < $1.categoryId) }
        return BudgetPlan(income: income, rule: rule, needsTarget: needsTarget, wantsTarget: wantsTarget,
                          savingsTarget: savingsTarget, lines: lines)
    }

    /// Redondea hacia arriba a miles.
    func roundUp(_ value: Pesos) -> Pesos {
        guard value > 0 else { return 0 }
        return ((value + 999) / 1_000) * 1_000
    }

    // MARK: Puntaje

    public func healthScore(_ input: AdvisorInput) -> HealthScore? {
        guard let income = estimatedMonthlyIncome(input), income > 0, let split = split(input) else { return nil }
        var components: [HealthScore.Component] = []

        let rate = split.savingsShare
        let savingsPoints = Int((min(max(rate, 0), 0.2) / 0.2 * 30).rounded())
        components.append(.init(name: "Tasa de ahorro", points: savingsPoints, maxPoints: 30,
                                detail: "Ahorras \(MoneyFormat.percent(max(rate, 0))) de tus ingresos (meta: 20 %)."))

        let needsShare = split.needsShare
        let needsPoints = needsShare <= 0.5 ? 20 : Int((max(0, 0.8 - needsShare) / 0.3 * 20).rounded())
        components.append(.init(name: "Gastos esenciales", points: needsPoints, maxPoints: 20,
                                detail: "Las necesidades usan \(MoneyFormat.percent(needsShare)) de tus ingresos (ideal: 50 % o menos)."))

        let monthlyNeeds = averageMonthlyNeeds(input)
        let emergencyPoints: Int
        let emergencyDetail: String
        if let liquid = liquidBalance(input.accounts), monthlyNeeds > 0 {
            let months = Double(liquid) / Double(monthlyNeeds)
            emergencyPoints = Int((min(max(months, 0), 6) / 6 * 20).rounded())
            emergencyDetail = "Tu saldo disponible cubre \(MoneyFormat.decimal(max(months, 0))) meses de gastos esenciales (meta: 6)."
        } else {
            emergencyPoints = 10
            emergencyDetail = "Conecta tus cuentas con saldo para medir tu fondo de emergencia."
        }
        components.append(.init(name: "Fondo de emergencia", points: emergencyPoints, maxPoints: 20, detail: emergencyDetail))

        let months = referenceMonths(input.transactions, now: input.now)
        let debtAverage = engine.averageMonthlySpending(input.transactions, months: months)
        let debtLoad = Double((debtAverage[CategoryID.debt] ?? 0) + (debtAverage[CategoryID.bankFees] ?? 0)) / Double(income)
        let debtPoints = Int((max(0, 0.35 - debtLoad) / 0.35 * 15).rounded())
        components.append(.init(name: "Deudas y comisiones", points: debtPoints, maxPoints: 15,
                                detail: "Créditos, intereses y comisiones equivalen al \(MoneyFormat.percent(debtLoad)) de tus ingresos."))

        let statuses = budgetStatuses(input)
        let budgetPoints: Int
        let budgetDetail: String
        if statuses.isEmpty {
            budgetPoints = 7
            budgetDetail = "Define presupuestos para medir cuánto los cumples."
        } else {
            let ok = statuses.filter { $0.projected <= $0.budget.monthlyLimit }.count
            budgetPoints = Int((Double(ok) / Double(statuses.count) * 15).rounded())
            budgetDetail = "Vas dentro de \(ok) de \(statuses.count) presupuestos este mes."
        }
        components.append(.init(name: "Presupuestos", points: budgetPoints, maxPoints: 15, detail: budgetDetail))

        let total = components.reduce(0) { $0 + $1.points }
        return HealthScore(score: min(100, max(0, total)), components: components)
    }

    // MARK: Conclusiones

    public func insights(_ input: AdvisorInput) -> [Insight] {
        var insights: [Insight] = []
        let now = input.now
        let currentMonth = calendar.period(.month, containing: now)
        let current = engine.summary(of: input.transactions, in: currentMonth, now: now,
                                     smallExpenseThreshold: input.profile.smallExpenseThreshold)
        let income = estimatedMonthlyIncome(input)
        let rule = input.profile.splitRule.isValid ? input.profile.splitRule : .fiftyThirtyTwenty
        let charges = recurring.detect(input.transactions, now: now)

        if input.transactions.isEmpty {
            return [Insight(id: "empty", kind: .info, title: "Conecta tu banco para empezar",
                            message: "Con al menos un mes de movimientos podré mostrarte en qué se va tu dinero y cómo mejorar.",
                            symbol: "building.columns")]
        }

        // 1. Proyección del mes.
        if let projected = current.projectedSpending, let income, income > 0, current.elapsedDays >= 7 {
            let projectedTotal = projected + current.savingsTransfers
            if projectedTotal > income {
                insights.append(Insight(
                    id: "projection-deficit", kind: .alert, title: "Vas camino a gastar más de lo que ganas",
                    message: "A este ritmo cerrarás \(calendar.title(for: currentMonth, now: now).lowercased()) con salidas por \(MoneyFormat.clp(projectedTotal)), \(MoneyFormat.clp(projectedTotal - income)) sobre tu ingreso de \(MoneyFormat.clp(income)). Te quedan \(current.totalDays - current.elapsedDays) días: apunta a no superar \(MoneyFormat.clp(max(0, (income - current.spending - current.savingsTransfers) / max(1, current.totalDays - current.elapsedDays)))) diarios.",
                    symbol: "exclamationmark.triangle.fill"))
            }
        }

        // 2. Tasa de ahorro y distribución.
        if let split = split(input) {
            let rate = split.savingsShare
            if rate < 0 {
                insights.append(Insight(id: "savings-negative", kind: .alert, title: "Gastaste más de lo que ingresó",
                                        message: "El último mes tus gastos superaron tus ingresos en \(MoneyFormat.clp(-split.savings)). Revisa los deseos y gastos variables primero; las deudas de consumo para cubrir el mes encarecen todo.",
                                        symbol: "arrow.down.right.circle.fill"))
            } else if rate < 0.1 {
                insights.append(Insight(id: "savings-low", kind: .warning, title: "Tu tasa de ahorro es baja",
                                        message: "Ahorraste \(MoneyFormat.percent(rate)) de tus ingresos. Una buena meta es \(MoneyFormat.percent(rule.savings)): \(MoneyFormat.clp(Int(Double(split.income) * rule.savings))) al mes. Prueba transferirlo apenas recibas el sueldo.",
                                        symbol: "banknote"))
            } else if rate >= rule.savings {
                insights.append(Insight(id: "savings-good", kind: .positive, title: "Buen nivel de ahorro",
                                        message: "Ahorraste \(MoneyFormat.percent(rate)) de tus ingresos el último mes, sobre la meta de \(MoneyFormat.percent(rule.savings)) de tu regla \(rule.name).",
                                        symbol: "checkmark.seal.fill"))
            }
            if split.wantsShare > rule.wants + 0.05 {
                let excess = split.wants - Int(Double(split.income) * rule.wants)
                insights.append(Insight(id: "wants-high", kind: .warning, title: "Los deseos pesan más de lo recomendado",
                                        message: "Destinas \(MoneyFormat.percent(split.wantsShare)) a deseos (restaurantes, compras, entretención…), sobre el \(MoneyFormat.percent(rule.wants)) ideal. Recortar \(MoneyFormat.clp(excess)) al mes te dejaría en rango.",
                                        symbol: "cup.and.saucer.fill"))
            }
            if split.needsShare > rule.needs + 0.1 {
                insights.append(Insight(id: "needs-high", kind: .info, title: "Tus gastos esenciales son altos",
                                        message: "Las necesidades consumen \(MoneyFormat.percent(split.needsShare)) de tus ingresos. Revisa planes de telefonía e internet, compara seguros y, si arriendas, evalúa el costo de vivienda frente a tu ingreso.",
                                        symbol: "house"))
            }
        }

        // 3. Suscripciones.
        let subscriptions = charges.filter { $0.isActive && $0.isSubscription }
        if !subscriptions.isEmpty {
            let monthly = subscriptions.reduce(0) { $0 + $1.monthlyCost }
            let heavy = (income ?? 0) > 0 && Double(monthly) / Double(income ?? 1) > 0.03
            var names = subscriptions.prefix(4).map(\.merchant).joined(separator: ", ")
            if subscriptions.count > 4 { names += " y \(subscriptions.count - 4) más" }
            insights.append(Insight(id: "subscriptions", kind: heavy ? .warning : .info,
                                    title: "\(subscriptions.count) suscripciones activas",
                                    message: "Pagas \(MoneyFormat.clp(monthly)) al mes (\(MoneyFormat.clp(monthly * 12)) al año) en \(names). Cancela las que no usaste en el último mes o compártelas en plan familiar.",
                                    symbol: "play.rectangle.on.rectangle", categoryId: CategoryID.subscriptions))
        }

        // 4. Gastos hormiga.
        let small = current.smallExpenses
        if small.count >= 8, current.elapsedDays > 0 {
            let projectedMonthly = Int(Double(small.total) / Double(current.elapsedDays) * Double(current.totalDays))
            let relevant = small.total >= 30_000 || ((income ?? 0) > 0 && Double(projectedMonthly) / Double(income ?? 1) > 0.03)
            if relevant {
                insights.append(Insight(id: "small-expenses", kind: .warning, title: "Gastos hormiga",
                                        message: "Llevas \(small.count) compras de menos de \(MoneyFormat.clp(small.threshold)) en cafés, snacks y similares este mes, por \(MoneyFormat.clp(small.total)). Al año serían cerca de \(MoneyFormat.clp(projectedMonthly * 12)).",
                                        symbol: "ant.fill"))
            }
        }

        // 5. Delivery vs supermercado.
        let delivery = current.byCategory.first { $0.categoryId == CategoryID.delivery }?.amount ?? 0
        let groceries = current.byCategory.first { $0.categoryId == CategoryID.groceries }?.amount ?? 0
        if delivery >= 20_000, Double(delivery) > Double(delivery + groceries) * 0.3 {
            insights.append(Insight(id: "delivery", kind: .info, title: "Mucho delivery",
                                    message: "Este mes llevas \(MoneyFormat.clp(delivery)) en delivery, \(MoneyFormat.percent(Double(delivery) / Double(delivery + groceries))) de lo que gastas en comida. Cocinar dos veces más por semana suele ahorrar más de la mitad de ese monto.",
                                    symbol: "bag.fill", categoryId: CategoryID.delivery))
        }

        // 6. Comisiones bancarias y deuda.
        let months = referenceMonths(input.transactions, now: now)
        let averages = engine.averageMonthlySpending(input.transactions, months: months)
        let fees = (averages[CategoryID.bankFees] ?? 0) * max(1, months.count)
        if fees > 0 {
            insights.append(Insight(id: "fees", kind: .warning, title: "Estás pagando comisiones",
                                    message: "En los últimos \(max(1, months.count)) meses pagaste \(MoneyFormat.clp(fees)) en comisiones y mantención. Pide a tu banco eximirte o considera una cuenta sin costo de mantención.",
                                    symbol: "building.columns.fill", categoryId: CategoryID.bankFees))
        }
        if let income, income > 0 {
            let debt = averages[CategoryID.debt] ?? 0
            let load = Double(debt) / Double(income)
            if load > 0.25 {
                insights.append(Insight(id: "debt-high", kind: .alert, title: "Carga financiera alta",
                                        message: "Tus créditos e intereses equivalen al \(MoneyFormat.percent(load)) de tu ingreso. Sobre 25 % es riesgoso: prioriza pagar primero la deuda con mayor tasa (avalancha), evita avances en efectivo y consulta por refinanciar o consolidar.",
                                        symbol: "creditcard.trianglebadge.exclamationmark", categoryId: CategoryID.debt))
            } else if load > 0.15 {
                insights.append(Insight(id: "debt-medium", kind: .warning, title: "Ojo con los créditos",
                                        message: "Destinas \(MoneyFormat.percent(load)) de tu ingreso a créditos e intereses. Evita sumar nuevas cuotas hasta bajar de 15 %.",
                                        symbol: "creditcard", categoryId: CategoryID.debt))
            }
        }

        // 7. Alzas por categoría (las explicadas por un gasto inusual se informan en el punto 12).
        let unusual = anomalies.unusualTransactions(input.transactions, in: currentMonth)
        let explained = Set(unusual.map(\.transaction.categoryId))
        for spike in anomalies.categorySpikes(input.transactions, month: currentMonth, now: now)
            .filter({ !explained.contains($0.categoryId) }).prefix(3) {
            let name = engine.category(spike.categoryId).name
            insights.append(Insight(id: "spike-\(spike.categoryId)", kind: .warning, title: "\(name) subió \(MoneyFormat.change(spike.change))",
                                    message: "Este mes apuntas a \(MoneyFormat.clp(spike.current)) en \(name.lowercased()), versus \(MoneyFormat.clp(spike.baseline)) promedio de los meses anteriores.",
                                    symbol: "chart.line.uptrend.xyaxis", categoryId: spike.categoryId))
        }

        // 8. Presupuestos.
        for status in budgetStatuses(input) {
            let name = engine.category(status.budget.categoryId).name
            if status.progress >= 1 {
                insights.append(Insight(id: "budget-over-\(status.id)", kind: .alert, title: "Superaste el presupuesto de \(name.lowercased())",
                                        message: "Llevas \(MoneyFormat.clp(status.spent)) de \(MoneyFormat.clp(status.budget.monthlyLimit)) (\(MoneyFormat.percent(status.progress))).",
                                        symbol: "xmark.octagon.fill", categoryId: status.id))
            } else if status.progress >= 0.8 {
                insights.append(Insight(id: "budget-near-\(status.id)", kind: .warning, title: "Presupuesto de \(name.lowercased()) al \(MoneyFormat.percent(status.progress))",
                                        message: "Te quedan \(MoneyFormat.clp(status.remaining)) para lo que resta del mes.",
                                        symbol: "gauge.with.dots.needle.67percent", categoryId: status.id))
            } else if status.projected > status.budget.monthlyLimit, current.elapsedDays >= 7 {
                insights.append(Insight(id: "budget-pace-\(status.id)", kind: .info, title: "\(name) va rápido",
                                        message: "Al ritmo actual cerrarías el mes en \(MoneyFormat.clp(status.projected)), sobre tu presupuesto de \(MoneyFormat.clp(status.budget.monthlyLimit)).",
                                        symbol: "speedometer", categoryId: status.id))
            }
        }
        if input.budgets.isEmpty, !months.isEmpty {
            insights.append(Insight(id: "no-budgets", kind: .info, title: "Crea tu primer presupuesto",
                                    message: "Preparé un plan según tu historial y tu regla \(rule.name). Aplicarlo te avisará antes de pasarte.",
                                    symbol: "list.bullet.clipboard"))
        }

        // 9. Fondo de emergencia.
        let monthlyNeeds = averageMonthlyNeeds(input)
        if let liquid = liquidBalance(input.accounts), monthlyNeeds > 0 {
            let coverage = Double(liquid) / Double(monthlyNeeds)
            if coverage < 3 {
                let target = monthlyNeeds * 3
                insights.append(Insight(id: "emergency-low", kind: input.profile.goal == .emergencyFund ? .warning : .info,
                                        title: "Fondo de emergencia bajo",
                                        message: "Tu saldo disponible cubre \(MoneyFormat.decimal(max(coverage, 0))) meses de gastos esenciales. Lo recomendado son 3 a 6 meses (\(MoneyFormat.clp(target)) – \(MoneyFormat.clp(monthlyNeeds * 6))), idealmente en un instrumento líquido como un fondo mutuo de money market o depósito a plazo renovable.",
                                        symbol: "lifepreserver"))
            } else if coverage >= 6 {
                insights.append(Insight(id: "emergency-good", kind: .positive, title: "Fondo de emergencia cubierto",
                                        message: "Tienes \(MoneyFormat.decimal(coverage)) meses de gastos esenciales disponibles. El excedente podría rendir más invertido a largo plazo (por ejemplo, APV o fondos indexados).",
                                        symbol: "lifepreserver.fill"))
            }
        }

        // 10. Fin de semana.
        let reference = months.last.map { engine.summary(of: input.transactions, in: $0, now: now) } ?? current
        let weekendDays = reference.byWeekday.filter { $0.weekday >= 5 }
        let weekDays = reference.byWeekday.filter { $0.weekday < 5 }
        let weekendAvg = weekendDays.reduce(0) { $0 + $1.averagePerDay } / max(1, weekendDays.count)
        let weekAvg = weekDays.reduce(0) { $0 + $1.averagePerDay } / max(1, weekDays.count)
        if weekAvg > 0, Double(weekendAvg) > Double(weekAvg) * 1.6, weekendAvg - weekAvg >= 10_000 {
            insights.append(Insight(id: "weekend", kind: .info, title: "Los fines de semana gastas más",
                                    message: "Un día de fin de semana te cuesta en promedio \(MoneyFormat.clp(weekendAvg)), contra \(MoneyFormat.clp(weekAvg)) un día hábil. Planificar panoramas con un monto fijo ayuda a controlarlo.",
                                    symbol: "calendar"))
        }

        // 11. Próximos cobros.
        let upcoming = recurring.upcoming(charges, now: now, days: 7)
        if !upcoming.isEmpty {
            let total = upcoming.reduce(0) { $0 + $1.typicalAmount }
            let detail = upcoming.prefix(4).map { "\($0.merchant) (\(calendar.shortDate($0.nextDate)))" }.joined(separator: ", ")
            insights.append(Insight(id: "upcoming", kind: .info, title: "Cobros de los próximos 7 días",
                                    message: "Se esperan cerca de \(MoneyFormat.clp(total)): \(detail).",
                                    symbol: "calendar.badge.clock"))
        }

        // 12. Movimientos inusuales.
        for unusual in unusual.prefix(2) {
            let tx = unusual.transaction
            insights.append(Insight(id: "unusual-\(tx.id)", kind: .info, title: "Gasto inusual en \(tx.merchant)",
                                    message: "\(MoneyFormat.clp(-tx.amount)) el \(calendar.shortDate(tx.date)), \(MoneyFormat.decimal(unusual.ratio)) veces lo habitual en \(engine.category(tx.categoryId).name.lowercased()). Si no lo reconoces, contacta a tu banco.",
                                    symbol: "eye.fill", categoryId: tx.categoryId))
        }

        // 13. Movimientos sin clasificar.
        let unclassified = current.byCategory
            .filter { $0.categoryId == CategoryID.otherExpense || $0.categoryId == CategoryID.transfersOut }
            .reduce(0) { $0 + $1.amount }
        if current.spending > 0, Double(unclassified) / Double(current.spending) > 0.2 {
            insights.append(Insight(id: "unclassified", kind: .info, title: "Clasifica tus transferencias",
                                    message: "\(MoneyFormat.percent(Double(unclassified) / Double(current.spending))) de tus gastos del mes son transferencias u otros sin categoría. Asígnales una (por ejemplo, arriendo) y la app recordará el destinatario.",
                                    symbol: "tag.fill"))
        }

        // 14. Tarjeta no conectada.
        let hasCardPayments = input.transactions.contains { $0.categoryId == CategoryID.cardPayment && $0.amount < 0 }
        let hasCardAccount = input.accounts.contains { $0.kind == .creditCard }
        if hasCardPayments && !hasCardAccount {
            insights.append(Insight(id: "card-missing", kind: .info, title: "Conecta tu tarjeta de crédito",
                                    message: "Veo pagos de tarjeta, pero no sus compras. Conéctala para saber en qué se usa ese dinero; los pagos no se cuentan como gasto para no duplicarlo.",
                                    symbol: "creditcard"))
        }

        // 15. Consejo según el objetivo.
        if let tip = goalTip(input, income: income) { insights.append(tip) }

        // Ordenar por importancia manteniendo el orden relativo.
        return insights.enumerated()
            .sorted { $0.element.kind != $1.element.kind ? $0.element.kind < $1.element.kind : $0.offset < $1.offset }
            .map(\.element)
    }

    private func goalTip(_ input: AdvisorInput, income: Pesos?) -> Insight? {
        let rule = input.profile.splitRule.isValid ? input.profile.splitRule : .fiftyThirtyTwenty
        switch input.profile.goal {
        case .controlSpending:
            return Insight(id: "goal", kind: .info, title: "Tu objetivo: ordenar tus gastos",
                           message: "Revisa una vez por semana la pestaña Movimientos y corrige categorías. En un mes tendrás un mapa fiel de tus gastos y presupuestos realistas.",
                           symbol: "target")
        case .saveMore:
            guard let income else { return nil }
            return Insight(id: "goal", kind: .info, title: "Tu objetivo: ahorrar más",
                           message: "Automatiza una transferencia de \(MoneyFormat.clp(Int(Double(income) * rule.savings))) el día de pago a una cuenta separada. Lo que no ves, no lo gastas.",
                           symbol: "target")
        case .emergencyFund:
            let needs = averageMonthlyNeeds(input)
            guard needs > 0 else { return nil }
            return Insight(id: "goal", kind: .info, title: "Tu objetivo: fondo de emergencia",
                           message: "Tu meta inicial son \(MoneyFormat.clp(needs * 3)) (3 meses de gastos esenciales). Aportando \(MoneyFormat.clp(needs * 3 / 12)) al mes lo completas en un año.",
                           symbol: "target")
        case .payDebt:
            return Insight(id: "goal", kind: .info, title: "Tu objetivo: salir de deudas",
                           message: "Lista tus deudas por tasa de interés, paga el mínimo en todas y destina todo excedente a la de mayor tasa. Evita pagar solo el mínimo de la tarjeta: los intereses rotativos son de los más caros.",
                           symbol: "target")
        case .invest:
            return Insight(id: "goal", kind: .info, title: "Tu objetivo: invertir",
                           message: "Primero asegura 3 a 6 meses de fondo de emergencia. Luego evalúa APV (beneficio tributario), fondos mutuos o ETF de bajo costo según tu horizonte, y compara comisiones antes de elegir.",
                           symbol: "target")
        }
    }
}
