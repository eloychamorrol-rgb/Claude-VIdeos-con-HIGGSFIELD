import SwiftUI
import Charts
import CuadraCore

struct AnalysisView: View {
    @Environment(FinanceStore.self) private var store
    @State private var kind = PeriodKind.month
    @State private var period = FinanceCalendar.chile.period(.month, containing: Date())
    @State private var selectedAngle: Int?

    var body: some View {
        let summary = store.summary(for: period)
        let previous = store.summary(for: store.calendar.previous(period))
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PeriodSelector(kind: $kind, period: $period, calendar: store.calendar)
                        .padding(.top, 4)

                    if summary.transactionCount == 0 {
                        EmptyStateView(symbol: "chart.bar", title: "Sin movimientos en este período",
                                       message: "Elige otro período o agrega movimientos.")
                            .card()
                    } else {
                        overview(summary, previous: previous)
                        categoryBreakdown(summary)
                        timeline(summary)
                        weekdayChart(summary)
                        hourChart(summary)
                        comparison(summary, previous: previous)
                        merchants(summary)
                        largest(summary)
                    }
                    trend
                    recurringSection
                }
                .padding(.horizontal, Theme.padding)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationTitle("Análisis")
            .navigationDestination(for: String.self) { CategoryDetailView(categoryId: $0, period: period) }
            .navigationDestination(for: Movement.self) { TransactionDetailView(movement: $0) }
        }
    }

    // MARK: Resumen

    private func overview(_ summary: PeriodSummary, previous: PeriodSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gastos").font(.subheadline).foregroundStyle(.secondary)
                    Text(MoneyFormat.clp(summary.spending))
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText(value: Double(summary.spending)))
                }
                Spacer()
                if previous.spending > 0 {
                    let change = Double(summary.spending - previous.spending) / Double(previous.spending)
                    ChangeBadge(change: change, lowerIsBetter: true)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 14) {
                stat("Ingresos", MoneyFormat.clp(summary.income), color: Theme.positive)
                stat("Flujo neto", MoneyFormat.clp(summary.net, signed: true), color: summary.net >= 0 ? Theme.positive : Theme.negative)
                stat("Tasa de ahorro", summary.savingsRate.map { MoneyFormat.percent($0) } ?? "–")
                stat("Promedio diario", MoneyFormat.clp(summary.averageDailySpending))
                stat("Necesidades", MoneyFormat.clp(summary.needs))
                stat("Deseos", MoneyFormat.clp(summary.wants))
                if summary.savingsTransfers != 0 {
                    stat("A ahorro / inversión", MoneyFormat.clp(summary.savingsTransfers))
                }
                if let projected = summary.projectedSpending {
                    stat("Proyección al cierre", MoneyFormat.clp(projected))
                }
                stat("Movimientos", "\(summary.transactionCount)")
                if summary.smallExpenses.count > 0 {
                    stat("Gastos hormiga", "\(summary.smallExpenses.count) · \(MoneyFormat.clp(summary.smallExpenses.total))")
                }
            }
        }
        .card(padding: 20)
    }

    private func stat(_ title: String, _ value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(Theme.amountFont(.subheadline)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    // MARK: Categorías

    private func categoryBreakdown(_ summary: PeriodSummary) -> some View {
        let totals = summary.byCategory.filter { $0.amount > 0 }
        let selectedCategory = category(atAngle: selectedAngle, in: totals)
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Por categoría")
            VStack(spacing: 16) {
                Chart(totals) { total in
                    SectorMark(angle: .value("Monto", total.amount), innerRadius: .ratio(0.62), angularInset: 1.5)
                        .cornerRadius(3)
                        .foregroundStyle(store.category(total.categoryId).color)
                        .opacity(selectedCategory == nil || selectedCategory == total.categoryId ? 1 : 0.35)
                }
                .chartLegend(.hidden)
                .chartAngleSelection(value: $selectedAngle)
                .frame(height: 210)
                .overlay {
                    VStack(spacing: 2) {
                        if let id = selectedCategory, let total = totals.first(where: { $0.categoryId == id }) {
                            Text(store.category(id).name).font(.caption).foregroundStyle(.secondary)
                            Text(MoneyFormat.clp(total.amount)).font(Theme.amountFont(.title3, weight: .bold))
                            Text(MoneyFormat.percent(total.share)).font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("\(totals.count) categorías").font(.caption).foregroundStyle(.secondary)
                            Text(MoneyFormat.compact(summary.spending)).font(Theme.amountFont(.title3, weight: .bold))
                        }
                    }
                }

                VStack(spacing: 14) {
                    ForEach(totals) { total in
                        NavigationLink(value: total.categoryId) {
                            CategoryProgressRow(category: store.category(total.categoryId), amount: total.amount, share: total.share)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .card()
        }
    }

    /// Traduce el ángulo tocado en el gráfico de dona a la categoría correspondiente.
    private func category(atAngle value: Int?, in totals: [CategoryTotal]) -> String? {
        guard let value else { return nil }
        var cumulative = 0
        for total in totals {
            cumulative += total.amount
            if value <= cumulative { return total.categoryId }
        }
        return nil
    }

    // MARK: Línea de tiempo

    private struct Bucket: Identifiable {
        let date: Date
        let spending: Pesos
        let income: Pesos
        var id: Date { date }
    }

    private func buckets(_ summary: PeriodSummary) -> (items: [Bucket], unit: Calendar.Component) {
        let days = summary.daily
        guard days.count > 62 else {
            return (days.map { Bucket(date: $0.date, spending: $0.spending, income: $0.income) }, .day)
        }
        let unit: PeriodKind = days.count > 120 ? .month : .week
        var grouped: [Date: (Pesos, Pesos)] = [:]
        for day in days {
            let key = store.calendar.period(unit, containing: day.date).start
            let current = grouped[key] ?? (0, 0)
            grouped[key] = (current.0 + day.spending, current.1 + day.income)
        }
        let items = grouped.keys.sorted().map { Bucket(date: $0, spending: grouped[$0]?.0 ?? 0, income: grouped[$0]?.1 ?? 0) }
        return (items, unit == .month ? .month : .weekOfYear)
    }

    private func timeline(_ summary: PeriodSummary) -> some View {
        let data = buckets(summary)
        let title = data.unit == .day ? "Gasto por día" : (data.unit == .month ? "Gasto por mes" : "Gasto por semana")
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: title, trailing: "Prom. \(MoneyFormat.clp(summary.averageDailySpending))/día")
            Chart(data.items) { bucket in
                BarMark(x: .value("Fecha", bucket.date, unit: data.unit), y: .value("Gasto", bucket.spending))
                    .foregroundStyle(Theme.ink.opacity(0.8))
                    .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel { if let amount = value.as(Int.self) { Text(MoneyFormat.compact(amount)) } }
                }
            }
            .frame(height: 180)
            .card()
        }
    }

    private func weekdayChart(_ summary: PeriodSummary) -> some View {
        let maxDay = summary.byWeekday.max { $0.averagePerDay < $1.averagePerDay }
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Por día de la semana")
            VStack(alignment: .leading, spacing: 12) {
                Chart(summary.byWeekday) { day in
                    BarMark(x: .value("Día", FinanceCalendar.weekdayShortNames[day.weekday]),
                            y: .value("Promedio", day.averagePerDay))
                        .foregroundStyle(day.weekday == maxDay?.weekday ? Theme.ink : Theme.ink.opacity(0.25))
                        .cornerRadius(4)
                }
                .chartYAxis(.hidden)
                .frame(height: 140)
                if let maxDay, maxDay.averagePerDay > 0 {
                    Text("Los \(FinanceCalendar.weekdayNames[maxDay.weekday]) gastas en promedio \(MoneyFormat.clp(maxDay.averagePerDay)).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .card()
        }
    }

    @ViewBuilder
    private func hourChart(_ summary: PeriodSummary) -> some View {
        SectionTitle(title: "Por hora del día")
        if summary.hourCoverage >= 0.3 {
            let peak = summary.byHour.max { $0.amount < $1.amount }
            VStack(alignment: .leading, spacing: 12) {
                Chart(summary.byHour) { hour in
                    BarMark(x: .value("Hora", hour.hour), y: .value("Gasto", hour.amount))
                        .foregroundStyle(hour.hour == peak?.hour ? Theme.ink : Theme.ink.opacity(0.25))
                        .cornerRadius(2)
                }
                .chartXScale(domain: 0...23)
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                        AxisValueLabel { if let hour = value.as(Int.self) { Text("\(hour)h") } }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 130)
                if let peak, peak.amount > 0 {
                    Text("Tu hora de mayor gasto es entre las \(peak.hour):00 y las \(peak.hour + 1):00.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if summary.hourCoverage < 0.95 {
                    Text("Basado en el \(MoneyFormat.percent(summary.hourCoverage)) de tus gastos: algunos bancos informan solo la fecha.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            .card()
        } else {
            Text("Tu banco informa la mayoría de los movimientos sin hora. Los gastos que registres a mano sí la incluyen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .card()
        }
    }

    // MARK: Comparación y detalle

    @ViewBuilder
    private func comparison(_ summary: PeriodSummary, previous: PeriodSummary) -> some View {
        let deltas = store.engine.compare(summary, with: previous).filter { $0.difference != 0 }.prefix(5)
        if !deltas.isEmpty && previous.transactionCount > 0 {
            SectionTitle(title: "Frente al período anterior", trailing: store.calendar.title(for: previous.period))
            VStack(spacing: 12) {
                ForEach(Array(deltas)) { delta in
                    let category = store.category(delta.categoryId)
                    HStack(spacing: 12) {
                        CategoryIcon(category: category, size: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(category.name).font(.subheadline.weight(.medium))
                            Text("\(MoneyFormat.clp(delta.previous)) → \(MoneyFormat.clp(delta.current))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(MoneyFormat.clp(delta.difference, signed: true))
                            .font(Theme.amountFont(.subheadline))
                            .foregroundStyle(delta.difference > 0 ? Theme.negative : Theme.positive)
                    }
                }
            }
            .card()
        }
    }

    @ViewBuilder
    private func merchants(_ summary: PeriodSummary) -> some View {
        if !summary.topMerchants.isEmpty {
            SectionTitle(title: "Dónde más gastas")
            VStack(spacing: 12) {
                let top = Array(summary.topMerchants.prefix(8))
                ForEach(top.indices, id: \.self) { index in
                    let merchant = top[index]
                    HStack(spacing: 12) {
                        Text("\(index + 1)").font(Theme.amountFont(.subheadline)).foregroundStyle(.secondary).frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(merchant.name).font(.subheadline.weight(.medium)).lineLimit(1)
                            Text("\(merchant.count) \(merchant.count == 1 ? "vez" : "veces") · \(store.category(merchant.categoryId).name)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(MoneyFormat.clp(merchant.amount)).font(Theme.amountFont(.subheadline))
                    }
                }
            }
            .card()
        }
    }

    @ViewBuilder
    private func largest(_ summary: PeriodSummary) -> some View {
        if !summary.largestExpenses.isEmpty {
            SectionTitle(title: "Gastos más grandes")
            VStack(spacing: 10) {
                ForEach(summary.largestExpenses) { movement in
                    NavigationLink(value: movement) {
                        MovementRow(movement: movement, category: store.category(movement.categoryId), showDate: true,
                                    calendar: store.calendar)
                    }
                    .buttonStyle(.plain)
                }
            }
            .card()
        }
    }

    // MARK: Tendencia y recurrentes

    private var trend: some View {
        let points = store.engine.monthlyTrend(store.analyzedTransactions, months: 6, endingAt: Date())
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Últimos 6 meses")
            VStack(alignment: .leading, spacing: 12) {
                Chart {
                    ForEach(points) { point in
                        BarMark(x: .value("Mes", store.calendar.monthShortName(point.month.start)),
                                y: .value("Monto", point.income), width: .ratio(0.35))
                            .foregroundStyle(by: .value("Tipo", "Ingresos"))
                            .position(by: .value("Tipo", "Ingresos"))
                            .cornerRadius(3)
                        BarMark(x: .value("Mes", store.calendar.monthShortName(point.month.start)),
                                y: .value("Monto", point.spending), width: .ratio(0.35))
                            .foregroundStyle(by: .value("Tipo", "Gastos"))
                            .position(by: .value("Tipo", "Gastos"))
                            .cornerRadius(3)
                    }
                }
                .chartForegroundStyleScale(["Ingresos": Theme.positive, "Gastos": Theme.ink.opacity(0.75)])
                .chartLegend(position: .top, alignment: .leading)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel { if let amount = value.as(Int.self) { Text(MoneyFormat.compact(amount)) } }
                    }
                }
                .frame(height: 200)
                let withIncome = points.filter { $0.income > 0 }
                if !withIncome.isEmpty {
                    let average = withIncome.reduce(0) { $0 + $1.net } / withIncome.count
                    Text(average >= 0
                         ? "En promedio te quedan \(MoneyFormat.clp(average)) al mes."
                         : "En promedio gastas \(MoneyFormat.clp(-average)) más de lo que ingresa al mes.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .card()
        }
    }

    @ViewBuilder
    private var recurringSection: some View {
        let active = store.recurring.filter(\.isActive)
        if !active.isEmpty {
            SectionTitle(title: "Gastos recurrentes", trailing: "\(MoneyFormat.clp(active.reduce(0) { $0 + $1.monthlyCost }))/mes")
            VStack(spacing: 12) {
                ForEach(active) { charge in
                    HStack(spacing: 12) {
                        CategoryIcon(category: store.category(charge.categoryId), size: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(charge.merchant).font(.subheadline.weight(.medium)).lineLimit(1)
                            Text("\(charge.cadence.title) · próximo \(store.calendar.shortDate(charge.nextDate))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(MoneyFormat.clp(charge.typicalAmount)).font(Theme.amountFont(.subheadline))
                            Text("\(MoneyFormat.clp(charge.yearlyCost))/año").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .card()
        }
    }
}

struct ChangeBadge: View {
    let change: Double
    var lowerIsBetter = true

    var body: some View {
        let isGood = lowerIsBetter ? change <= 0 : change >= 0
        Label(MoneyFormat.change(change), systemImage: change >= 0 ? "arrow.up.right" : "arrow.down.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(isGood ? Theme.positive : Theme.negative)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isGood ? Theme.positive : Theme.negative).opacity(0.12), in: Capsule())
            .accessibilityLabel("\(MoneyFormat.change(change)) frente al período anterior")
    }
}
