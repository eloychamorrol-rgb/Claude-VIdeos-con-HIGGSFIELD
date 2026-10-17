import XCTest
@testable import CuadraCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let cal = FinanceCalendar.chile

func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
    cal.calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

func tx(_ id: String, _ amount: Pesos, _ when: Date, _ category: String, merchant: String = "Comercio",
        account: String = "a1", hasTime: Bool = true, source: CategorySource = .automatic, pending: Bool = false) -> Transaction {
    Transaction(id: id, accountId: account, amount: amount, date: when, hasTime: hasTime, rawDescription: merchant,
                merchant: merchant, categoryId: category, categorySource: source, isPending: pending, source: .manual)
}

final class FormattingTests: XCTestCase {
    func testCLP() {
        XCTAssertEqual(MoneyFormat.clp(0), "$0")
        XCTAssertEqual(MoneyFormat.clp(999), "$999")
        XCTAssertEqual(MoneyFormat.clp(1_000), "$1.000")
        XCTAssertEqual(MoneyFormat.clp(1_234_567), "$1.234.567")
        XCTAssertEqual(MoneyFormat.clp(-2_500), "-$2.500")
        XCTAssertEqual(MoneyFormat.clp(2_500, signed: true), "+$2.500")
    }

    func testCompactAndPercent() {
        XCTAssertEqual(MoneyFormat.compact(850), "$850")
        XCTAssertEqual(MoneyFormat.compact(12_400), "$12 mil")
        XCTAssertEqual(MoneyFormat.compact(1_250_000), "$1,3 M")
        XCTAssertEqual(MoneyFormat.compact(1_000_000), "$1 M")
        XCTAssertEqual(MoneyFormat.compact(15_400_000), "$15 M")
        XCTAssertEqual(MoneyFormat.percent(0.256), "26 %")
        XCTAssertEqual(MoneyFormat.change(0.125), "+13 %")
        XCTAssertEqual(MoneyFormat.change(-0.08), "-8 %")
        XCTAssertEqual(MoneyFormat.decimal(2.04), "2")
        XCTAssertEqual(MoneyFormat.decimal(2.25), "2,3")
    }

    func testParse() {
        XCTAssertEqual(MoneyFormat.parse("$ 1.234.567"), 1_234_567)
        XCTAssertEqual(MoneyFormat.parse("-12.990"), -12_990)
        XCTAssertEqual(MoneyFormat.parse("1.234,50"), 1_235)
        XCTAssertEqual(MoneyFormat.parse("1,234.56"), 1_235)
        XCTAssertEqual(MoneyFormat.parse("(5.000)"), -5_000)
        XCTAssertEqual(MoneyFormat.parse("5000"), 5_000)
        XCTAssertEqual(MoneyFormat.parse("12.5"), 13)
        XCTAssertEqual(MoneyFormat.parse("1,234"), 1_234)
        XCTAssertEqual(MoneyFormat.parse("15000-"), -15_000)
        XCTAssertNil(MoneyFormat.parse(""))
        XCTAssertNil(MoneyFormat.parse("abc"))
        XCTAssertNil(MoneyFormat.parse("-"))
    }
}

final class CategorizerTests: XCTestCase {
    let categorizer = Categorizer(userRules: [], categories: CategoryCatalog.defaults)

    func check(_ description: String, _ amount: Pesos, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let result = categorizer.categorize(description: description, amount: amount)
        XCTAssertEqual(result.categoryId, expected, "\(description) -> \(result.categoryId)", file: file, line: line)
    }

    func testChileanMerchants() {
        check("COMPRA NAC UBER *TRIP 12345 SANTIAGO", -5_000, CategoryID.transport)
        check("UBER EATS 1234", -12_000, CategoryID.delivery)
        check("DIDI FOOD", -9_000, CategoryID.delivery)
        check("METROGAS S.A.", -20_000, CategoryID.utilities)
        check("METRO DE SANTIAGO", -800, CategoryID.transport)
        check("LIDER EXPRESS LAS CONDES", -15_000, CategoryID.groceries)
        check("PAC ENEL DISTRIBUCION", -35_000, CategoryID.utilities)
        check("PAGO EN LINEA GASTOS COMUNES", -80_000, CategoryID.housing)
        check("NETFLIX.COM", -10_990, CategoryID.subscriptions)
        check("APPLE.COM/BILL", -2_900, CategoryID.subscriptions)
        check("CLINICA VETERINARIA SAN FRANCISCO", -40_000, CategoryID.pets)
        check("FARMACIAS CRUZ VERDE", -8_000, CategoryID.health)
        check("COPEC", -30_000, CategoryID.car)
        check("COSTANERA NORTE TAG", -6_000, CategoryID.car)
        check("COMISION MANTENCION CUENTA", -4_990, CategoryID.bankFees)
        check("GIRO CAJERO AUTOMATICO", -40_000, CategoryID.cash)
        check("TRANSFERENCIA A JUAN PEREZ", -50_000, CategoryID.transfersOut)
        check("TRANSFERENCIA A FINTUAL", -100_000, CategoryID.savings)
        check("PAGO TARJETA DE CREDITO", -300_000, CategoryID.cardPayment)
        check("STARBUCKS COSTANERA", -4_500, CategoryID.restaurants)
        check("SMART FIT", -19_900, CategoryID.sports)
        check("ALGO DESCONOCIDO", -1_000, CategoryID.otherExpense)
    }

