import Foundation

/// Regla de categorización por palabras clave sobre la glosa normalizada.
public struct MerchantRule: Sendable {
    public enum Direction: Sendable { case outflow, inflow, any }

    public let keywords: [String]
    public let categoryId: String
    /// Nombre canónico del comercio (si se conoce).
    public let merchant: String?
    public let direction: Direction

    public init(_ keywords: [String], _ categoryId: String, merchant: String? = nil, direction: Direction = .outflow) {
        self.keywords = keywords
        self.categoryId = categoryId
        self.merchant = merchant
        self.direction = direction
    }

    /// Las palabras de hasta 4 letras, las frases y las que empiezan con "=" deben coincidir como palabras
    /// completas para evitar falsos positivos ("GAS" no calza con "GASTOS"); las demás pueden estar dentro
    /// de otra palabra ("SEGURO" calza con "SEGUROS").
    func matches(paddedText: String) -> Bool {
        for keyword in keywords {
            if keyword.hasPrefix("=") {
                if paddedText.contains(" \(keyword.dropFirst()) ") { return true }
            } else if keyword.count <= 4 || keyword.contains(" ") {
                if paddedText.contains(" \(keyword) ") { return true }
            } else if paddedText.contains(keyword) {
                return true
            }
        }
        return false
    }
}

/// Reglas para comercios y glosas habituales en Chile. El orden importa: gana la primera que calza.
public enum MerchantRules {
    public static let all: [MerchantRule] = movementsBetweenAccounts + incomeRules + expenseRules

    static let movementsBetweenAccounts: [MerchantRule] = [
        MerchantRule(["PAGO TARJETA", "PAGO TC", "PAGO DE TARJETA", "PAGO TARJ", "PAGO TAR CRED", "PAGO CMR", "PAGO TARJETA CREDITO",
                      "PAGO LINEA DE CREDITO", "PAGO LINEA CREDITO", "ABONO LINEA DE CREDITO", "TRASPASO LINEA"],
                     CategoryID.cardPayment, merchant: "Pago de tarjeta", direction: .any),
        MerchantRule(["TRASPASO DE FONDOS", "TRASPASO ENTRE CUENTAS", "TRASPASO A CUENTA PROPIA", "CUENTAS PROPIAS"],
                     CategoryID.ownTransfer, merchant: "Entre mis cuentas", direction: .any),
        // Rescates desde plataformas de inversión: vuelven fondos propios, no son ingreso.
        MerchantRule(["FINTUAL", "RACIONAL", "RESCATE FONDO", "RESCATE FFMM", "RESCATE DAP"],
                     CategoryID.ownTransfer, merchant: nil, direction: .inflow)
    ]

    static let incomeRules: [MerchantRule] = [
        MerchantRule(["REMUNERACION", "REMUNERACIONES", "SUELDO", "NOMINA", "PAGO DE REMUN", "LIQUIDACION SUELDO",
                      "HONORARIOS", "PENSION", "AGUINALDO", "BONO"], CategoryID.salary, merchant: "Sueldo", direction: .inflow),
        MerchantRule(["DEVOLUCION", "REVERSO", "REVERSA", "ANULACION", "REEMBOLSO", "NOTA DE CREDITO", "CASHBACK", "CONTRACARGO"],
                     CategoryID.refunds, merchant: nil, direction: .inflow),
        MerchantRule(["INTERES", "INTERESES", "DIVIDENDO", "DIVIDENDOS", "UTILIDAD", "UTILIDADES", "CUPON"],
                     CategoryID.investmentIncome, merchant: nil, direction: .inflow),
        MerchantRule(["TRANSFERENCIA", "TRANSF", "TEF", "DEPOSITO", "DEP", "ABONO"],
                     CategoryID.transfersIn, merchant: nil, direction: .inflow)
    ]

