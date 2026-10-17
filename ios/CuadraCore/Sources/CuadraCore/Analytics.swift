import Foundation

public struct CategoryTotal: Identifiable, Hashable, Sendable {
    public var id: String { categoryId }
    public let categoryId: String
    /// Gasto positivo (las devoluciones lo reducen).
    public let amount: Pesos
    public let count: Int
    /// Proporción sobre el gasto total del período.
    public let share: Double
}

public struct WeekdayTotal: Identifiable, Hashable, Sendable {
    public var id: Int { weekday }
    /// 0 = lunes … 6 = domingo.
    public let weekday: Int
    public let amount: Pesos
    public let count: Int
    /// Gasto promedio por cada día de ese tipo dentro del período.
    public let averagePerDay: Pesos
}

public struct HourTotal: Identifiable, Hashable, Sendable {
    public var id: Int { hour }
    public let hour: Int
    public let amount: Pesos
    public let count: Int
}

public struct DailyPoint: Identifiable, Hashable, Sendable {
    public var id: Date { date }
    public let date: Date
    public let spending: Pesos
    public let income: Pesos
}

public struct MerchantTotal: Identifiable, Hashable, Sendable {
    public var id: String { key }
    public let key: String
    public let name: String
    public let categoryId: String
    public let amount: Pesos
    public let count: Int
}

public struct MonthPoint: Identifiable, Hashable, Sendable {
    public var id: Date { month.start }
    public let month: Period
    public let income: Pesos
    public let spending: Pesos
    public let savings: Pesos
    public var net: Pesos { income - spending - savings }
}

public struct CategoryDelta: Identifiable, Hashable, Sendable {
    public var id: String { categoryId }
    public let categoryId: String
    public let current: Pesos
    public let previous: Pesos
    public var difference: Pesos { current - previous }
    /// `nil` si el período anterior no tuvo gasto en la categoría.
    public var change: Double? { previous > 0 ? Double(current - previous) / Double(previous) : nil }
}

public struct SmallExpensesSummary: Hashable, Sendable {
    public let threshold: Pesos
    public let count: Int
    public let total: Pesos
}

public struct PeriodSummary: Sendable {
    public let period: Period
    public let income: Pesos
    /// Gasto en necesidades + deseos.
    public let spending: Pesos
    public let needs: Pesos
    public let wants: Pesos
    /// Dinero enviado a ahorro o inversión.
    public let savingsTransfers: Pesos
    public let transactionCount: Int
    public let byCategory: [CategoryTotal]
    public let byWeekday: [WeekdayTotal]
    public let byHour: [HourTotal]
    /// Proporción de gastos que traen hora (los bancos a veces informan solo la fecha).
    public let hourCoverage: Double
    public let daily: [DailyPoint]
    public let topMerchants: [MerchantTotal]
    public let largestExpenses: [Transaction]
    public let elapsedDays: Int
    public let totalDays: Int
    public let smallExpenses: SmallExpensesSummary
    public let incomeByCategory: [CategoryTotal]
    /// Gasto estimado al cierre por categoría. Los gastos fijos y las compras puntuales grandes no se
    /// extrapolan; el resto se proyecta según el ritmo diario. Igual al gasto real si el período terminó.
    public let projectedByCategory: [String: Pesos]

    /// Flujo neto: lo que entró menos todo lo que salió (incluido lo enviado a ahorro).
    public var net: Pesos { income - spending - savingsTransfers }

    /// (ingresos - gastos) / ingresos.
    public var savingsRate: Double? {
        guard income > 0 else { return nil }
        return Double(income - spending) / Double(income)
    }

    public var averageDailySpending: Pesos {
        guard elapsedDays > 0 else { return 0 }
        return spending / elapsedDays
    }

    public var isInProgress: Bool { elapsedDays < totalDays }

    /// Gasto estimado al cierre del período según el ritmo actual (solo si el período está en curso).
    public var projectedSpending: Pesos? {
        guard isInProgress, elapsedDays > 0 else { return nil }
        return projectedByCategory.values.reduce(0, +)
    }
}

/// Cálculo de estadísticas a partir de los movimientos.
public struct AnalyticsEngine: Sendable {
    public let categories: [String: Category]
    public let calendar: FinanceCalendar
    public let currency: String

    public init(categories: [Category], calendar: FinanceCalendar = .chile, currency: String = "CLP") {
        var map: [String: Category] = [:]
        for category in categories { map[category.id] = category }
        self.categories = map
        self.calendar = calendar
        self.currency = currency
    }

    public func group(of transaction: Transaction) -> CategoryGroup {
        if let category = categories[transaction.categoryId] { return category.group }
        return transaction.amount > 0 ? .income : .wants
    }

    public func category(_ id: String) -> Category {
        categories[id] ?? CategoryCatalog.fallbackCategory
    }

