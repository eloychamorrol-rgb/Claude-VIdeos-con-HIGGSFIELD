import Foundation

/// Montos en pesos chilenos (sin decimales). Negativo = sale dinero, positivo = entra dinero.
public typealias Pesos = Int

// MARK: - Categorías

public enum CategoryGroup: String, Codable, CaseIterable, Sendable {
    case needs, wants, savings, income, transfer

    public var title: String {
        switch self {
        case .needs: return "Necesidades"
        case .wants: return "Deseos"
        case .savings: return "Ahorro e inversión"
        case .income: return "Ingresos"
        case .transfer: return "Movimientos internos"
        }
    }

    /// Grupos que cuentan como consumo (gasto real).
    public var isSpending: Bool { self == .needs || self == .wants }
}

public struct Category: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var symbol: String
    public var colorHex: String
    public var group: CategoryGroup
    public var isCustom: Bool

    public init(id: String, name: String, symbol: String, colorHex: String, group: CategoryGroup, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.group = group
        self.isCustom = isCustom
    }
}

// MARK: - Instituciones y cuentas

public struct Institution: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let colorHex: String

    public init(id: String, name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    /// Instituciones conocidas en Chile. La disponibilidad real depende del agregador.
    public static let catalog: [Institution] = [
        Institution(id: "santander", name: "Santander", colorHex: "#EC0000"),
        Institution(id: "banco_de_chile", name: "Banco de Chile", colorHex: "#002D72"),
        Institution(id: "bancoestado", name: "BancoEstado", colorHex: "#F37021"),
        Institution(id: "bci", name: "Bci", colorHex: "#1D1D1B"),
        Institution(id: "itau", name: "Itaú", colorHex: "#EC7000"),
        Institution(id: "scotiabank", name: "Scotiabank", colorHex: "#EC111A"),
        Institution(id: "security", name: "Banco Security", colorHex: "#5B2C83"),
        Institution(id: "bice", name: "BICE", colorHex: "#00395D"),
        Institution(id: "falabella", name: "Banco Falabella", colorHex: "#4C9C2E"),
        Institution(id: "ripley", name: "Banco Ripley", colorHex: "#5C2D91"),
        Institution(id: "internacional", name: "Banco Internacional", colorHex: "#003B71"),
        Institution(id: "consorcio", name: "Banco Consorcio", colorHex: "#00A3AD"),
        Institution(id: "hsbc", name: "HSBC", colorHex: "#DB0011"),
        Institution(id: "btg", name: "BTG Pactual", colorHex: "#0B2D4F"),
        Institution(id: "mercadopago", name: "Mercado Pago", colorHex: "#00B1EA"),
        Institution(id: "tenpo", name: "Tenpo", colorHex: "#00BAA4"),
        Institution(id: "mach", name: "MACH", colorHex: "#6E2FF4"),
        Institution(id: "cash", name: "Efectivo", colorHex: "#6B7280"),
        Institution(id: "other", name: "Otra institución", colorHex: "#6B7280")
    ]

    /// Resuelve una institución a partir del id o nombre entregado por el agregador.
    public static func resolve(id rawId: String?, name rawName: String?) -> Institution {
        let haystack = TextNormalizer.normalize("\(rawId ?? "") \(rawName ?? "")")
        let aliases: [(String, String)] = [
            ("SANTANDER", "santander"), ("BANCO DE CHILE", "banco_de_chile"), ("BANCO CHILE", "banco_de_chile"),
            ("EDWARDS", "banco_de_chile"), ("ESTADO", "bancoestado"), ("BCI", "bci"), ("ITAU", "itau"),
            ("SCOTIA", "scotiabank"), ("SECURITY", "security"), ("BICE", "bice"), ("FALABELLA", "falabella"),
            ("RIPLEY", "ripley"), ("INTERNACIONAL", "internacional"), ("CONSORCIO", "consorcio"),
            ("HSBC", "hsbc"), ("BTG", "btg"), ("MERCADO PAGO", "mercadopago"), ("MERCADOPAGO", "mercadopago"),
            ("TENPO", "tenpo"), ("MACH", "mach")
        ]
        for (needle, id) in aliases where haystack.contains(needle) {
            if let match = catalog.first(where: { $0.id == id }) { return match }
        }
        let display = (rawName?.isEmpty == false ? rawName : nil) ?? "Otra institución"
        return Institution(id: rawId ?? "other", name: display, colorHex: "#6B7280")
    }

    public static func known(_ id: String) -> Institution {
        catalog.first(where: { $0.id == id }) ?? resolve(id: id, name: nil)
    }
}

public enum AccountKind: String, Codable, CaseIterable, Sendable {
    case checking, sight, savings, creditCard, creditLine, cash, investment, other