    func testIncome() {
        check("PAGO DE REMUNERACIONES ACME SPA", 1_500_000, CategoryID.salary)
        check("TRANSFERENCIA DE MARIA SOTO", 30_000, CategoryID.transfersIn)
        check("DEVOLUCION COMPRA FALABELLA", 15_000, CategoryID.refunds)
        check("RESCATE FINTUAL", 200_000, CategoryID.ownTransfer)
        check("ABONO DESCONOCIDO", 1_000, CategoryID.transfersIn)
        check("XYZ", 1_000, CategoryID.otherIncome)
    }

    func testShortKeywordsNeedWholeWord() {
        // "GAS" no debe calzar con "GASTOS"; "BAR" no con "BARBERIA".
        check("BARBERIA EL ROBLE", -10_000, CategoryID.personalCare)
        check("METROPOLITANO HOSPITAL", -10_000, CategoryID.health)
    }

    func testMerchantNames() {
        XCTAssertEqual(categorizer.categorize(description: "COMPRA NAC UBER *TRIP 12345", amount: -1).merchant, "Uber")
        XCTAssertEqual(TextNormalizer.merchantName(from: "COMPRA NACIONAL PANADERIA LA ESPIGA 0012 SANTIAGO CL"), "Panaderia La Espiga")
        XCTAssertEqual(TextNormalizer.merchantName(from: "12345"), "12345")
        XCTAssertEqual(TextNormalizer.normalize("Ñuñoa  Café*Bar"), "NUNOA CAFE BAR")
    }

    func testUserRulesWin() {
        let rule = UserRule(merchantKey: "UBER", categoryId: CategoryID.otherExpense)
        let custom = Categorizer(userRules: [rule], categories: CategoryCatalog.defaults)
        let result = custom.categorize(description: "UBER *TRIP", amount: -5_000)
        XCTAssertEqual(result.categoryId, CategoryID.otherExpense)
        XCTAssertEqual(result.source, .userRule)
    }

    func testCounterpartyNameForTransfers() {
        let result = categorizer.categorize(description: "TRANSFERENCIA", amount: -20_000, counterpartyName: "maría josé soto")
        XCTAssertEqual(result.categoryId, CategoryID.transfersOut)
        XCTAssertEqual(result.merchant, "Maria Jose Soto")
    }

    func testApplyKeepsManualChanges() {
        var manual = tx("1", -5_000, date(2026, 1, 1), CategoryID.travel, merchant: "Uber", source: .user)
        manual.rawDescription = "UBER TRIP"
        XCTAssertEqual(categorizer.apply(to: manual).categoryId, CategoryID.travel)
    }
}

final class PeriodTests: XCTestCase {
    func testWeekStartsMonday() {
        // 15 oct 2026 es jueves.
        let week = cal.period(.week, containing: date(2026, 10, 15))
        XCTAssertEqual(cal.weekdayIndex(week.start), 0)
        XCTAssertEqual(cal.calendar.component(.day, from: week.start), 12)
        XCTAssertEqual(cal.numberOfDays(in: week), 7)
    }

    func testMonthAndNavigation() {
        let month = cal.period(.month, containing: date(2026, 2, 10))
        XCTAssertEqual(cal.numberOfDays(in: month), 28)
        let previous = cal.previous(month)
        XCTAssertEqual(cal.calendar.component(.month, from: previous.start), 1)
        XCTAssertEqual(cal.numberOfDays(in: previous), 31)
        XCTAssertEqual(cal.title(for: month, now: date(2026, 5, 1)), "Febrero")
        XCTAssertEqual(cal.title(for: month, now: date(2027, 5, 1)), "Febrero 2026")
    }

