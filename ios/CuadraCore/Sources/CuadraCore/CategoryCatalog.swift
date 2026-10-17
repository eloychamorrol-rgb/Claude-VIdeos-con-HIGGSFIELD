import Foundation

public enum CategoryID {
    // Necesidades
    public static let housing = "vivienda"
    public static let utilities = "cuentas"
    public static let groceries = "supermercado"
    public static let transport = "transporte"
    public static let car = "auto"
    public static let health = "salud"
    public static let education = "educacion"
    public static let insurance = "seguros"
    public static let debt = "creditos"
    public static let bankFees = "comisiones"
    public static let taxes = "impuestos"
    // Deseos
    public static let restaurants = "restaurantes"
    public static let delivery = "delivery"
    public static let subscriptions = "suscripciones"
    public static let shopping = "compras"
    public static let home = "hogar"
    public static let entertainment = "entretencion"
    public static let travel = "viajes"
    public static let personalCare = "cuidado-personal"
    public static let sports = "deporte"
    public static let pets = "mascotas"
    public static let gifts = "donaciones"
    public static let cash = "efectivo"
    public static let transfersOut = "transferencias-enviadas"
    public static let otherExpense = "otros"
    // Ahorro
    public static let savings = "ahorro"
    // Ingresos
    public static let salary = "sueldo"
    public static let transfersIn = "transferencias-recibidas"
    public static let refunds = "reembolsos"
    public static let investmentIncome = "inversiones"
    public static let otherIncome = "otros-ingresos"
    // Internos
    public static let ownTransfer = "transferencias-propias"
    public static let cardPayment = "pago-tarjeta"
}

public enum CategoryCatalog {
    public static let defaults: [Category] = [
        Category(id: CategoryID.housing, name: "Vivienda", symbol: "house.fill", colorHex: "#5E7CE2", group: .needs),
        Category(id: CategoryID.utilities, name: "Cuentas básicas", symbol: "bolt.fill", colorHex: "#E2A93B", group: .needs),
        Category(id: CategoryID.groceries, name: "Supermercado", symbol: "cart.fill", colorHex: "#3FA66B", group: .needs),
        Category(id: CategoryID.transport, name: "Transporte", symbol: "tram.fill", colorHex: "#3B8FD9", group: .needs),
        Category(id: CategoryID.car, name: "Auto", symbol: "car.fill", colorHex: "#4C6A88", group: .needs),
        Category(id: CategoryID.health, name: "Salud", symbol: "cross.case.fill", colorHex: "#E05A6B", group: .needs),
        Category(id: CategoryID.education, name: "Educación", symbol: "book.fill", colorHex: "#7A63D6", group: .needs),
        Category(id: CategoryID.insurance, name: "Seguros", symbol: "shield.fill", colorHex: "#5B8C85", group: .needs),
        Category(id: CategoryID.debt, name: "Créditos e intereses", symbol: "creditcard.fill", colorHex: "#C2553F", group: .needs),
        Category(id: CategoryID.bankFees, name: "Comisiones bancarias", symbol: "building.columns.fill", colorHex: "#9C6B4E", group: .needs),
        Category(id: CategoryID.taxes, name: "Impuestos y trámites", symbol: "doc.text.fill", colorHex: "#7D8590", group: .needs),

        Category(id: CategoryID.restaurants, name: "Restaurantes y café", symbol: "fork.knife", colorHex: "#E07A3F", group: .wants),
        Category(id: CategoryID.delivery, name: "Delivery", symbol: "bag.fill", colorHex: "#D9534F", group: .wants),
        Category(id: CategoryID.subscriptions, name: "Suscripciones", symbol: "play.rectangle.fill", colorHex: "#8E5BD9", group: .wants),
        Category(id: CategoryID.shopping, name: "Compras", symbol: "handbag.fill", colorHex: "#D46BA3", group: .wants),
        Category(id: CategoryID.home, name: "Hogar", symbol: "sofa.fill", colorHex: "#A7845A", group: .wants),
        Category(id: CategoryID.entertainment, name: "Entretención", symbol: "ticket.fill", colorHex: "#C9A227", group: .wants),
        Category(id: CategoryID.travel, name: "Viajes", symbol: "airplane", colorHex: "#2BA6B5", group: .wants),
        Category(id: CategoryID.personalCare, name: "Cuidado personal", symbol: "sparkles", colorHex: "#C774C9", group: .wants),
        Category(id: CategoryID.sports, name: "Deporte", symbol: "figure.run", colorHex: "#4CAF91", group: .wants),
        Category(id: CategoryID.pets, name: "Mascotas", symbol: "pawprint.fill", colorHex: "#B0855B", group: .wants),
        Category(id: CategoryID.gifts, name: "Regalos y donaciones", symbol: "gift.fill", colorHex: "#E06F8B", group: .wants),
        Category(id: CategoryID.cash, name: "Efectivo", symbol: "banknote.fill", colorHex: "#6E9E5B", group: .wants),
        Category(id: CategoryID.transfersOut, name: "Transferencias a terceros", symbol: "arrow.up.right", colorHex: "#8A94A6", group: .wants),
        Category(id: CategoryID.otherExpense, name: "Otros gastos", symbol: "ellipsis.circle.fill", colorHex: "#9AA0A6", group: .wants),

        Category(id: CategoryID.savings, name: "Ahorro e inversión", symbol: "chart.line.uptrend.xyaxis", colorHex: "#2E9E6A", group: .savings),

        Category(id: CategoryID.salary, name: "Sueldo", symbol: "briefcase.fill", colorHex: "#2E9E6A", group: .income),
        Category(id: CategoryID.transfersIn, name: "Transferencias recibidas", symbol: "arrow.down.left", colorHex: "#3FA66B", group: .income),
        Category(id: CategoryID.refunds, name: "Reembolsos", symbol: "arrow.uturn.backward", colorHex: "#5BB98C", group: .income),
        Category(id: CategoryID.investmentIncome, name: "Intereses e inversiones", symbol: "percent", colorHex: "#2F8F83", group: .income),
        Category(id: CategoryID.otherIncome, name: "Otros ingresos", symbol: "plus.circle.fill", colorHex: "#6DBF8F", group: .income),

        Category(id: CategoryID.ownTransfer, name: "Entre mis cuentas", symbol: "arrow.left.arrow.right", colorHex: "#9AA0A6", group: .transfer),
        Category(id: CategoryID.cardPayment, name: "Pago de tarjeta", symbol: "creditcard.and.123", colorHex: "#9AA0A6", group: .transfer)
    ]

    /// Necesidades que son compromisos fijos: el plan de presupuesto no las recorta.
    public static let fixedNeeds: Set<String> = [
        CategoryID.housing, CategoryID.utilities, CategoryID.insurance, CategoryID.debt, CategoryID.education, CategoryID.taxes
    ]

    public static let fallbackCategory = Category(id: CategoryID.otherExpense, name: "Otros gastos",
                                                  symbol: "ellipsis.circle.fill", colorHex: "#9AA0A6", group: .wants)
}