    public var title: String {
        switch self {
        case .checking: return "Cuenta corriente"
        case .sight: return "Cuenta vista"
        case .savings: return "Cuenta de ahorro"
        case .creditCard: return "Tarjeta de crédito"
        case .creditLine: return "Línea de crédito"
        case .cash: return "Efectivo"
        case .investment: return "Inversiones"
        case .other: return "Otra"
        }
    }

    /// Cuentas cuyo saldo es dinero disponible (sirve para el fondo de emergencia).
    public var isLiquid: Bool {
        switch self {
        case .checking, .sight, .savings, .cash, .investment: return true
        case .creditCard, .creditLine, .other: return false
        }
    }
}

public enum DataSource: String, Codable, Sendable {
    case bank, csv, manual, demo
}

public struct Account: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var institutionId: String
    public var name: String
    public var numberMasked: String
    public var kind: AccountKind
    public var currency: String
    public var balance: Pesos?
    public var availableBalance: Pesos?
    public var source: DataSource
    public var linkId: String?
    public var externalId: String?
    public var lastSyncedAt: Date?
    public var isHidden: Bool

    public init(id: String, institutionId: String, name: String, numberMasked: String = "", kind: AccountKind,
                currency: String = "CLP", balance: Pesos? = nil, availableBalance: Pesos? = nil,
                source: DataSource, linkId: String? = nil, externalId: String? = nil,
                lastSyncedAt: Date? = nil, isHidden: Bool = false) {
        self.id = id
        self.institutionId = institutionId
        self.name = name
        self.numberMasked = numberMasked
        self.kind = kind
        self.currency = currency
        self.balance = balance
        self.availableBalance = availableBalance
        self.source = source
        self.linkId = linkId
        self.externalId = externalId
        self.lastSyncedAt = lastSyncedAt
        self.isHidden = isHidden
    }
}

/// Conexión con un banco a través del backend (un "link" del agregador).
public struct BankLink: Identifiable, Codable, Hashable, Sendable {
    public enum Status: String, Codable, Sendable { case active, needsReconnect, error }

    public var id: String
    public var institutionId: String
    public var institutionName: String
    public var holderName: String?
    public var createdAt: Date
    public var lastSyncedAt: Date?
    public var status: Status
    public var lastError: String?

    public init(id: String, institutionId: String, institutionName: String, holderName: String? = nil,
                createdAt: Date, lastSyncedAt: Date? = nil, status: Status = .active, lastError: String? = nil) {
        self.id = id
        self.institutionId = institutionId
        self.institutionName = institutionName
        self.holderName = holderName
        self.createdAt = createdAt
        self.lastSyncedAt = lastSyncedAt
        self.status = status
        self.lastError = lastError
    }
}

// MARK: - Movimientos

public enum CategorySource: String, Codable, Sendable {
    /// Asignada por las reglas del sistema.
    case automatic
    /// Asignada por una regla creada por el usuario.
    case userRule
    /// El usuario la cambió a mano en este movimiento.
    case user
}

public struct Transaction: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var accountId: String
    public var amount: Pesos
    public var currency: String
    public var date: Date
    /// `false` cuando el banco solo informa la fecha (sin hora).
    public var hasTime: Bool
    public var rawDescription: String
    public var merchant: String
    public var categoryId: String
    public var categorySource: CategorySource
    public var note: String?
    public var isPending: Bool
    public var source: DataSource

    public init(id: String, accountId: String, amount: Pesos, currency: String = "CLP", date: Date, hasTime: Bool,
                rawDescription: String, merchant: String, categoryId: String,
                categorySource: CategorySource = .automatic, note: String? = nil,
                isPending: Bool = false, source: DataSource) {
        self.id = id
        self.accountId = accountId
        self.amount = amount
        self.currency = currency
        self.date = date
        self.hasTime = hasTime
        self.rawDescription = rawDescription
        self.merchant = merchant
        self.categoryId = categoryId
        self.categorySource = categorySource
        self.note = note
        self.isPending = isPending
        self.source = source
    }

    /// Clave estable para agrupar por comercio.
    public var merchantKey: String { TextNormalizer.normalize(merchant) }
}

// MARK: - Reglas, presupuestos, metas y perfil

public struct UserRule: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    /// Clave normalizada del comercio (ver `Transaction.merchantKey`).
    public var merchantKey: String
    public var categoryId: String
    public var createdAt: Date

    public init(id: String = UUID().uuidString, merchantKey: String, categoryId: String, createdAt: Date = Date()) {
        self.id = id
        self.merchantKey = merchantKey
        self.categoryId = categoryId
        self.createdAt = createdAt
    }
}

public struct Budget: Identifiable, Codable, Hashable, Sendable {
    public var id: String { categoryId }
    public var categoryId: String
    public var monthlyLimit: Pesos

    public init(categoryId: String, monthlyLimit: Pesos) {
        self.categoryId = categoryId
        self.monthlyLimit = monthlyLimit
    }
}