    func testQuarterYearCustom() {
        let quarter = cal.period(.quarter, containing: date(2026, 8, 20))
        XCTAssertEqual(cal.calendar.component(.month, from: quarter.start), 7)
        XCTAssertEqual(cal.title(for: quarter), "T3 2026")
        let year = cal.period(.year, containing: date(2024, 6, 1))
        XCTAssertEqual(cal.numberOfDays(in: year), 366)
        let custom = cal.customPeriod(from: date(2026, 3, 10), through: date(2026, 3, 1))
        XCTAssertEqual(cal.numberOfDays(in: custom), 10)
        XCTAssertEqual(cal.numberOfDays(in: cal.previous(custom)), 10)
        XCTAssertTrue(custom.contains(date(2026, 3, 10, 23, 59)))
        XCTAssertFalse(custom.contains(date(2026, 3, 11, 0, 1)))
    }

    func testDSTDaysStillCountedOnce() {
        // Chile cambia de horario en abril y septiembre.
        for month in [4, 9] {
            let period = cal.period(.month, containing: date(2026, month, 15))
            let days = cal.days(in: period)
            XCTAssertEqual(days.count, 30)
            XCTAssertEqual(Set(days.map { cal.calendar.component(.day, from: $0) }).count, 30)
        }
    }

    func testElapsedDays() {
        let month = cal.period(.month, containing: date(2026, 10, 1))
        XCTAssertEqual(cal.elapsedDays(in: month, now: date(2026, 10, 17)), 17)
        XCTAssertEqual(cal.elapsedDays(in: month, now: date(2026, 11, 3)), 31)
        XCTAssertEqual(cal.elapsedDays(in: month, now: date(2026, 9, 3)), 0)
    }

    func testTitles() {
        let now = date(2026, 10, 17, 15)
        XCTAssertEqual(cal.title(for: cal.period(.day, containing: now), now: now), "Hoy")
        XCTAssertEqual(cal.title(for: cal.period(.day, containing: date(2026, 10, 16)), now: now), "Ayer")
        XCTAssertEqual(cal.title(for: cal.period(.day, containing: date(2026, 10, 12)), now: now), "Lunes 12 de octubre")
        XCTAssertEqual(cal.timeString(date(2026, 1, 1, 7, 5)), "07:05")
    }
}

final class AnalyticsTests: XCTestCase {
    let engine = AnalyticsEngine(categories: CategoryCatalog.defaults)

    func testSummaryTotals() {
        let items = [
            tx("s", 1_000_000, date(2026, 9, 1), CategoryID.salary),
            tx("r", -400_000, date(2026, 9, 3), CategoryID.housing),
            tx("f", -100_000, date(2026, 9, 5, 20), CategoryID.restaurants, merchant: "Sushi"),
            tx("f2", -50_000, date(2026, 9, 6, 20), CategoryID.restaurants, merchant: "Sushi"),
            tx("refund", 10_000, date(2026, 9, 7), CategoryID.restaurants, merchant: "Sushi"),
            tx("save", -100_000, date(2026, 9, 10), CategoryID.savings),
            tx("card", -300_000, date(2026, 9, 10), CategoryID.cardPayment),
            tx("coffee", -3_000, date(2026, 9, 11, 9), CategoryID.restaurants, merchant: "Cafe"),
            tx("other-month", -999_999, date(2026, 10, 1), CategoryID.housing)
        ]
        let summary = engine.summary(of: items, in: cal.period(.month, containing: date(2026, 9, 15)), now: date(2026, 12, 1))
        XCTAssertEqual(summary.income, 1_000_000)
        XCTAssertEqual(summary.needs, 400_000)
        XCTAssertEqual(summary.wants, 143_000)
        XCTAssertEqual(summary.spending, 543_000)
        XCTAssertEqual(summary.savingsTransfers, 100_000)
        XCTAssertEqual(summary.net, 357_000)
        XCTAssertEqual(summary.savingsRate!, 0.457, accuracy: 0.0001)
        XCTAssertEqual(summary.byCategory.first?.categoryId, CategoryID.housing)
        XCTAssertEqual(summary.byCategory.first { $0.categoryId == CategoryID.restaurants }?.amount, 143_000)
        XCTAssertEqual(summary.topMerchants.first { $0.name == "Sushi" }?.amount, 140_000)
        XCTAssertEqual(summary.daily.count, 30)
        XCTAssertEqual(summary.daily.reduce(0) { $0 + $1.spending }, 543_000)
        XCTAssertEqual(summary.byHour[20].amount, 150_000)
        XCTAssertEqual(summary.smallExpenses.count, 1)
        XCTAssertNil(summary.projectedSpending)
        XCTAssertEqual(summary.averageDailySpending, 543_000 / 30)
    }