    static let expenseRules: [MerchantRule] = [
        // Delivery antes que transporte (UBER EATS vs UBER).
        MerchantRule(["UBER EATS", "UBEREATS"], CategoryID.delivery, merchant: "Uber Eats"),
        MerchantRule(["RAPPI"], CategoryID.delivery, merchant: "Rappi"),
        MerchantRule(["PEDIDOSYA", "PEDIDOS YA"], CategoryID.delivery, merchant: "PedidosYa"),
        MerchantRule(["DIDI FOOD", "DIDIFOOD"], CategoryID.delivery, merchant: "DiDi Food"),
        MerchantRule(["=JUSTO", "JOKR"], CategoryID.delivery),

        // Cuentas básicas antes que transporte (METROGAS vs METRO).
        MerchantRule(["ENEL"], CategoryID.utilities, merchant: "Enel"),
        MerchantRule(["CGE", "CHILQUINTA", "SAESA", "FRONTEL", "CODINER"], CategoryID.utilities),
        MerchantRule(["AGUAS ANDINAS"], CategoryID.utilities, merchant: "Aguas Andinas"),
        MerchantRule(["ESVAL", "ESSBIO", "NUEVOSUR", "AGUAS DEL VALLE", "AGUAS ARAUCANIA", "SMAPA", "AGUAS"], CategoryID.utilities),
        MerchantRule(["METROGAS"], CategoryID.utilities, merchant: "Metrogas"),
        MerchantRule(["LIPIGAS"], CategoryID.utilities, merchant: "Lipigas"),
        MerchantRule(["ABASTIBLE"], CategoryID.utilities, merchant: "Abastible"),
        MerchantRule(["GASCO", "GAS"], CategoryID.utilities),
        MerchantRule(["ENTEL"], CategoryID.utilities, merchant: "Entel"),
        MerchantRule(["MOVISTAR"], CategoryID.utilities, merchant: "Movistar"),
        MerchantRule(["WOM"], CategoryID.utilities, merchant: "WOM"),
        MerchantRule(["=CLARO"], CategoryID.utilities, merchant: "Claro"),
        MerchantRule(["VTR"], CategoryID.utilities, merchant: "VTR"),
        MerchantRule(["MUNDO PACIFICO", "MUNDO TELECOM", "GTD", "TELSUR"], CategoryID.utilities),
        MerchantRule(["SERVIPAG", "SENCILLITO", "UNIRED"], CategoryID.utilities),

        // Vivienda
        MerchantRule(["ARRIENDO", "ARRIENDOS"], CategoryID.housing, merchant: "Arriendo"),
        MerchantRule(["GASTOS COMUNES", "GASTO COMUN", "GGCC", "COMUNIDAD FELIZ", "EDIFITO", "KASTOR"], CategoryID.housing, merchant: "Gastos comunes"),
        MerchantRule(["DIVIDENDO", "HIPOTECARIO", "MUTUO HIPOTECARIO"], CategoryID.housing, merchant: "Dividendo"),
        MerchantRule(["CONTRIBUCIONES"], CategoryID.housing, merchant: "Contribuciones"),

        // Auto (antes que impuestos, por el permiso de circulación)
        MerchantRule(["COPEC"], CategoryID.car, merchant: "Copec"),
        MerchantRule(["SHELL"], CategoryID.car, merchant: "Shell"),
        MerchantRule(["PETROBRAS", "ARAMCO", "ENEX", "TERPEL", "ESMAX", "BENCINA", "COMBUSTIBLE"], CategoryID.car),
        MerchantRule(["COSTANERA NORTE", "VESPUCIO", "AUTOPISTA", "AUTOPASE", "TAG", "RUTA DEL", "NORORIENTE"], CategoryID.car, merchant: "Autopistas (TAG)"),
        MerchantRule(["ESTACIONAMIENTO", "PARKING", "SABA", "PARQUIMETRO"], CategoryID.car, merchant: "Estacionamiento"),
        MerchantRule(["PERMISO DE CIRCULACION", "PERMISO CIRCULACION", "REVISION TECNICA", "SOAP", "LAVADO AUTO", "AUTOMOTRIZ", "NEUMATICOS"], CategoryID.car),

        // Transporte
        MerchantRule(["UBER"], CategoryID.transport, merchant: "Uber"),
        MerchantRule(["DIDI"], CategoryID.transport, merchant: "DiDi"),
        MerchantRule(["CABIFY"], CategoryID.transport, merchant: "Cabify"),
        MerchantRule(["INDRIVE", "BEAT", "TAXI"], CategoryID.transport),
        MerchantRule(["METRO DE SANTIAGO", "=METRO"], CategoryID.transport, merchant: "Metro"),
        MerchantRule(["BIP", "CARGA BIP", "RED MOVILIDAD", "TRANSANTIAGO", "MERVAL", "BIOTREN", "EFE"], CategoryID.transport, merchant: "Transporte público"),
        MerchantRule(["TURBUS", "TUR BUS", "PULLMAN", "BUSES"], CategoryID.transport),
        MerchantRule(["SCOOTER", "LIME", "BIRD"], CategoryID.transport),

        // Supermercado
        MerchantRule(["LIDER", "WALMART"], CategoryID.groceries, merchant: "Líder"),
        MerchantRule(["JUMBO"], CategoryID.groceries, merchant: "Jumbo"),
        MerchantRule(["UNIMARC"], CategoryID.groceries, merchant: "Unimarc"),
        MerchantRule(["SANTA ISABEL"], CategoryID.groceries, merchant: "Santa Isabel"),
        MerchantRule(["TOTTUS"], CategoryID.groceries, merchant: "Tottus"),
        MerchantRule(["ACUENTA", "ALVI", "MAYORISTA", "OK MARKET", "OXXO", "PRONTO", "SPID", "CORNERSHOP", "SUPERMERCADO",
                      "MINIMARKET", "ALMACEN", "VERDULERIA", "CARNICERIA", "PANADERIA", "LA VEGA", "FRUTERIA"], CategoryID.groceries),

        // Mascotas antes que salud (clínica veterinaria)
        MerchantRule(["VETERINARI", "SUPERZOO", "PET HAPPY", "PETLAND", "MASCOTA", "PETCO"], CategoryID.pets),

        // Salud
        MerchantRule(["CRUZ VERDE"], CategoryID.health, merchant: "Cruz Verde"),
        MerchantRule(["SALCOBRAND"], CategoryID.health, merchant: "Salcobrand"),
        MerchantRule(["AHUMADA"], CategoryID.health, merchant: "Farmacias Ahumada"),
        MerchantRule(["FARMACIA", "DR SIMI", "KNOP", "ISAPRE", "COLMENA", "CRUZ BLANCA", "BANMEDICA", "CONSALUD", "VIDA TRES",
                      "MASVIDA", "FONASA", "CLINICA", "INTEGRAMEDICA", "REDSALUD", "LABORATORIO", "DENTAL", "OPTICA",
                      "MEDICO", "HOSPITAL", "MEGASALUD", "CENTRO MEDICO", "PSICOLOG", "KINESIOLOG"], CategoryID.health),

        // Educación
        MerchantRule(["UNIVERSIDAD", "COLEGIO", "INSTITUTO", "DUOC", "INACAP", "JARDIN INFANTIL", "MATRICULA",
                      "ARANCEL", "UDEMY", "COURSERA", "PLATZI", "DOMESTIKA", "BUSCALIBRE", "LIBRERIA", "CREDITO CAE"], CategoryID.education),

        // Seguros
        MerchantRule(["SEGURO", "METLIFE", "MAPFRE", "HDI", "SURA", "CONSOLIDADA", "ZURICH", "LIBERTY", "BICE VIDA", "CONFUTURO"], CategoryID.insurance),

        // Ahorro e inversión (salidas hacia instrumentos de ahorro)
        MerchantRule(["FINTUAL"], CategoryID.savings, merchant: "Fintual"),
        MerchantRule(["RACIONAL"], CategoryID.savings, merchant: "Racional"),
        MerchantRule(["DEPOSITO A PLAZO", "DAP", "FONDOS MUTUOS", "FONDO MUTUO", "FFMM", "APV", "AHORRO", "INVERSION", "BTG PACTUAL",
                      "LARRAIN VIAL", "BUDA", "ORIONX"], CategoryID.savings),

        // Créditos y comisiones
        MerchantRule(["COMISION", "COMISIONES", "MANTENCION", "CARGO MENSUAL", "COSTO ADMINISTRACION", "ADMINISTRACION CUENTA",
                      "COBRO MANTENCION"], CategoryID.bankFees, merchant: "Comisión bancaria"),
        MerchantRule(["CREDITO CONSUMO", "CUOTA CREDITO", "PAGO CREDITO", "PAGO PRESTAMO", "AVANCE EN EFECTIVO", "INTERESES",
                      "INTERES", "IMPUESTO TIMBRE", "IMPTO TIMBRE", "COBRANZA", "SOBREGIRO", "CUOTA PRESTAMO"], CategoryID.debt),

        // Impuestos y trámites
        MerchantRule(["TESORERIA", "SII", "REGISTRO CIVIL", "MUNICIPALIDAD", "NOTARIA", "CONSERVADOR", "TGR"], CategoryID.taxes),

        // Suscripciones digitales
        MerchantRule(["NETFLIX"], CategoryID.subscriptions, merchant: "Netflix"),
        MerchantRule(["SPOTIFY"], CategoryID.subscriptions, merchant: "Spotify"),
        MerchantRule(["DISNEY"], CategoryID.subscriptions, merchant: "Disney+"),
        MerchantRule(["HBO", "MAX COM", "HBOMAX"], CategoryID.subscriptions, merchant: "Max"),
        MerchantRule(["PRIME VIDEO", "AMAZON PRIME", "PRIMEVIDEO"], CategoryID.subscriptions, merchant: "Prime Video"),
        MerchantRule(["APPLE COM BILL", "ITUNES", "ICLOUD", "APPLE COM"], CategoryID.subscriptions, merchant: "Apple"),
        MerchantRule(["YOUTUBE"], CategoryID.subscriptions, merchant: "YouTube Premium"),
        MerchantRule(["GOOGLE ONE", "GOOGLE PLAY", "GOOGLE STORAGE", "GOOGLE"], CategoryID.subscriptions, merchant: "Google"),
        MerchantRule(["PARAMOUNT"], CategoryID.subscriptions, merchant: "Paramount+"),
        MerchantRule(["CRUNCHYROLL", "MUBI", "STAR PLUS", "DIRECTV", "ZAPPING", "TWITCH", "PATREON"], CategoryID.subscriptions),
        MerchantRule(["OPENAI", "CHATGPT", "ANTHROPIC", "CLAUDE AI", "MIDJOURNEY", "NOTION", "CANVA", "ADOBE", "MICROSOFT",
                      "DROPBOX", "DUOLINGO", "LINKEDIN"], CategoryID.subscriptions),
        MerchantRule(["XBOX", "PLAYSTATION", "NINTENDO"], CategoryID.subscriptions),

        // Deporte
        MerchantRule(["SMART FIT", "SMARTFIT", "SPORTLIFE", "=ENERGY", "PACIFIC FITNESS", "GIMNASIO", "CROSSFIT", "DECATHLON"], CategoryID.sports),

        // Restaurantes y café
        MerchantRule(["STARBUCKS"], CategoryID.restaurants, merchant: "Starbucks"),
        MerchantRule(["MCDONALD"], CategoryID.restaurants, merchant: "McDonald's"),
        MerchantRule(["JUAN MAESTRO", "DOMINO", "PAPA JOHN", "BURGER KING", "KFC", "TELEPIZZA", "PIZZA", "DOGGIS", "SUBWAY",
                      "SUSHI", "RESTAURANT", "=RESTO", "CAFE", "CAFETERIA", "BAR", "DUNKIN", "TAMBO", "MAMUT", "LITTLE CAESARS",
                      "WENDY", "TARRAGONA", "=CHINA", "EMPANADA", "HELADERIA", "PASTELERIA", "FUENTE DE SODA", "SANGUCHE", "COMIDA",
                      "PEDIDOS", "BURGER", "SANDWICH"], CategoryID.restaurants),

        // Compras
        MerchantRule(["MERCADOLIBRE", "MERCADO LIBRE", "MELI"], CategoryID.shopping, merchant: "Mercado Libre"),
        MerchantRule(["FALABELLA"], CategoryID.shopping, merchant: "Falabella"),
        MerchantRule(["=PARIS"], CategoryID.shopping, merchant: "Paris"),
        MerchantRule(["RIPLEY"], CategoryID.shopping, merchant: "Ripley"),
        MerchantRule(["AMAZON"], CategoryID.shopping, merchant: "Amazon"),
        MerchantRule(["ALIEXPRESS", "SHEIN", "TEMU", "HITES", "LA POLAR", "ZARA", "H M", "ADIDAS", "NIKE", "PC FACTORY",
                      "MAC ONLINE", "MACONLINE", "APPLE STORE", "ABCDIN", "=CORONA", "TRICOT", "UNIQLO", "SKECHERS", "BATA"], CategoryID.shopping),

        // Hogar
        MerchantRule(["SODIMAC", "HOMECENTER", "EASY", "IKEA", "CASA IDEAS", "CASAIDEAS", "DAISO", "FERRETERIA", "CONSTRUMART",
                      "IMPERIAL", "LAVANDERIA", "MUEBLE"], CategoryID.home),

        // Entretención
        MerchantRule(["CINEMARK", "CINEPLANET", "HOYTS", "PUNTOTICKET", "TICKETMASTER", "PASSLINE", "STEAM", "ENJOY",
                      "CASINO", "TEATRO", "MUSEO", "BOWLING", "ENTRADAS", "FANTASILANDIA", "BUIN ZOO"], CategoryID.entertainment),

        // Viajes
        MerchantRule(["LATAM"], CategoryID.travel, merchant: "LATAM"),
        MerchantRule(["SKY AIRLINE", "SKYAIRLINE"], CategoryID.travel, merchant: "SKY Airline"),
        MerchantRule(["JETSMART"], CategoryID.travel, merchant: "JetSMART"),
        MerchantRule(["BOOKING", "AIRBNB", "DESPEGAR", "EXPEDIA", "HOTEL", "HOSTAL", "COCHA", "TURISMO"], CategoryID.travel),

        // Cuidado personal
        MerchantRule(["PELUQUERIA", "BARBERIA", "PREUNIC", "MAICAO", "DBS", "=SALON", "MANICURE", "COSMETICOS", "PERFUMERIA"], CategoryID.personalCare),

        // Regalos y donaciones
        MerchantRule(["TELETON", "HOGAR DE CRISTO", "TECHO", "UNICEF", "COANIQUEM", "DONACION", "BOMBEROS", "FUNDACION"], CategoryID.gifts),

        // Efectivo
        MerchantRule(["GIRO", "CAJERO", "ATM", "RETIRO EFECTIVO", "GIRO CAJERO"], CategoryID.cash, merchant: "Retiro de efectivo"),

        // Transferencias a terceros (al final: muy genérico)
        MerchantRule(["TRANSFERENCIA", "TRANSF", "TEF", "TRASPASO"], CategoryID.transfersOut, merchant: nil)
    ]
}