public struct SavingsGoal: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var target: Pesos
    public var saved: Pesos
    public var deadline: Date?

    public init(id: String = UUID().uuidString, name: String, target: Pesos, saved: Pesos = 0, deadline: Date? = nil) {
        self.id = id
        self.name = name
        self.target = target
        self.saved = saved
        self.deadline = deadline
    }

    public var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, Double(saved) / Double(target)))
    }

    /// Aporte mensual necesario para llegar a la meta en la fecha límite.
    public func monthlyContributionNeeded(now: Date, calendar: Calendar) -> Pesos? {
        guard let deadline, saved < target else { return nil }
        let months = max(1, (calendar.dateComponents([.month], from: now, to: deadline).month ?? 0) + 1)
        return Int((Double(target - saved) / Double(months)).rounded(.up))
    }
}

public struct SplitRule: Codable, Hashable, Sendable {
    public var name: String
    public var needs: Double
    public var wants: Double
    public var savings: Double

    public init(name: String, needs: Double, wants: Double, savings: Double) {
        self.name = name
        self.needs = needs
        self.wants = wants
        self.savings = savings
    }

    public static let fiftyThirtyTwenty = SplitRule(name: "50/30/20", needs: 0.5, wants: 0.3, savings: 0.2)
    public static let sixtyThirtyTen = SplitRule(name: "60/30/10", needs: 0.6, wants: 0.3, savings: 0.1)
    public static let seventyTwentyTen = SplitRule(name: "70/20/10", needs: 0.7, wants: 0.2, savings: 0.1)
    public static let presets: [SplitRule] = [.fiftyThirtyTwenty, .sixtyThirtyTen, .seventyTwentyTen]

    public var isValid: Bool {
        needs >= 0 && wants >= 0 && savings >= 0 && abs(needs + wants + savings - 1) < 0.001
    }
}

public enum FinancialGoal: String, Codable, CaseIterable, Sendable {
    case controlSpending, saveMore, emergencyFund, payDebt, invest

    public var title: String {
        switch self {
        case .controlSpending: return "Ordenar mis gastos"
        case .saveMore: return "Ahorrar más"
        case .emergencyFund: return "Armar un fondo de emergencia"
        case .payDebt: return "Salir de deudas"
        case .invest: return "Empezar a invertir"
        }
    }
}

public enum HousingSituation: String, Codable, CaseIterable, Sendable {
    case rent, mortgage, owned, family

    public var title: String {
        switch self {
        case .rent: return "Arriendo"
        case .mortgage: return "Pago dividendo"
        case .owned: return "Vivienda propia pagada"
        case .family: return "Vivo con familia"
        }
    }
}

public struct UserProfile: Codable, Hashable, Sendable {
    public var name: String
    /// Ingreso mensual declarado. `nil` = se estima a partir de los movimientos.
    public var declaredMonthlyIncome: Pesos?
    public var goal: FinancialGoal
    public var housing: HousingSituation
    public var dependents: Int
    public var splitRule: SplitRule
    /// Compras bajo este monto se consideran "gastos hormiga".
    public var smallExpenseThreshold: Pesos

    public init(name: String = "", declaredMonthlyIncome: Pesos? = nil, goal: FinancialGoal = .controlSpending,
                housing: HousingSituation = .rent, dependents: Int = 0,
                splitRule: SplitRule = .fiftyThirtyTwenty, smallExpenseThreshold: Pesos = 5_000) {
        self.name = name
        self.declaredMonthlyIncome = declaredMonthlyIncome
        self.goal = goal
        self.housing = housing
        self.dependents = dependents
        self.splitRule = splitRule
        self.smallExpenseThreshold = smallExpenseThreshold
    }
}

// MARK: - Estado persistido

public struct FinanceSnapshot: Codable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var profile: UserProfile?
    public var accounts: [Account]
    public var links: [BankLink]
    public var transactions: [Transaction]
    public var categories: [Category]
    public var rules: [UserRule]
    public var budgets: [Budget]
    public var goals: [SavingsGoal]

    public init(version: Int = FinanceSnapshot.currentVersion, profile: UserProfile? = nil, accounts: [Account] = [],
                links: [BankLink] = [], transactions: [Transaction] = [], categories: [Category] = CategoryCatalog.defaults,
                rules: [UserRule] = [], budgets: [Budget] = [], goals: [SavingsGoal] = []) {
        self.version = version
        self.profile = profile
        self.accounts = accounts
        self.links = links
        self.transactions = transactions
        self.categories = categories
        self.rules = rules
        self.budgets = budgets
        self.goals = goals
    }

    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Agrega categorías por defecto que falten (p. ej. tras una actualización de la app).
    public mutating func ensureDefaultCategories() {
        let existing = Set(categories.map(\.id))
        categories.append(contentsOf: CategoryCatalog.defaults.filter { !existing.contains($0.id) })
    }
}