    func testProjectionForCurrentPeriod() {
        let items = [tx("a", -10_000, date(2026, 10, 2), CategoryID.groceries)]
        let summary = engine.summary(of: items, in: cal.period(.month, containing: date(2026, 10, 1)), now: date(2026, 10, 10))
        XCTAssertEqual(summary.elapsedDays, 10)
        XCTAssertEqual(summary.projectedSpending, 31_000)

        // El arriendo (fijo) y una compra puntual grande no se extrapolan.
        let mixed = items + [tx("rent", -500_000, date(2026, 10, 1), CategoryID.housing),
                             tx("tv", -400_000, date(2026, 10, 3), CategoryID.shopping)]
        let mixedSummary = engine.summary(of: mixed, in: cal.period(.month, containing: date(2026, 10, 1)), now: date(2026, 10, 10))
        XCTAssertEqual(mixedSummary.projectedSpending, 931_000)
        XCTAssertEqual(mixedSummary.projectedByCategory[CategoryID.housing], 500_000)
    }

    func testWeekdayAverages() {
        // Septiembre 2026 empieza en martes; sábados: 5, 12, 19, 26.
        let items = [tx("a", -40_000, date(2026, 9, 5), CategoryID.restaurants)]
        let summary = engine.summary(of: items, in: cal.period(.month, containing: date(2026, 9, 1)), now: date(2026, 12, 1))
        XCTAssertEqual(summary.byWeekday[5].amount, 40_000)
        XCTAssertEqual(summary.byWeekday[5].averagePerDay, 10_000)
    }

    func testTrendAndComparison() {
        let items = [
            tx("a", -100, date(2026, 8, 3), CategoryID.groceries),
            tx("b", -300, date(2026, 9, 3), CategoryID.groceries),
            tx("c", 1_000, date(2026, 9, 4), CategoryID.salary)
        ]
        let trend = engine.monthlyTrend(items, months: 3, endingAt: date(2026, 9, 20))
        XCTAssertEqual(trend.map(\.spending), [0, 100, 300])
        XCTAssertEqual(trend.last?.net, 700)
        let sep = engine.summary(of: items, in: cal.period(.month, containing: date(2026, 9, 1)), now: date(2026, 12, 1))
        let aug = engine.summary(of: items, in: cal.period(.month, containing: date(2026, 8, 1)), now: date(2026, 12, 1))
        let delta = engine.compare(sep, with: aug).first!
        XCTAssertEqual(delta.difference, 200)
        XCTAssertEqual(delta.change!, 2, accuracy: 0.001)
    }

    func testCategorySeries() {
        let items = [
            tx("a", -1_000, date(2026, 9, 1), CategoryID.transport),
            tx("b", -2_000, date(2026, 9, 8), CategoryID.transport),
            tx("c", -5_000, date(2026, 9, 8), CategoryID.groceries)
        ]
        let series = engine.categorySeries(items, categoryId: CategoryID.transport,
                                           in: cal.period(.month, containing: date(2026, 9, 1)), bucket: .week)
        XCTAssertEqual(series.reduce(0) { $0 + $1.1 }, 3_000)
        XCTAssertEqual(series.count, 5)
    }
}

final class RecurringTests: XCTestCase {
    let engine = AnalyticsEngine(categories: CategoryCatalog.defaults)

    func testMonthlySubscriptionDetected() {
        let items = (1...4).map { tx("n\($0)", -10_990, date(2026, 5 + $0, 7), CategoryID.subscriptions, merchant: "Netflix") }
        let charges = RecurringDetector(engine: engine).detect(items, now: date(2026, 9, 20))
        XCTAssertEqual(charges.count, 1)
        let netflix = charges[0]
        XCTAssertEqual(netflix.cadence, .monthly)
        XCTAssertEqual(netflix.typicalAmount, 10_990)
        XCTAssertTrue(netflix.isActive)
        XCTAssertTrue(netflix.isSubscription)
        XCTAssertEqual(cal.calendar.component(.month, from: netflix.nextDate), 10)
        XCTAssertEqual(netflix.yearlyCost, 131_880)
        let upcoming = RecurringDetector(engine: engine).upcoming(charges, now: date(2026, 10, 1), days: 7)
        XCTAssertEqual(upcoming.count, 1)
    }

    func testIrregularNotDetectedAndCancelledInactive() {
        let rides = [1, 2, 4, 9, 10, 11, 20].map { tx("u\($0)", -5_000, date(2026, 9, $0), CategoryID.transport, merchant: "Uber") }
        XCTAssertTrue(RecurringDetector(engine: engine).detect(rides, now: date(2026, 9, 30)).isEmpty)

        let old = (1...3).map { tx("s\($0)", -6_590, date(2026, $0, 11), CategoryID.subscriptions, merchant: "Spotify") }
        let charges = RecurringDetector(engine: engine).detect(old, now: date(2026, 9, 30))
        XCTAssertEqual(charges.count, 1)
        XCTAssertFalse(charges[0].isActive)
    }

