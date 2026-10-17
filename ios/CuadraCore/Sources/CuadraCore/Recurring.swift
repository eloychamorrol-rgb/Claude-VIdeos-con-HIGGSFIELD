import Foundation

public enum Cadence: String, Codable, CaseIterable, Sendable {
    case weekly, biweekly, monthly, quarterly, yearly

    public var title: String {
        switch self {
        case .weekly: return "Semanal"
        case .biweekly: return "Quincenal"
        case .monthly: return "Mensual"
        case .quarterly: return "Trimestral"
        case .yearly: return "Anual"
        }
    }

    /// Rango aceptado de días entre cobros.
    var dayRange: ClosedRange<Double> {
        switch self {
        case .weekly: return 6...8
        case .biweekly: return 13...17
        case .monthly: return 26...35
        case .quarterly: return 84...98
        case .yearly: return 350...380
        }
    }

    var nominalDays: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 91
        case .yearly: return 365
        }
    }

    /// Factor para llevar un cobro a su equivalente mensual.
    public var monthlyFactor: Double {
        switch self {
        case .weekly: return 52.0 / 12.0
        case .biweekly: return 26.0 / 12.0
        case .monthly: return 1
        case .quarterly: return 1.0 / 3.0
        case .yearly: return 1.0 / 12.0
        }
    }
}

public struct RecurringCharge: Identifiable, Hashable, Sendable {
    public var id: String { merchantKey }
    public let merchantKey: String
    public let merchant: String
    public let categoryId: String
    public let cadence: Cadence
    /// Monto típico (positivo).
    public let typicalAmount: Pesos
    public let lastDate: Date
    public let nextDate: Date
    public let occurrences: Int
    public let isActive: Bool

    public var monthlyCost: Pesos { Int((Double(typicalAmount) * cadence.monthlyFactor).rounded()) }
    public var yearlyCost: Pesos { Int((Double(typicalAmount) * cadence.monthlyFactor * 12).rounded()) }
    public var isSubscription: Bool { categoryId == CategoryID.subscriptions || categoryId == CategoryID.sports }
}

/// Detecta cobros periódicos (suscripciones, cuentas, arriendo, etc.).
public struct RecurringDetector: Sendable {
    public let engine: AnalyticsEngine

    public init(engine: AnalyticsEngine) { self.engine = engine }

    public func detect(_ transactions: [Transaction], now: Date = Date()) -> [RecurringCharge] {
        let calendar = engine.calendar
        let expenses = transactions.filter {
            $0.amount < 0 && $0.currency == engine.currency && $0.date <= now
                && [.needs, .wants, .savings].contains(engine.group(of: $0))
        }
        let groups = Dictionary(grouping: expenses, by: \.merchantKey)
        var result: [RecurringCharge] = []

        for (key, items) in groups where !key.isEmpty {
            // Un cobro por día como máximo (varios el mismo día no son periódicos).
            var byDay: [Date: Transaction] = [:]
            for item in items {
                let day = calendar.startOfDay(item.date)
                if let existing = byDay[day] {
                    if item.amount < existing.amount { byDay[day] = item }
                } else {
                    byDay[day] = item
                }
            }
            let sorted = byDay.values.sorted { $0.date < $1.date }
            guard let last = sorted.last else { continue }
            let category = engine.category(last.categoryId)
            let isBill = [CategoryID.subscriptions, CategoryID.utilities, CategoryID.housing, CategoryID.insurance,
                          CategoryID.sports, CategoryID.education, CategoryID.debt].contains(category.id)
            guard sorted.count >= (isBill ? 2 : 3) else { continue }

            let intervals = zip(sorted, sorted.dropFirst()).map { pair -> Double in
                Double(calendar.calendar.dateComponents([.day], from: calendar.startOfDay(pair.0.date),
                                                         to: calendar.startOfDay(pair.1.date)).day ?? 0)
            }
            let medianInterval = median(intervals)
            guard let cadence = Cadence.allCases.first(where: { $0.dayRange.contains(medianInterval) }) else { continue }
            let regular = intervals.filter { cadence.dayRange.contains($0) }.count
            guard Double(regular) / Double(intervals.count) >= 0.7 else { continue }

            let amounts = sorted.map { Double(-$0.amount) }
            let typical = median(amounts)
            let tolerance = category.id == CategoryID.utilities ? 0.45 : 0.2
            let similar = amounts.filter { abs($0 - typical) <= typical * tolerance }.count
            guard typical > 0, Double(similar) / Double(amounts.count) >= 0.7 else { continue }

            let nextDate: Date
            switch cadence {
            case .weekly: nextDate = calendar.adding(days: 7, to: last.date)
            case .biweekly: nextDate = calendar.adding(days: 14, to: last.date)
            case .monthly: nextDate = calendar.adding(months: 1, to: last.date)
            case .quarterly: nextDate = calendar.adding(months: 3, to: last.date)
            case .yearly: nextDate = calendar.adding(months: 12, to: last.date)
            }
            let graceDays = Int(cadence.dayRange.upperBound) - cadence.nominalDays + 7
            let isActive = now <= calendar.adding(days: graceDays, to: nextDate)

            result.append(RecurringCharge(
                merchantKey: key, merchant: last.merchant, categoryId: category.id, cadence: cadence,
                typicalAmount: Int(typical.rounded()), lastDate: last.date, nextDate: nextDate,
                occurrences: sorted.count, isActive: isActive
            ))
        }
        return result.sorted { $0.monthlyCost != $1.monthlyCost ? $0.monthlyCost > $1.monthlyCost : $0.merchantKey < $1.merchantKey }
    }

