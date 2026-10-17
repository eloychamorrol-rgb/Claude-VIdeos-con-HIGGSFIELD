import SwiftUI
import Charts
import CuadraCore

/// Detalle de una categoría: evolución diaria/semanal/mensual, comercios, presupuesto y movimientos.
struct CategoryDetailView: View {
    @Environment(FinanceStore.self) private var store
    let categoryId: String
    @State var period: Period
    @State private var bucket = PeriodKind.day
    @State private var showingBudget = false
    @State private var budgetDraft: Pesos?

    init(categoryId: String, period: Period) {
        self.categoryId = categoryId
        _period = State(initialValue: period)
    }

    private var category: FinanceCategory { store.category(categoryId) }

    var body: some View {
        let movements = store.engine.transactions(store.analyzedTransactions, in: period).filter { $0.categoryId == categoryId }
        let isIncome = category.group == .income
        let total = movements.reduce(0) { $0 + (isIncome ? $1.amount : -$1.amount) }
        let previousPeriod = store.calendar.previous(period)
        let previousTotal = store.engine.transactions(store.analyzedTransactions, in: previousPeriod)
            .filter { $0.categoryId == categoryId }
            .reduce(0) { $0 + (isIncome ? $1.amount : -$1.amount) }
        let series = store.engine.categorySeries(store.analyzedTransactions, categoryId: categoryId, in: period, bucket: bucket)
            .map { SeriesPoint(date: $0.0.start, amount: isIncome ? -$0.1 : $0.1) }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button { period = store.calendar.previous(period) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(store.calendar.title(for: period)).font(.headline)
                    Spacer()
                    Button { period = store.calendar.next(period) } label: { Image(systemName: "chevron.right") }
                        .disabled(period.end > Date())
                }
                .padding(.horizontal, 8)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        CategoryIcon(category: category, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.group.title).font(.caption).foregroundStyle(.secondary)
                            Text(MoneyFormat.clp(total)).font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                        }
                        Spacer()
                        if previousTotal > 0 {
                            ChangeBadge(change: Double(total - previousTotal) / Double(previousTotal), lowerIsBetter: !isIncome)
                        }
                    }
                    HStack(spacing: 20) {
                        info("Movimientos", "\(movements.count)")
                        info("Ticket promedio", movements.isEmpty ? "–" : MoneyFormat.clp(total / movements.count))
                        info("Período anterior", MoneyFormat.clp(previousTotal))
                    }
                }
                .card(padding: 20)

                VStack(alignment: .leading, spacing: 12) {
                    Picker("Agrupar", selection: $bucket) {
                        Text("Diario").tag(PeriodKind.day)
                        Text("Semanal").tag(PeriodKind.week)
                        Text("Mensual").tag(PeriodKind.month)
                    }
                    .pickerStyle(.segmented)
                    Chart(series) { point in
                        BarMark(x: .value("Fecha", point.date, unit: unit), y: .value("Monto", point.amount))
                            .foregroundStyle(category.color)
                            .cornerRadius(3)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel { if let amount = value.as(Int.self) { Text(MoneyFormat.compact(amount)) } }
                        }
                    }
                    .frame(height: 180)
                    let nonZero = series.filter { $0.amount > 0 }
                    if !nonZero.isEmpty {
                        Text("Promedio \(bucketName): \(MoneyFormat.clp(series.reduce(0) { $0 + $1.amount } / max(1, series.count)))")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .card()

                if category.group.isSpending {
                    budgetCard(spent: total)
                }

                let merchants = Dictionary(grouping: movements, by: \.merchantKey)
                    .map { MerchantLine(id: $0.key, name: $0.value.first?.merchant ?? "",
                                        total: $0.value.reduce(0) { $0 + (isIncome ? $1.amount : -$1.amount) }, count: $0.value.count) }
                    .sorted { $0.total > $1.total }
                if merchants.count > 1 {
                    SectionTitle(title: "Comercios")
                    VStack(spacing: 10) {
                        ForEach(merchants.prefix(8)) { merchant in
                            HStack {
                                Text(merchant.name).font(.subheadline.weight(.medium)).lineLimit(1)
                                Text("×\(merchant.count)").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text(MoneyFormat.clp(merchant.total)).font(Theme.amountFont(.subheadline))
                            }
                        }
                    }
                    .card()
                }

                SectionTitle(title: "Movimientos")
                if movements.isEmpty {
                    EmptyStateView(symbol: "tray", title: "Sin movimientos", message: "No hay movimientos en este período.").card()
                } else {
                    VStack(spacing: 10) {
                        ForEach(movements.sorted { $0.date > $1.date }) { movement in
                            NavigationLink(value: movement) {
                                MovementRow(movement: movement, category: category, showDate: true, calendar: store.calendar)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .card()
                }
            }
            .padding(.horizontal, Theme.padding)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if period.kind == .year || period.kind == .quarter { bucket = .month }
        }
        .sheet(isPresented: $showingBudget) { budgetSheet }
    }

    private struct MerchantLine: Identifiable {
        let id: String
        let name: String
        let total: Pesos
        let count: Int
    }

    private struct SeriesPoint: Identifiable {
        let date: Date
        let amount: Pesos
        var id: Date { date }
    }

    private var unit: Calendar.Component {
        switch bucket {
        case .week: return .weekOfYear
        case .month: return .month
        default: return .day
        }
    }

    private var bucketName: String {
        switch bucket {
        case .week: return "semanal"
        case .month: return "mensual"
        default: return "diario"
        }
    }

    private func info(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(Theme.amountFont(.subheadline))
        }
    }

    private func budgetCard(spent: Pesos) -> some View {
        let budget = store.budgets.first { $0.categoryId == categoryId }
        let monthSpent = store.summary(for: store.calendar.period(.month, containing: Date()))
            .byCategory.first { $0.categoryId == categoryId }?.amount ?? 0
        return Button {
            budgetDraft = budget?.monthlyLimit
            showingBudget = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Presupuesto mensual").font(.subheadline.weight(.medium))
                    Spacer()
                    Text(budget.map { MoneyFormat.clp($0.monthlyLimit) } ?? "Definir")
                        .font(Theme.amountFont(.subheadline))
                        .foregroundStyle(budget == nil ? Color.secondary : Color.primary)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                }
                if let budget {
                    let progress = Double(monthSpent) / Double(max(1, budget.monthlyLimit))
                    ProgressBar(value: progress, tint: progress >= 1 ? Theme.negative : (progress >= 0.8 ? Theme.warning : category.color))
                    Text("Este mes: \(MoneyFormat.clp(monthSpent)) · quedan \(MoneyFormat.clp(max(0, budget.monthlyLimit - monthSpent)))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(Color.primary)
            .card()
        }
        .buttonStyle(.plain)
    }

    private var budgetSheet: some View {
        NavigationStack {
            Form {
                Section {
                    PesosField(title: "Monto mensual", value: $budgetDraft)
                } footer: {
                    if let line = store.plan?.lines.first(where: { $0.categoryId == categoryId }) {
                        Text("Promedio de los últimos meses: \(MoneyFormat.clp(line.average)). Sugerido: \(MoneyFormat.clp(line.suggested)).")
                    }
                }
                if store.budgets.contains(where: { $0.categoryId == categoryId }) {
                    Button("Quitar presupuesto", role: .destructive) {
                        store.setBudget(nil, for: categoryId)
                        showingBudget = false
                    }
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showingBudget = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        store.setBudget(budgetDraft, for: categoryId)
                        Haptics.success()
                        showingBudget = false
                    }
                    .disabled((budgetDraft ?? 0) <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