    func testUnusualAndSpikes() {
        var items: [Transaction] = []
        for month in 6...9 {
            for day in [3, 10, 17, 24] {
                items.append(tx("g\(month)-\(day)", -20_000, date(2026, month, day), CategoryID.groceries))
            }
        }
        items.append(tx("big", -150_000, date(2026, 9, 26), CategoryID.groceries))
        let detector = AnomalyDetector(engine: engine)
        let unusual = detector.unusualTransactions(items, in: cal.period(.month, containing: date(2026, 9, 1)))
        XCTAssertEqual(unusual.map(\.transaction.id), ["big"])
        XCTAssertEqual(unusual[0].typicalAmount, 20_000)

        let spikes = detector.categorySpikes(items, month: cal.period(.month, containing: date(2026, 9, 1)), now: date(2026, 10, 5))
        XCTAssertEqual(spikes.first?.categoryId, CategoryID.groceries)
        XCTAssertEqual(spikes.first?.current, 230_000)
        XCTAssertEqual(spikes.first?.baseline, 80_000)
    }
}

final class AdvisorTests: XCTestCase {
    let engine = AnalyticsEngine(categories: CategoryCatalog.defaults)

    func monthlyHistory() -> [Transaction] {
        var items: [Transaction] = []
        for month in 7...9 {
            items.append(tx("sal\(month)", 1_000_000, date(2026, month, 1), CategoryID.salary))
            items.append(tx("rent\(month)", -450_000, date(2026, month, 2), CategoryID.housing))
            items.append(tx("food\(month)", -150_000, date(2026, month, 5), CategoryID.groceries))
            items.append(tx("fun\(month)", -360_000, date(2026, month, 6), CategoryID.restaurants))
            items.append(tx("fee\(month)", -5_000, date(2026, month, 6), CategoryID.bankFees))
        }
        return items
    }

    func testIncomeEstimateAndSplit() {
        let advisor = FinancialAdvisor(engine: engine)
        let input = AdvisorInput(transactions: monthlyHistory(), accounts: [], budgets: [], profile: UserProfile(), now: date(2026, 10, 15))
        XCTAssertEqual(advisor.estimatedMonthlyIncome(input), 1_000_000)
        let split = advisor.split(input)!
        XCTAssertEqual(split.needs, 605_000)
        XCTAssertEqual(split.wants, 360_000)
        XCTAssertEqual(split.savings, 35_000)

        var declared = input
        declared.profile.declaredMonthlyIncome = 2_000_000
        XCTAssertEqual(advisor.estimatedMonthlyIncome(declared), 2_000_000)
    }

    func testInsightsAreRelevantAndSorted() {
        let advisor = FinancialAdvisor(engine: engine)
        let accounts = [Account(id: "a1", institutionId: "santander", name: "CC", kind: .checking, balance: 300_000,
                                availableBalance: 300_000, source: .manual)]
        let input = AdvisorInput(transactions: monthlyHistory(), accounts: accounts, budgets: [], profile: UserProfile(), now: date(2026, 10, 15))
        let insights = advisor.insights(input)
        let ids = insights.map(\.id)
        XCTAssertTrue(ids.contains("savings-low"))
        XCTAssertTrue(ids.contains("wants-high"))
        XCTAssertTrue(ids.contains("fees"))
        XCTAssertTrue(ids.contains("emergency-low"))
        XCTAssertTrue(ids.contains("no-budgets"))
        XCTAssertEqual(Set(ids).count, ids.count, "ids únicos")
        XCTAssertEqual(insights.map(\.kind), insights.map(\.kind).sorted())
    }

    func testPlanRespectsRule() {
        let advisor = FinancialAdvisor(engine: engine)
        let input = AdvisorInput(transactions: monthlyHistory(), accounts: [], budgets: [], profile: UserProfile(), now: date(2026, 10, 15))
        let plan = advisor.suggestedPlan(input)!
        XCTAssertEqual(plan.income, 1_000_000)
        XCTAssertEqual(plan.needsTarget, 500_000)
        XCTAssertEqual(plan.wantsTarget, 300_000)
        let housing = plan.lines.first { $0.categoryId == CategoryID.housing }!
        XCTAssertEqual(housing.suggested, 450_000, "los gastos fijos no se recortan")
        let fun = plan.lines.first { $0.categoryId == CategoryID.restaurants }!
        XCTAssertEqual(fun.suggested, 300_000)
        XCTAssertGreaterThan(plan.projectedSavings, 0)
        XCTAssertTrue(plan.lines.allSatisfy { $0.suggested % 1_000 == 0 })
    }

