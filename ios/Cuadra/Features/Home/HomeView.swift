import SwiftUI
import Charts
import CuadraCore

struct HomeView: View {
    @Environment(FinanceStore.self) private var store
    @Binding var selection: RootView.Tab
    @State private var showingAdd = false

    private var month: Period { store.calendar.period(.month, containing: Date()) }

    var body: some View {
        let summary = store.summary(for: month)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if store.transactions.isEmpty {
                        emptyState
                    } else {
                        hero(summary)
                        if !store.visibleAccounts.isEmpty { accounts }
                        if let score = store.healthScore { healthCard(score) }
                        insightsPreview
                        categoriesCard(summary)
                        upcomingCard
                        recentCard
                    }
                }
                .padding(.horizontal, Theme.padding)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationTitle(greeting)
            .toolbar {
                if !store.links.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            Task { await store.sync() }
                        } label: {
                            if store.isSyncing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(store.isSyncing)
                        .accessibilityLabel("Actualizar movimientos")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Agregar movimiento")
                }
            }
            .refreshable { if !store.links.isEmpty { await store.sync() } }
            .sheet(isPresented: $showingAdd) { AddTransactionView() }
            .navigationDestination(for: Movement.self) { TransactionDetailView(movement: $0) }
            .navigationDestination(for: String.self) { CategoryDetailView(categoryId: $0, period: month) }
        }
    }

    private var greeting: String {
        let hour = store.calendar.hour(Date())
        let base = hour < 12 ? "Buenos días" : (hour < 20 ? "Buenas tardes" : "Buenas noches")
        let name = store.profile.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? base : "\(base), \(name)"
    }

    // MARK: Secciones

    private var emptyState: some View {
        VStack(spacing: 16) {
            EmptyStateView(symbol: "tray", title: "Aún no hay movimientos",
                           message: "Conecta tu banco, importa una cartola o registra un gasto para empezar.")
            Button("Conectar o importar") { selection = .settings }
                .buttonStyle(.primary)
            Button("Agregar un gasto manual") { showingAdd = true }
                .font(.body.weight(.medium))
        }
        .card(padding: 20)
        .padding(.top, 12)
    }

    private func hero(_ summary: PeriodSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gastado en \(store.calendar.title(for: month).lowercased())")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(MoneyFormat.clp(summary.spending))
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(value: Double(summary.spending)))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            HStack(spacing: 20) {
                metric("Ingresos", MoneyFormat.clp(summary.income), color: Theme.positive)
                metric("Ahorro", MoneyFormat.clp(summary.savingsTransfers))
                if let projected = summary.projectedSpending {
                    metric("Proyección", MoneyFormat.clp(projected))
                }
            }

            Chart(summary.daily) { point in
                BarMark(x: .value("Día", point.date, unit: .day), y: .value("Gasto", point.spending))
                    .foregroundStyle(Calendar.current.isDateInToday(point.date) ? Theme.ink : Theme.ink.opacity(0.25))
                    .cornerRadius(2)
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text("\(store.calendar.calendar.component(.day, from: date))")
                        }
                    }
                }
            }
            .frame(height: 90)
            .accessibilityLabel("Gasto diario del mes")
        }
        .card(padding: 20)
        .padding(.top, 4)
    }

    private func metric(_ title: String, _ value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(Theme.amountFont(.subheadline)).foregroundStyle(color)
        }
    }

    private var accounts: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.visibleAccounts) { account in
                    let institution = store.institution(for: account)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle().fill(Color(hex: institution.colorHex)).frame(width: 8, height: 8)
                            Text(institution.name).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(account.name).font(.subheadline.weight(.medium)).lineLimit(1)
                        if let balance = account.availableBalance ?? account.balance {
                            Text(MoneyFormat.clp(balance)).font(Theme.amountFont(.headline))
                        } else {
                            Text("Sin saldo").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 160, alignment: .leading)
                    .card(padding: 14)
                }
            }
        }
        .scrollClipDisabled()
    }

    private func healthCard(_ score: HealthScore) -> some View {
        Button { selection = .advisor } label: {
            HStack(spacing: 16) {
                ScoreRing(score: score.score, size: 54)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Salud financiera").font(.subheadline).foregroundStyle(.secondary)
                    Text(score.label).font(.headline)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var insightsPreview: some View {
        let top = store.insights.filter { $0.kind != .positive }.prefix(2)
        if !top.isEmpty {
            SectionTitle(title: "Para tener en cuenta")
            ForEach(Array(top)) { insight in
                Button { selection = .advisor } label: { InsightCard(insight: insight, compact: true) }
                    .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func categoriesCard(_ summary: PeriodSummary) -> some View {
        if !summary.byCategory.isEmpty {
            SectionTitle(title: "En qué se va")
            VStack(spacing: 14) {
                ForEach(summary.byCategory.prefix(5)) { total in
                    let category = store.category(total.categoryId)
                    let budget = store.budgets.first { $0.categoryId == total.categoryId }
                    NavigationLink(value: total.categoryId) {
                        CategoryProgressRow(category: category, amount: total.amount, share: total.share, budget: budget)
                    }
                    .buttonStyle(.plain)
                }
            }
            .card()
        }
    }

    @ViewBuilder
    private var upcomingCard: some View {
        let upcoming = store.advisor.recurring.upcoming(store.recurring, now: Date(), days: 14)
        if !upcoming.isEmpty {
            SectionTitle(title: "Próximos cobros", trailing: MoneyFormat.clp(upcoming.reduce(0) { $0 + $1.typicalAmount }))
            VStack(spacing: 12) {
                ForEach(upcoming.prefix(5)) { charge in
                    HStack(spacing: 12) {
                        CategoryIcon(category: store.category(charge.categoryId), size: 32)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(charge.merchant).font(.subheadline.weight(.medium))
                            Text(store.calendar.longDayTitle(charge.nextDate)).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(MoneyFormat.clp(charge.typicalAmount)).font(Theme.amountFont(.subheadline))
                    }
                }
            }
            .card()
        }
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionTitle(title: "Recientes")
                Button("Ver todos") { selection = .movements }
                    .font(.subheadline)
                    .padding(.top, 8)
            }
            VStack(spacing: 10) {
                ForEach(store.transactions.prefix(5)) { movement in
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
}

/// Fila de categoría con barra (y presupuesto si existe).
struct CategoryProgressRow: View {
    let category: FinanceCategory
    let amount: Pesos
    let share: Double
    var budget: Budget?

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                CategoryIcon(category: category, size: 30)
                Text(category.name).font(.subheadline.weight(.medium))
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(MoneyFormat.clp(amount)).font(Theme.amountFont(.subheadline))
                    if let budget {
                        Text("de \(MoneyFormat.clp(budget.monthlyLimit))").font(.caption2).foregroundStyle(.secondary)
                    } else {
                        Text(MoneyFormat.percent(share)).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            if let budget {
                let progress = budget.monthlyLimit > 0 ? Double(amount) / Double(budget.monthlyLimit) : 0
                ProgressBar(value: progress, tint: progress >= 1 ? Theme.negative : (progress >= 0.8 ? Theme.warning : category.color))
            } else {
                ProgressBar(value: share, tint: category.color)
            }
        }
        .contentShape(Rectangle())
    }
}

struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 120

    private var color: Color {
        switch score {
        case 65...: return Theme.positive
        case 45..<65: return Theme.warning
        default: return Theme.negative
        }
    }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.track, lineWidth: size * 0.1)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: size * 0.32, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(value: Double(score)))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Puntaje \(score) de 100")
    }
}

struct InsightCard: View {
    let insight: Insight
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.color(for: insight.kind))
                .frame(width: 30, height: 30)
                .background(Theme.color(for: insight.kind).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title).font(.subheadline.weight(.semibold))
                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(compact ? 2 : nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .card()
    }
}
