import SwiftUI
import CuadraCore

struct AdvisorView: View {
    @Environment(FinanceStore.self) private var store
    @State private var showingPlan = false
    @State private var editingGoal: SavingsGoal?
    @State private var showingScoreDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let score = store.healthScore {
                        scoreCard(score)
                    }
                    if let split = store.advisor.split(store.advisorInput) {
                        splitCard(split, rule: store.profile.splitRule)
                    }
                    insightsSection
                    budgetsSection
                    goalsSection
                    Text("Las recomendaciones son educativas y se basan solo en tus movimientos. No reemplazan la asesoría de un profesional financiero acreditado.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, Theme.padding)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationTitle("Asesor")
            .sheet(isPresented: $showingPlan) { PlanSheet() }
            .sheet(item: $editingGoal) { GoalEditor(goal: $0) }
            .navigationDestination(for: String.self) { id in
                CategoryDetailView(categoryId: id, period: store.calendar.period(.month, containing: Date()))
            }
            .navigationDestination(for: Movement.self) { TransactionDetailView(movement: $0) }
        }
    }

    // MARK: Puntaje

    private func scoreCard(_ score: HealthScore) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) {
                ScoreRing(score: score.score, size: 96)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Salud financiera").font(.subheadline).foregroundStyle(.secondary)
                    Text(score.label).font(.title2.weight(.bold))
                    if let income = store.estimatedIncome {
                        Text("Ingreso \(store.profile.declaredMonthlyIncome == nil ? "estimado" : "declarado"): \(MoneyFormat.clp(income))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Button {
                withAnimation(.snappy) { showingScoreDetail.toggle() }
            } label: {
                HStack {
                    Text(showingScoreDetail ? "Ocultar detalle" : "Ver cómo se calcula")
                    Image(systemName: "chevron.down").rotationEffect(.degrees(showingScoreDetail ? 180 : 0))
                }
                .font(.subheadline.weight(.medium))
            }
            if showingScoreDetail {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(score.components) { component in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(component.name).font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(component.points)/\(component.maxPoints)").font(Theme.amountFont(.subheadline))
                            }
                            ProgressBar(value: Double(component.points) / Double(max(1, component.maxPoints)))
                            Text(component.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .card(padding: 20)
    }

    // MARK: Distribución

    private func splitCard(_ split: SplitBreakdown, rule: SplitRule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Tu distribución", trailing: "Meta \(rule.name)")
            VStack(alignment: .leading, spacing: 16) {
                splitRow("Necesidades", actual: split.needsShare, target: rule.needs, amount: split.needs, higherIsBetter: false)
                splitRow("Deseos", actual: split.wantsShare, target: rule.wants, amount: split.wants, higherIsBetter: false)
                splitRow("Ahorro", actual: split.savingsShare, target: rule.savings, amount: split.savings, higherIsBetter: true)
                Text("Último mes completo, sobre ingresos de \(MoneyFormat.clp(split.income)).")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .card()
        }
    }

    private func splitRow(_ title: String, actual: Double, target: Double, amount: Pesos, higherIsBetter: Bool) -> some View {
        let onTrack = higherIsBetter ? actual >= target - 0.02 : actual <= target + 0.02
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text(MoneyFormat.clp(amount)).font(Theme.amountFont(.footnote)).foregroundStyle(.secondary)
                Text(MoneyFormat.percent(actual))
                    .font(Theme.amountFont(.subheadline))
                    .foregroundStyle(onTrack ? Theme.positive : Theme.warning)
                    .frame(minWidth: 48, alignment: .trailing)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule().fill(onTrack ? Theme.positive : Theme.warning)
                        .frame(width: proxy.size.width * min(max(actual, 0), 1))
                    Rectangle().fill(Color.primary)
                        .frame(width: 2, height: 12)
                        .offset(x: proxy.size.width * min(max(target, 0), 1) - 1)
                }
            }
            .frame(height: 8)
            .accessibilityElement()
            .accessibilityLabel("\(title): \(MoneyFormat.percent(actual)), meta \(MoneyFormat.percent(target))")
        }
    }

    // MARK: Conclusiones

    @ViewBuilder
    private var insightsSection: some View {
        SectionTitle(title: "Conclusiones", trailing: store.insights.isEmpty ? nil : "\(store.insights.count)")
        if store.insights.isEmpty {
            EmptyStateView(symbol: "sparkle", title: "Sin conclusiones todavía",
                           message: "Con un mes de movimientos podré darte recomendaciones personalizadas.")
                .card()
        } else {
            ForEach(store.insights) { insight in
                if let categoryId = insight.categoryId {
                    NavigationLink(value: categoryId) { InsightCard(insight: insight) }
                        .buttonStyle(.plain)
                } else {
                    InsightCard(insight: insight)
                }
            }
        }
    }

    // MARK: Presupuestos

    @ViewBuilder
    private var budgetsSection: some View {
        SectionTitle(title: "Presupuestos del mes")
        VStack(alignment: .leading, spacing: 14) {
            if store.budgetStatuses.isEmpty {
                Text("Aún no tienes presupuestos. Te propongo uno según tu historial y tu regla \(store.profile.splitRule.name).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.budgetStatuses) { status in
                    NavigationLink(value: status.budget.categoryId) {
                        BudgetRow(status: status, category: store.category(status.budget.categoryId))
                    }
                    .buttonStyle(.plain)
                }
            }
            if store.plan != nil {
                Button(store.budgetStatuses.isEmpty ? "Ver plan sugerido" : "Revisar plan sugerido") { showingPlan = true }
                    .buttonStyle(.primary)
                    .padding(.top, 4)
            }
        }
        .card()
    }

    // MARK: Metas

    @ViewBuilder
    private var goalsSection: some View {
        HStack {
            SectionTitle(title: "Metas de ahorro")
            Button {
                editingGoal = SavingsGoal(name: "", target: 0)
            } label: {
                Image(systemName: "plus.circle.fill").font(.title3)
            }
            .padding(.top, 8)
            .accessibilityLabel("Nueva meta")
        }
        if store.goals.isEmpty {
            Text("Define una meta (viaje, pie para la casa, fondo de emergencia) y te diré cuánto apartar cada mes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .card()
        } else {
            VStack(spacing: 16) {
                ForEach(store.goals) { goal in
                    Button { editingGoal = goal } label: { GoalRow(goal: goal) }
                        .buttonStyle(.plain)
                }
            }
            .card()
        }
    }
}