    func testHealthScoreAndBudgets() {
        let advisor = FinancialAdvisor(engine: engine)
        var items = monthlyHistory()
        for day in 1...10 { items.append(tx("oct-fun\(day)", -29_000, date(2026, 10, day), CategoryID.restaurants)) }
        let input = AdvisorInput(transactions: items, accounts: [], budgets: [Budget(categoryId: CategoryID.restaurants, monthlyLimit: 300_000)],
                                 profile: UserProfile(), now: date(2026, 10, 15))
        let statuses = advisor.budgetStatuses(input)
        XCTAssertEqual(statuses.first?.spent, 290_000)
        XCTAssertGreaterThan(statuses.first!.projected, 300_000)
        XCTAssertTrue(advisor.insights(input).contains { $0.id == "budget-near-\(CategoryID.restaurants)" })
        let score = advisor.healthScore(input)!
        XCTAssertTrue((0...100).contains(score.score))
        XCTAssertEqual(score.components.count, 5)
        XCTAssertEqual(score.components.reduce(0) { $0 + $1.points }, score.score)
    }

    func testEmptyData() {
        let advisor = FinancialAdvisor(engine: engine)
        let input = AdvisorInput(transactions: [], accounts: [], budgets: [], profile: UserProfile(), now: date(2026, 10, 15))
        XCTAssertEqual(advisor.insights(input).map(\.id), ["empty"])
        XCTAssertNil(advisor.healthScore(input))
        XCTAssertNil(advisor.suggestedPlan(input))
    }

    func testGoalContribution() {
        let goal = SavingsGoal(name: "Viaje", target: 1_200_000, saved: 200_000, deadline: date(2027, 3, 15))
        XCTAssertEqual(goal.monthlyContributionNeeded(now: date(2026, 10, 15), calendar: cal.calendar), 166_667)
        XCTAssertEqual(goal.progress, 1.0 / 6.0, accuracy: 0.0001)
    }
}

final class ImportAndSyncTests: XCTestCase {
    let categorizer = Categorizer(userRules: [], categories: CategoryCatalog.defaults)

    func testSantanderStyleCSV() throws {
        let csv = """
        Cartola de movimientos;;;;
        Cuenta;0-000-12-34567-8;;;
        Fecha;Descripción;N° Documento;Cargos;Abonos
        01/09/2026;COMPRA NAC LIDER EXPRESS;123;15.990;
        02/09/2026;PAGO DE REMUNERACIONES;;;1.500.000
        03/09/2026;"TRANSFERENCIA A ""JUAN""; PEREZ";;50.000;
        xx/09/2026;FILA INVALIDA;;1;
        """
        let result = try CSVImporter().parse(csv)
        XCTAssertEqual(result.rows.count, 3)
        XCTAssertEqual(result.skippedRows, 1)
        XCTAssertEqual(result.rows[0].amount, -15_990)
        XCTAssertEqual(result.rows[1].amount, 1_500_000)
        XCTAssertEqual(result.rows[2].description, "TRANSFERENCIA A \"JUAN\"; PEREZ")
        XCTAssertEqual(cal.calendar.component(.day, from: result.rows[0].date), 1)
        XCTAssertFalse(result.rows[0].hasTime)

        let transactions = CSVImporter().transactions(from: result.rows, accountId: "acc", categorizer: categorizer)
        XCTAssertEqual(transactions[0].categoryId, CategoryID.groceries)
        XCTAssertEqual(transactions[1].categoryId, CategoryID.salary)
        let again = CSVImporter().transactions(from: result.rows, accountId: "acc", categorizer: categorizer)
        XCTAssertEqual(transactions.map(\.id), again.map(\.id), "ids estables")
    }

    func testSignedAmountCSVWithTime() throws {
        let csv = """
        fecha,hora,detalle,monto
        2026-09-05,14:32,UBER TRIP,"-6.500"
        2026-09-05,14:32,UBER TRIP,"-6.500"
        2026-09-06,00:00,NETFLIX,-10990
        """
        let result = try CSVImporter().parse(csv)
        XCTAssertEqual(result.rows.count, 3)
        XCTAssertTrue(result.rows[0].hasTime)
        XCTAssertEqual(cal.hour(result.rows[0].date), 14)
        XCTAssertFalse(result.rows[2].hasTime)
        let transactions = CSVImporter().transactions(from: result.rows, accountId: "acc", categorizer: categorizer)
        XCTAssertEqual(Set(transactions.map(\.id)).count, 3, "filas idénticas reciben ids distintas")
    }

    func testCSVErrors() {
        XCTAssertThrowsError(try CSVImporter().parse("")) { XCTAssertEqual($0 as? CSVImportError, .empty) }
        XCTAssertThrowsError(try CSVImporter().parse("a;b\n1;2")) { XCTAssertEqual($0 as? CSVImportError, .headerNotFound) }
        XCTAssertThrowsError(try CSVImporter().parse("Fecha;Detalle;Monto\n99/99/2026;X;1")) {
            XCTAssertEqual($0 as? CSVImportError, .noValidRows)
        }
    }