    /// Movimientos relevantes para el análisis (moneda principal, dentro del período).
    public func transactions(_ transactions: [Transaction], in period: Period) -> [Transaction] {
        transactions.filter { $0.currency == currency && period.contains($0.date) }
    }

    public func summary(of allTransactions: [Transaction], in period: Period, now: Date = Date(),
                        smallExpenseThreshold: Pesos = 5_000) -> PeriodSummary {
        let items = transactions(allTransactions, in: period)
        var income = 0, needs = 0, wants = 0, savings = 0
        var categoryAmounts: [String: (Pesos, Int)] = [:]
        var incomeAmounts: [String: (Pesos, Int)] = [:]
        var weekdayAmounts = Array(repeating: (0, 0), count: 7)
        var hourAmounts = Array(repeating: (0, 0), count: 24)
        var dailySpending: [Date: Pesos] = [:]
        var dailyIncome: [Date: Pesos] = [:]
        var merchants: [String: (name: String, categoryId: String, amount: Pesos, count: Int)] = [:]
        var expenseCount = 0, timedExpenseCount = 0
        var smallCount = 0, smallTotal = 0
        var expenses: [Transaction] = []

        for transaction in items {
            let day = calendar.startOfDay(transaction.date)
            switch group(of: transaction) {
            case .transfer:
                continue
            case .income:
                income += transaction.amount
                dailyIncome[day, default: 0] += transaction.amount
                let current = incomeAmounts[transaction.categoryId] ?? (0, 0)
                incomeAmounts[transaction.categoryId] = (current.0 + transaction.amount, current.1 + 1)
            case .savings:
                savings -= transaction.amount
            case .needs, .wants:
                let spent = -transaction.amount
                if group(of: transaction) == .needs { needs += spent } else { wants += spent }
                let current = categoryAmounts[transaction.categoryId] ?? (0, 0)
                categoryAmounts[transaction.categoryId] = (current.0 + spent, current.1 + 1)
                dailySpending[day, default: 0] += spent
                let weekday = calendar.weekdayIndex(transaction.date)
                weekdayAmounts[weekday].0 += spent
                weekdayAmounts[weekday].1 += 1
                if transaction.amount < 0 {
                    expenseCount += 1
                    expenses.append(transaction)
                    if transaction.hasTime {
                        timedExpenseCount += 1
                        let hour = calendar.hour(transaction.date)
                        hourAmounts[hour].0 += spent
                        hourAmounts[hour].1 += 1
                    }
                    if spent < smallExpenseThreshold && group(of: transaction) == .wants {
                        smallCount += 1
                        smallTotal += spent
                    }
                }
                let key = transaction.merchantKey
                var merchant = merchants[key] ?? (transaction.merchant, transaction.categoryId, 0, 0)
                merchant.amount += spent
                merchant.count += 1
                merchants[key] = merchant
            }
        }

        let spending = needs + wants
        let byCategory = categoryAmounts
            .map { CategoryTotal(categoryId: $0.key, amount: $0.value.0, count: $0.value.1,
                                 share: spending > 0 ? Double($0.value.0) / Double(spending) : 0) }
            .filter { $0.amount != 0 }
            .sorted { $0.amount != $1.amount ? $0.amount > $1.amount : $0.categoryId < $1.categoryId }
        let incomeByCategory = incomeAmounts
            .map { CategoryTotal(categoryId: $0.key, amount: $0.value.0, count: $0.value.1,
                                 share: income > 0 ? Double($0.value.0) / Double(income) : 0) }
            .sorted { $0.amount != $1.amount ? $0.amount > $1.amount : $0.categoryId < $1.categoryId }

        let elapsed = calendar.elapsedDays(in: period, now: now)
        let total = calendar.numberOfDays(in: period)
        let countedDays = calendar.days(in: period).prefix(max(elapsed, 0))
        var weekdayOccurrences = Array(repeating: 0, count: 7)
        for day in countedDays { weekdayOccurrences[calendar.weekdayIndex(day)] += 1 }

        let byWeekday = (0..<7).map { index in
            WeekdayTotal(weekday: index, amount: weekdayAmounts[index].0, count: weekdayAmounts[index].1,
                         averagePerDay: weekdayOccurrences[index] > 0 ? weekdayAmounts[index].0 / weekdayOccurrences[index] : 0)
        }
        let byHour = (0..<24).map { HourTotal(hour: $0, amount: hourAmounts[$0].0, count: hourAmounts[$0].1) }
        let daily = calendar.days(in: period).map { day in
            let key = calendar.startOfDay(day)
            return DailyPoint(date: key, spending: dailySpending[key] ?? 0, income: dailyIncome[key] ?? 0)
        }
        let topMerchants = merchants
            .map { MerchantTotal(key: $0.key, name: $0.value.name, categoryId: $0.value.categoryId,
                                 amount: $0.value.amount, count: $0.value.count) }
            .filter { $0.amount > 0 }
            .sorted { $0.amount != $1.amount ? $0.amount > $1.amount : $0.key < $1.key }
        // Proyección: gastos fijos y compras puntuales grandes no se multiplican por el ritmo diario.
        var projectedByCategory: [String: Pesos] = [:]
        let factor = elapsed > 0 && elapsed < total ? Double(total) / Double(elapsed) : 1
        let variableAmounts = expenses
            .filter { !CategoryCatalog.fixedNeeds.contains($0.categoryId) }
            .map { Double(-$0.amount) }
        // Con pocos datos la mediana no es representativa: se usa solo el mínimo fijo.
        let oneOffThreshold = variableAmounts.count >= 5 ? max(100_000, median(variableAmounts) * 4) : 100_000
        var oneOffByCategory: [String: Pesos] = [:]
        for expense in expenses where Double(-expense.amount) > oneOffThreshold {
            oneOffByCategory[expense.categoryId, default: 0] += -expense.amount
        }
        for total in byCategory {
            if factor == 1 || CategoryCatalog.fixedNeeds.contains(total.categoryId) {
                projectedByCategory[total.categoryId] = total.amount
            } else {
                let oneOff = min(oneOffByCategory[total.categoryId] ?? 0, max(total.amount, 0))
                projectedByCategory[total.categoryId] = oneOff + Int((Double(total.amount - oneOff) * factor).rounded())
            }
        }

        let largest = expenses.sorted { $0.amount != $1.amount ? $0.amount < $1.amount : $0.date > $1.date }

        return PeriodSummary(
            period: period, income: income, spending: spending, needs: needs, wants: wants,
            savingsTransfers: savings, transactionCount: items.count, byCategory: byCategory,
            byWeekday: byWeekday, byHour: byHour,
            hourCoverage: expenseCount > 0 ? Double(timedExpenseCount) / Double(expenseCount) : 0,
            daily: daily, topMerchants: Array(topMerchants.prefix(10)), largestExpenses: Array(largest.prefix(5)),
            elapsedDays: elapsed, totalDays: total,
            smallExpenses: SmallExpensesSummary(threshold: smallExpenseThreshold, count: smallCount, total: smallTotal),
            incomeByCategory: incomeByCategory, projectedByCategory: projectedByCategory
        )
    }