struct BudgetRow: View {
    let status: BudgetStatus
    let category: FinanceCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                CategoryIcon(category: category, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.name).font(.subheadline.weight(.medium))
                    Text(status.remaining >= 0 ? "Quedan \(MoneyFormat.clp(status.remaining))" : "Excedido en \(MoneyFormat.clp(-status.remaining))")
                        .font(.caption)
                        .foregroundStyle(status.remaining >= 0 ? Color.secondary : Theme.negative)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(MoneyFormat.clp(status.spent)).font(Theme.amountFont(.subheadline))
                    Text("de \(MoneyFormat.clp(status.budget.monthlyLimit))").font(.caption2).foregroundStyle(.secondary)
                }
            }
            ProgressBar(value: status.progress,
                        tint: status.progress >= 1 ? Theme.negative : (status.progress >= 0.8 ? Theme.warning : category.color))
            if status.projected > status.budget.monthlyLimit && status.progress < 1 {
                Text("A este ritmo cerrarás en \(MoneyFormat.clp(status.projected))")
                    .font(.caption2).foregroundStyle(Theme.warning)
            }
        }
        .contentShape(Rectangle())
    }
}

struct GoalRow: View {
    @Environment(FinanceStore.self) private var store
    let goal: SavingsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name.isEmpty ? "Meta" : goal.name).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(MoneyFormat.clp(goal.saved)) de \(MoneyFormat.clp(goal.target))").font(Theme.amountFont(.footnote))
            }
            ProgressBar(value: goal.progress, tint: Theme.positive)
            if let monthly = goal.monthlyContributionNeeded(now: Date(), calendar: store.calendar.calendar), let deadline = goal.deadline {
                Text("Aparta \(MoneyFormat.clp(monthly)) al mes para lograrlo antes del \(store.calendar.mediumDate(deadline)).")
                    .font(.caption).foregroundStyle(.secondary)
            } else if goal.progress >= 1 {
                Text("¡Meta cumplida!").font(.caption.weight(.semibold)).foregroundStyle(Theme.positive)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Plan sugerido

struct PlanSheet: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let plan = store.plan {
                    List {
                        Section {
                            LabeledContent("Ingreso mensual", value: MoneyFormat.clp(plan.income))
                            LabeledContent("Necesidades (\(MoneyFormat.percent(plan.rule.needs)))", value: MoneyFormat.clp(plan.needsTarget))
                            LabeledContent("Deseos (\(MoneyFormat.percent(plan.rule.wants)))", value: MoneyFormat.clp(plan.wantsTarget))
                            LabeledContent("Ahorro (\(MoneyFormat.percent(plan.rule.savings)))", value: MoneyFormat.clp(plan.savingsTarget))
                        } header: {
                            Text("Regla \(plan.rule.name)")
                        } footer: {
                            Text("Con este plan te quedarían cerca de \(MoneyFormat.clp(plan.projectedSavings)) al mes para ahorrar. Los gastos fijos (arriendo, cuentas, créditos) se mantienen; se ajustan los variables.")
                        }
                        ForEach([CategoryGroup.needs, .wants], id: \.self) { group in
                            let lines = plan.lines.filter { $0.group == group }
                            if !lines.isEmpty {
                                Section(group.title) {
                                    ForEach(lines) { line in
                                        let category = store.category(line.categoryId)
                                        HStack(spacing: 12) {
                                            CategoryIcon(category: category, size: 28)
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(category.name).font(.subheadline)
                                                Text("Promedio \(MoneyFormat.clp(line.average))").font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(MoneyFormat.clp(line.suggested))
                                                .font(Theme.amountFont(.subheadline))
                                                .foregroundStyle(line.suggested < line.average ? Theme.warning : Color.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button("Aplicar como presupuestos") {
                            store.apply(plan)
                            Haptics.success()
                            dismiss()
                        }
                        .buttonStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(.bar)
                    }
                } else {
                    EmptyStateView(symbol: "list.bullet.clipboard", title: "Faltan datos",
                                   message: "Necesito conocer tu ingreso: decláralo en tu perfil o espera a tener un mes de movimientos.")
                }
            }
            .navigationTitle("Plan sugerido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
        }
    }
}

// MARK: - Editor de metas

struct GoalEditor: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var goal: SavingsGoal
    @State private var target: Pesos?
    @State private var saved: Pesos?
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    private let isNew: Bool

    init(goal: SavingsGoal) {
        _goal = State(initialValue: goal)
        _target = State(initialValue: goal.target > 0 ? goal.target : nil)
        _saved = State(initialValue: goal.saved > 0 ? goal.saved : nil)
        _hasDeadline = State(initialValue: goal.deadline != nil)
        _deadline = State(initialValue: goal.deadline ?? Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date())
        isNew = goal.target == 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre (ej. Vacaciones)", text: $goal.name)
                    PesosField(title: "Monto objetivo", value: $target)
                    PesosField(title: "Ya tengo ahorrado", value: $saved)
                }
                Section {
                    Toggle("Fecha límite", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Lograrla antes del", selection: $deadline, in: Date()..., displayedComponents: .date)
                    }
                }
                if !isNew {
                    Section {
                        Button("Eliminar meta", role: .destructive) {
                            store.deleteGoal(goal)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "Nueva meta" : "Editar meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        goal.target = target ?? 0
                        goal.saved = saved ?? 0
                        goal.deadline = hasDeadline ? deadline : nil
                        goal.name = goal.name.trimmingCharacters(in: .whitespaces)
                        store.save(goal)
                        Haptics.success()
                        dismiss()
                    }
                    .disabled((target ?? 0) <= 0 || goal.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
