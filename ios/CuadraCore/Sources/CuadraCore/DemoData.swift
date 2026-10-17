import Foundation

/// Generador determinista (SplitMix64) para que los datos de demostración sean siempre iguales.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Datos de ejemplo realistas (Chile) para probar la app sin conectar un banco.
public enum DemoData {
    public static func snapshot(now: Date = Date(), months: Int = 6, calendar: FinanceCalendar = .chile) -> FinanceSnapshot {
        var rng = SeededGenerator(seed: 2026)
        let checking = Account(id: "demo-checking", institutionId: "santander", name: "Cuenta Corriente",
                               numberMasked: "•••• 4821", kind: .checking, balance: 1_284_350, availableBalance: 1_284_350, source: .demo)
        let card = Account(id: "demo-card", institutionId: "santander", name: "Tarjeta Visa",
                           numberMasked: "•••• 9034", kind: .creditCard, balance: -312_900, source: .demo)
        let savings = Account(id: "demo-savings", institutionId: "bancoestado", name: "CuentaRUT",
                              numberMasked: "•••• 7710", kind: .sight, balance: 420_000, availableBalance: 420_000, source: .demo)

        let categorizer = Categorizer(userRules: [], categories: CategoryCatalog.defaults)
        var transactions: [Transaction] = []
        var counter = 0

        func add(_ description: String, _ amount: Pesos, _ date: Date, account: String = "demo-checking", hasTime: Bool = true) {
            guard date <= now else { return }
            counter += 1
            let result = categorizer.categorize(description: description, amount: amount)
            transactions.append(Transaction(id: "demo-\(counter)", accountId: account, amount: amount, date: date, hasTime: hasTime,
                                            rawDescription: description, merchant: result.merchant,
                                            categoryId: result.categoryId, categorySource: result.source, source: .demo))
        }

        func at(_ day: Date, hour: Int, minute: Int = 0) -> Date {
            calendar.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        func vary(_ base: Int, _ spread: Double) -> Int {
            let factor = 1 + Double.random(in: -spread...spread, using: &rng)
            return Int((Double(base) * factor / 10).rounded()) * 10
        }

        let firstMonth = calendar.shifted(calendar.period(.month, containing: now), by: -(months - 1))
        for monthOffset in 0..<months {
            let month = calendar.shifted(firstMonth, by: monthOffset)
            let days = calendar.days(in: month)
            func day(_ number: Int) -> Date { days[min(number, days.count) - 1] }

            // Ingresos y cuentas fijas
            add("PAGO DE REMUNERACIONES ACME SPA", 2_350_000, at(day(days.count >= 30 ? 30 : days.count), hour: 9), hasTime: false)
            add("TRANSFERENCIA A JUAN PEREZ ARRIENDO", -520_000, at(day(3), hour: 10, minute: 12))
            add("PAGO EN LINEA GASTOS COMUNES EDIFITO", -78_500, at(day(5), hour: 21, minute: 40))
            add("PAC ENEL DISTRIBUCION", -vary(38_000, 0.25), at(day(8), hour: 7), hasTime: false)
            add("PAC AGUAS ANDINAS", -vary(16_000, 0.2), at(day(10), hour: 7), hasTime: false)
            add("PAGO METROGAS", -vary(24_000, 0.35), at(day(12), hour: 19, minute: 5))
            add("PAT ENTEL PCS", -21_990, at(day(15), hour: 6), hasTime: false)
            add("PAT VTR BANDA ANCHA", -27_990, at(day(16), hour: 6), hasTime: false)
            add("PAGO ISAPRE COLMENA", -96_400, at(day(2), hour: 8), hasTime: false)
            add("NETFLIX.COM", -10_990, at(day(7), hour: 3, minute: 15), account: "demo-card")
            add("SPOTIFY P1A2B3", -6_590, at(day(11), hour: 4, minute: 2), account: "demo-card")
            add("APPLE.COM/BILL", -2_900, at(day(19), hour: 2, minute: 50), account: "demo-card")
            add("DISNEY PLUS", -9_990, at(day(21), hour: 5, minute: 10), account: "demo-card")
            add("SMART FIT LAS CONDES", -19_900, at(day(1), hour: 6, minute: 30), account: "demo-card")
            add("COMISION MANTENCION CUENTA", -4_990, at(day(1), hour: 0), hasTime: false)
            add("CUOTA CREDITO CONSUMO 12/36", -89_300, at(day(5), hour: 0), hasTime: false)
            add("PAGO TARJETA DE CREDITO", -vary(310_000, 0.15), at(day(6), hour: 13, minute: 20))
            add("PAGO TARJETA DE CREDITO", vary(310_000, 0.15), at(day(6), hour: 13, minute: 21), account: "demo-card")
            add("TRANSFERENCIA A CUENTA FINTUAL", -100_000, at(day(days.count >= 30 ? 30 : days.count), hour: 12), hasTime: true)

            // Gastos variables diarios
            for (index, date) in days.enumerated() {
                let weekday = calendar.weekdayIndex(date)
                let isWeekend = weekday >= 5
                if !isWeekend {
                    add("COMPRA NAC METRO DE SANTIAGO", -vary(1_600, 0.0), at(date, hour: 8, minute: 5 + index % 20))
                    if Int.random(in: 0..<10, using: &rng) < 6 {
                        add(["STARBUCKS COSTANERA", "CAFE ALTO MAIPU", "JUAN MAESTRO PROVIDENCIA"][index % 3],
                            -vary(4_200, 0.4), at(date, hour: 11 + index % 3, minute: 20), account: "demo-card")
                    }
                    if Int.random(in: 0..<10, using: &rng) < 3 {
                        add("UBER *TRIP", -vary(6_800, 0.5), at(date, hour: 19 + index % 3, minute: 45), account: "demo-card")
                    }
                } else {
                    if Int.random(in: 0..<10, using: &rng) < 7 {
                        add(["SUSHI BLUE RESTAURANT", "TARRAGONA PIZZA", "BAR LIGURIA"][index % 3],
                            -vary(28_000, 0.4), at(date, hour: 21, minute: 10), account: "demo-card")
                    }
                    if Int.random(in: 0..<10, using: &rng) < 5 {
                        add(["UBER EATS", "RAPPI CHILE", "PEDIDOSYA"][index % 3], -vary(14_500, 0.35),
                            at(date, hour: 14, minute: 30), account: "demo-card")
                    }
                    if Int.random(in: 0..<10, using: &rng) < 3 {
                        add("CINEMARK ALTO LAS CONDES", -vary(16_000, 0.3), at(date, hour: 18, minute: 0), account: "demo-card")
                    }
                }
                if weekday == 5 || (weekday == 2 && Int.random(in: 0..<10, using: &rng) < 5) {
                    add(["LIDER EXPRESS", "JUMBO COSTANERA", "UNIMARC"][index % 3], -vary(weekday == 5 ? 68_000 : 24_000, 0.3),
                        at(date, hour: weekday == 5 ? 11 : 20, minute: 15))
                }
                if Int.random(in: 0..<20, using: &rng) < 2 {
                    add("COPEC APP", -vary(35_000, 0.2), at(date, hour: 9, minute: 40), account: "demo-card")
                }
                if Int.random(in: 0..<20, using: &rng) < 2 {
                    add(["MERCADOLIBRE", "FALABELLA.COM", "SODIMAC HOMECENTER"][index % 3], -vary(32_000, 0.6),
                        at(date, hour: 22, minute: 30), account: "demo-card")
                }
                if Int.random(in: 0..<25, using: &rng) < 2 {
                    add("FARMACIAS CRUZ VERDE", -vary(12_000, 0.5), at(date, hour: 18, minute: 50))
                }
                if Int.random(in: 0..<10, using: &rng) < 4 {
                    add(["OXXO", "OK MARKET", "MINIMARKET DON PEPE"][index % 3], -vary(2_800, 0.5), at(date, hour: 17, minute: 55))
                }
            }
        }

        // Movimiento inusual reciente
        let recentDay = calendar.adding(days: -3, to: now)
        add("COMPRA INTERNACIONAL APPLE STORE", -649_990, at(recentDay, hour: 16, minute: 22), account: "demo-card")

        transactions = TransactionMerger.markInternalTransfers(transactions, calendar: calendar)
        transactions.sort { $0.date > $1.date }

        let profile = UserProfile(name: "Demo", declaredMonthlyIncome: nil, goal: .saveMore, housing: .rent)
        return FinanceSnapshot(profile: profile, accounts: [checking, card, savings], transactions: transactions,
                               budgets: [Budget(categoryId: CategoryID.restaurants, monthlyLimit: 180_000),
                                         Budget(categoryId: CategoryID.delivery, monthlyLimit: 60_000),
                                         Budget(categoryId: CategoryID.groceries, monthlyLimit: 320_000)],
                               goals: [SavingsGoal(name: "Viaje al sur", target: 900_000, saved: 350_000,
                                                   deadline: calendar.adding(months: 6, to: now))])
    }
}

// MARK: - Exportación

public enum CSVExporter {
    public static func export(_ transactions: [Transaction], categories: [Category], accounts: [Account],
                              calendar: FinanceCalendar = .chile) -> String {
        let categoryNames = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
        let accountNames = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0.name) })
        var lines = ["Fecha;Hora;Cuenta;Comercio;Descripción;Categoría;Monto;Nota"]
        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            let comps = calendar.calendar.dateComponents([.year, .month, .day], from: transaction.date)
            func pad(_ value: Int) -> String { value < 10 ? "0\(value)" : "\(value)" }
            let date = "\(pad(comps.day ?? 1))/\(pad(comps.month ?? 1))/\(comps.year ?? 2000)"
            let fields = [
                date,
                transaction.hasTime ? calendar.timeString(transaction.date) : "",
                accountNames[transaction.accountId] ?? "",
                transaction.merchant,
                transaction.rawDescription,
                categoryNames[transaction.categoryId] ?? transaction.categoryId,
                String(transaction.amount),
                transaction.note ?? ""
            ]
            lines.append(fields.map(escape).joined(separator: ";"))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == ";" || $0 == "\"" || $0 == "\n" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