    func testFintocDatesWithoutTimeStayOnSameDay() throws {
        let json = """
        [{"id":"mov_1","amount":-12990,"currency":"CLP","description":"COMPRA NAC JUMBO","post_date":"2026-09-01T00:00:00.000Z",
          "transaction_date":null,"type":"outbound","pending":false,"recipient_account":null,"sender_account":null,"comment":null},
         {"id":"mov_2","amount":50000,"currency":"CLP","description":"TRANSFERENCIA","post_date":"2026-09-10T00:00:00Z",
          "transaction_date":"2026-09-10T18:45:10Z","type":"inbound","pending":true,
          "sender_account":{"holder_name":"PEDRO GONZALEZ","number":"123"},"recipient_account":null,"comment":"asado"}]
        """
        let movements = try JSONDecoder().decode([RemoteMovement].self, from: Data(json.utf8))
        let mapper = BankMapper()
        let first = mapper.transaction(movements[0], accountId: "a", categorizer: categorizer)!
        XCTAssertEqual(cal.calendar.component(.day, from: first.date), 1)
        XCTAssertFalse(first.hasTime)
        XCTAssertEqual(first.categoryId, CategoryID.groceries)
        XCTAssertEqual(first.id, "bank-mov_1")

        let second = mapper.transaction(movements[1], accountId: "a", categorizer: categorizer)!
        XCTAssertTrue(second.hasTime)
        XCTAssertEqual(cal.hour(second.date), 15) // 18:45 UTC = 15:45 en Santiago (horario de verano)
        XCTAssertEqual(second.merchant, "Pedro Gonzalez")
        XCTAssertEqual(second.categoryId, CategoryID.transfersIn)
        XCTAssertEqual(second.note, "asado")
        XCTAssertTrue(second.isPending)
    }

    func testAccountMapping() throws {
        let json = """
        {"id":"acc_1","name":"Cuenta Corriente","official_name":"CTA CTE","number":"0000123456789","type":"checking_account",
         "currency":"CLP","balance":{"available":500000,"current":520000,"limit":0}}
        """
        let remote = try JSONDecoder().decode(RemoteAccount.self, from: Data(json.utf8))
        let link = BankLink(id: "lnk", institutionId: "santander", institutionName: "Santander", createdAt: Date())
        let account = BankMapper().account(remote, link: link, existing: nil, now: Date())
        XCTAssertEqual(account.id, "bank-lnk-acc_1")
        XCTAssertEqual(account.kind, .checking)
        XCTAssertEqual(account.numberMasked, "•••• 6789")
        XCTAssertEqual(account.availableBalance, 500_000)
    }

    func testMergeKeepsUserChangesAndDropsStalePending() {
        let existing = [
            tx("bank-1", -5_000, date(2026, 9, 1), CategoryID.travel, source: .user),
            tx("bank-2", -7_000, date(2026, 9, 2), CategoryID.groceries, pending: true),
            tx("bank-old-pending", -1_000, date(2026, 8, 1), CategoryID.groceries, pending: true),
            tx("manual", -1_000, date(2026, 9, 2), CategoryID.groceries, account: "cash", pending: true)
        ]
        let incoming = [
            tx("bank-1", -5_000, date(2026, 9, 1), CategoryID.transport),
            tx("bank-3", -7_000, date(2026, 9, 3), CategoryID.groceries)
        ]
        let result = TransactionMerger.merge(existing: existing, incoming: incoming, syncedAccounts: ["a1"], since: date(2026, 8, 30))
        XCTAssertEqual(result.inserted, 1)
        XCTAssertEqual(result.removedPending, 1)
        let ids = Set(result.transactions.map(\.id))
        XCTAssertEqual(ids, ["bank-1", "bank-3", "bank-old-pending", "manual"])
        XCTAssertEqual(result.transactions.first { $0.id == "bank-1" }?.categoryId, CategoryID.travel)
    }

    func testInternalTransfers() {
        let items = [
            tx("out", -100_000, date(2026, 9, 1), CategoryID.transfersOut, account: "a1"),
            tx("in", 100_000, date(2026, 9, 2), CategoryID.transfersIn, account: "a2"),
            tx("friend", -100_000, date(2026, 9, 1), CategoryID.transfersOut, account: "a1")
        ]
        let marked = TransactionMerger.markInternalTransfers(items)
        XCTAssertEqual(marked.filter { $0.categoryId == CategoryID.ownTransfer }.count, 2)
        XCTAssertEqual(marked.first { $0.id == "friend" }?.categoryId, CategoryID.transfersOut)
    }