    public func compare(_ current: PeriodSummary, with previous: PeriodSummary) -> [CategoryDelta] {
        let currentMap = Dictionary(uniqueKeysWithValues: current.byCategory.map { ($0.categoryId, $0.amount) })
        let previousMap = Dictionary(uniqueKeysWithValues: previous.byCategory.map { ($0.categoryId, $0.amount) })
        return Set(currentMap.keys).union(previousMap.keys)
            .map { CategoryDelta(categoryId: $0, current: currentMap[$0] ?? 0, previous: previousMap[$0] ?? 0) }
            .sorted { abs($0.difference) != abs($1.difference) ? abs($0.difference) > abs($1.difference) : $0.categoryId < $1.categoryId }
    }

    /// Ingresos, gastos y ahorro de los últimos `months` meses (incluido el mes de `date`).
    public func monthlyTrend(_ transactions: [Transaction], months: Int, endingAt date: Date) -> [MonthPoint] {
        let current = calendar.period(.month, containing: date)
        return (0..<max(1, months)).reversed().map { offset in
            let month = calendar.shifted(current, by: -offset)
            var income = 0, spending = 0, savings = 0
            for transaction in self.transactions(transactions, in: month) {
                switch group(of: transaction) {
                case .income: income += transaction.amount
                case .needs, .wants: spending -= transaction.amount
                case .savings: savings -= transaction.amount
                case .transfer: break
                }
            }
            return MonthPoint(month: month, income: income, spending: spending, savings: savings)
        }
    }

    /// Gasto en una categoría agrupado por día, semana o mes dentro del período.
    public func categorySeries(_ transactions: [Transaction], categoryId: String, in period: Period,
                               bucket: PeriodKind) -> [(Period, Pesos)] {
        var buckets: [Period] = []
        var cursor = calendar.period(bucket == .custom ? .day : bucket, containing: period.start)
        while cursor.start < period.end {
            buckets.append(cursor)
            cursor = calendar.next(cursor)
        }
        let relevant = self.transactions(transactions, in: period).filter { $0.categoryId == categoryId }
        return buckets.map { bucketPeriod in
            (bucketPeriod, relevant.filter { bucketPeriod.contains($0.date) }.reduce(0) { $0 - $1.amount })
        }
    }

    /// Promedio mensual de gasto por categoría en los meses completos indicados.
    public func averageMonthlySpending(_ transactions: [Transaction], months: [Period]) -> [String: Pesos] {
        guard !months.isEmpty else { return [:] }
        var totals: [String: Pesos] = [:]
        for month in months {
            for transaction in self.transactions(transactions, in: month) where group(of: transaction).isSpending {
                totals[transaction.categoryId, default: 0] -= transaction.amount
            }
        }
        return totals.mapValues { $0 / months.count }
    }
}