    /// Cobros activos esperados entre `now` y `now + days`.
    public func upcoming(_ charges: [RecurringCharge], now: Date, days: Int) -> [RecurringCharge] {
        let limit = engine.calendar.adding(days: days, to: now)
        let today = engine.calendar.startOfDay(now)
        return charges
            .filter { $0.isActive && $0.nextDate >= today && $0.nextDate <= limit }
            .sorted { $0.nextDate < $1.nextDate }
    }
}

func median(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0 }
    let sorted = values.sorted()
    let middle = sorted.count / 2
    return sorted.count % 2 == 0 ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
}

// MARK: - Gastos inusuales

public struct UnusualTransaction: Identifiable, Hashable, Sendable {
    public var id: String { transaction.id }
    public let transaction: Transaction
    public let typicalAmount: Pesos
    public var ratio: Double { typicalAmount > 0 ? Double(-transaction.amount) / Double(typicalAmount) : 0 }
}

public struct CategorySpike: Identifiable, Hashable, Sendable {
    public var id: String { categoryId }
    public let categoryId: String
    public let current: Pesos
    public let baseline: Pesos
    public var change: Double { baseline > 0 ? Double(current - baseline) / Double(baseline) : 0 }
}

public struct AnomalyDetector: Sendable {
    public let engine: AnalyticsEngine

    public init(engine: AnalyticsEngine) { self.engine = engine }

    /// Gastos del período que superan 3 veces lo típico (del mismo comercio si hay historial suficiente,
    /// si no de su categoría) y además están entre el 5 % más alto de la categoría (últimos 180 días).
    public func unusualTransactions(_ transactions: [Transaction], in period: Period) -> [UnusualTransaction] {
        let calendar = engine.calendar
        let historyStart = calendar.adding(days: -180, to: period.start)
        let history = transactions.filter {
            $0.amount < 0 && $0.date >= historyStart && $0.currency == engine.currency && engine.group(of: $0).isSpending
        }
        let byCategory = Dictionary(grouping: history, by: \.categoryId)
        var result: [UnusualTransaction] = []
        for transaction in engine.transactions(transactions, in: period)
        where transaction.amount < 0 && engine.group(of: transaction).isSpending {
            let others = (byCategory[transaction.categoryId] ?? []).filter { $0.id != transaction.id && $0.date < transaction.date }
            guard others.count >= 5 else { continue }
            let categoryAmounts = others.map { Double(-$0.amount) }.sorted()
            let sameMerchant = others.filter { $0.merchantKey == transaction.merchantKey }.map { Double(-$0.amount) }
            let typical = sameMerchant.count >= 4 ? median(sameMerchant) : median(categoryAmounts)
            let p95 = categoryAmounts[min(categoryAmounts.count - 1, Int(Double(categoryAmounts.count) * 0.95))]
            let spent = Double(-transaction.amount)
            if typical > 0, spent >= typical * 3, spent > p95, spent - typical >= 15_000 {
                result.append(UnusualTransaction(transaction: transaction, typicalAmount: Int(typical.rounded())))
            }
        }
        return result.sorted { $0.ratio > $1.ratio }
    }

    /// Categorías cuyo gasto del mes supera en más de 30 % el promedio de los 3 meses anteriores.
    /// Si el mes está en curso se compara la proyección al cierre.
    public func categorySpikes(_ transactions: [Transaction], month: Period, now: Date) -> [CategorySpike] {
        let calendar = engine.calendar
        let baselineMonths = (1...3).map { calendar.shifted(month, by: -$0) }
        let monthsWithData = baselineMonths.filter { period in
            transactions.contains { period.contains($0.date) }
        }
        guard monthsWithData.count >= 2 else { return [] }
        let baseline = engine.averageMonthlySpending(transactions, months: monthsWithData)
        let summary = engine.summary(of: transactions, in: month, now: now)

        return summary.byCategory.compactMap { total -> CategorySpike? in
            let base = baseline[total.categoryId] ?? 0
            let isFixed = CategoryCatalog.fixedNeeds.contains(total.categoryId)
            let projected = summary.projectedByCategory[total.categoryId] ?? total.amount
            // Al inicio de mes la proyección es poco confiable.
            if summary.isInProgress && summary.elapsedDays < 10 && !isFixed { return nil }
            guard base > 0, Double(projected) > Double(base) * 1.3, projected - base >= 20_000 else { return nil }
            return CategorySpike(categoryId: total.categoryId, current: projected, baseline: base)
        }
        .sorted { ($0.current - $0.baseline) > ($1.current - $1.baseline) }
    }
}