    func testDemoDataIsConsistent() throws {
        let snapshot = DemoData.snapshot(now: date(2026, 10, 17, 18))
        XCTAssertGreaterThan(snapshot.transactions.count, 300)
        XCTAssertEqual(Set(snapshot.transactions.map(\.id)).count, snapshot.transactions.count)
        XCTAssertTrue(snapshot.transactions.allSatisfy { $0.date <= date(2026, 10, 17, 18) })
        let engine = AnalyticsEngine(categories: snapshot.categories)
        let advisor = FinancialAdvisor(engine: engine)
        let input = AdvisorInput(transactions: snapshot.transactions, accounts: snapshot.accounts, budgets: snapshot.budgets,
                                 goals: snapshot.goals, profile: snapshot.profile!, now: date(2026, 10, 17, 18))
        let insights = advisor.insights(input)
        XCTAssertFalse(insights.isEmpty)
        XCTAssertEqual(Set(insights.map(\.id)).count, insights.count)
        XCTAssertNotNil(advisor.healthScore(input))
        let charges = RecurringDetector(engine: engine).detect(snapshot.transactions, now: date(2026, 10, 17, 18))
        let names = Set(charges.map(\.merchant))
        XCTAssertTrue(names.isSuperset(of: ["Netflix", "Spotify"]), "\(names)")
        let unknown = snapshot.transactions.filter { $0.categoryId == CategoryID.otherExpense }
        XCTAssertTrue(unknown.isEmpty, unknown.map(\.rawDescription).joined(separator: ", "))

        // Ida y vuelta por JSON.
        let data = try FinanceSnapshot.encoder().encode(snapshot)
        let decoded = try FinanceSnapshot.decoder().decode(FinanceSnapshot.self, from: data)
        XCTAssertEqual(decoded.transactions.count, snapshot.transactions.count)
        XCTAssertEqual(decoded.budgets, snapshot.budgets)

        let csv = CSVExporter.export(snapshot.transactions, categories: snapshot.categories, accounts: snapshot.accounts)
        XCTAssertEqual(csv.split(separator: "\n").count, snapshot.transactions.count + 1)
    }
}

final class BackendClientTests: XCTestCase {
    struct MockTransport: HTTPTransport {
        let status: Int
        let body: String
        let check: @Sendable (URLRequest) -> Void

        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            check(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (Data(body.utf8), response)
        }
    }

    func testMovementsRequestAndDecoding() async throws {
        let transport = MockTransport(status: 200, body: #"{"movements":[{"id":"m1","amount":-100,"currency":"CLP","description":"X","post_date":"2026-09-01T00:00:00Z"}]}"#) { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tok")
            XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/links/l1/accounts/a1/movements?since=2026-09-01")
        }
        let client = BackendClient(baseURL: URL(string: "https://api.example.com")!, token: "tok", transport: transport)
        let movements = try await client.movements(linkId: "l1", accountId: "a1", since: date(2026, 9, 1))
        XCTAssertEqual(movements.first?.amount, -100)
    }

    func testLinkDecodingWithFractionalDates() async throws {
        let transport = MockTransport(status: 200, body: #"{"link":{"id":"l1","institution":{"id":"cl_banco_santander","name":"Banco Santander"},"holderName":"Ana","createdAt":"2026-10-17T01:13:49.102Z"}}"#) { _ in }
        let client = BackendClient(baseURL: URL(string: "https://api.example.com")!, token: "tok", transport: transport)
        let link = try await client.exchange(exchangeToken: "x")
        XCTAssertEqual(Institution.resolve(id: link.institution.id, name: link.institution.name).id, "santander")
    }

    func testErrors() async {
        let reconnect = MockTransport(status: 409, body: #"{"error":"Reconecta tu banco","code":"link_needs_reconnect"}"#) { _ in }
        let client = BackendClient(baseURL: URL(string: "https://api.example.com")!, token: "tok", transport: reconnect)
        do {
            _ = try await client.links()
            XCTFail("debía fallar")
        } catch {
            XCTAssertEqual(error as? BackendError, .linkNeedsReconnect("Reconecta tu banco"))
        }
        let unauthorized = BackendClient(baseURL: URL(string: "https://api.example.com")!, token: nil, transport: reconnect)
        do {
            _ = try await unauthorized.links()
            XCTFail("debía fallar")
        } catch {
            XCTAssertEqual(error as? BackendError, .unauthorized)
        }
    }

    func testInstitutionResolution() {
        XCTAssertEqual(Institution.resolve(id: "cl_banco_de_chile", name: "Banco de Chile").id, "banco_de_chile")
        XCTAssertEqual(Institution.resolve(id: "cl_banco_estado", name: "BancoEstado").id, "bancoestado")
        XCTAssertEqual(Institution.resolve(id: "cl_banco_itau", name: "Itaú").id, "itau")
        XCTAssertEqual(Institution.resolve(id: "xyz", name: "Cooperativa Nueva").name, "Cooperativa Nueva")
    }
}
