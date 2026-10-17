import SwiftUI
import CuadraCore

struct TransactionsView: View {
    @Environment(FinanceStore.self) private var store
    @State private var search = ""
    @State private var flow = Flow.all
    @State private var categoryFilter: String?
    @State private var accountFilter: String?
    @State private var showingAdd = false
    @State private var visibleDays = 60

    enum Flow: String, CaseIterable, Identifiable {
        case all = "Todos", expenses = "Gastos", income = "Ingresos"
        var id: String { rawValue }
    }

    private var filtered: [Movement] {
        let query = TextNormalizer.normalize(search)
        return store.transactions.filter { movement in
            let group = store.category(movement.categoryId).group
            switch flow {
            case .all: break
            case .expenses: if !(group.isSpending || group == .savings) { return false }
            case .income: if group != .income { return false }
            }
            if let categoryFilter, movement.categoryId != categoryFilter { return false }
            if let accountFilter, movement.accountId != accountFilter { return false }
            if !query.isEmpty {
                let haystack = TextNormalizer.normalize("\(movement.merchant) \(movement.rawDescription) \(movement.note ?? "") \(store.category(movement.categoryId).name)")
                if !haystack.contains(query) { return false }
            }
            return true
        }
    }

    struct DaySection: Identifiable {
        let day: Date
        let items: [Movement]
        var id: Date { day }
    }

    private var sections: [DaySection] {
        let grouped = Dictionary(grouping: filtered) { store.calendar.startOfDay($0.date) }
        return grouped.keys.sorted(by: >).map { DaySection(day: $0, items: grouped[$0] ?? []) }
    }

    var body: some View {
        let sections = self.sections
        let total = sections.reduce(0) { $0 + $1.items.count }
        NavigationStack {
            List {
                Section {
                    Picker("Tipo", selection: $flow) {
                        ForEach(Flow.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if sections.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass", title: "Sin resultados",
                                   message: store.transactions.isEmpty ? "Todavía no tienes movimientos." : "Prueba con otra búsqueda o filtro.")
                        .listRowBackground(Color.clear)
                }

                ForEach(sections.prefix(visibleDays)) { section in
                    Section {
                        ForEach(section.items) { movement in
                            NavigationLink(value: movement) {
                                MovementRow(movement: movement, category: store.category(movement.categoryId), calendar: store.calendar)
                            }
                            .swipeActions(edge: .trailing) {
                                if movement.source == .manual || movement.source == .demo {
                                    Button(role: .destructive) { store.delete([movement.id]) } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    } header: {
                        let net = section.items.reduce(0) { result, movement in
                            store.category(movement.categoryId).group == .transfer ? result : result + movement.amount
                        }
                        HStack {
                            Text(store.calendar.longDayTitle(section.day))
                            Spacer()
                            Text(MoneyFormat.clp(net, signed: true)).monospacedDigit()
                        }
                        .font(.footnote.weight(.medium))
                        .textCase(nil)
                    }
                }

                if sections.count > visibleDays {
                    Button("Cargar más") { visibleDays += 60 }
                        .frame(maxWidth: .infinity)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Movimientos")
            .searchable(text: $search, prompt: "Buscar comercio, categoría o nota")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { filterMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Agregar movimiento")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if categoryFilter != nil || accountFilter != nil {
                    Button {
                        categoryFilter = nil
                        accountFilter = nil
                    } label: {
                        Label("\(total) movimientos · Quitar filtros", systemImage: "xmark.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.regularMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 8)
                }
            }
            .navigationDestination(for: Movement.self) { TransactionDetailView(movement: $0) }
            .sheet(isPresented: $showingAdd) { AddTransactionView() }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Categoría", selection: $categoryFilter) {
                Text("Todas las categorías").tag(String?.none)
                ForEach(CategoryGroup.allCases, id: \.self) { group in
                    Section(group.title) {
                        ForEach(store.categories(in: group)) { category in
                            Label(category.name, systemImage: category.symbol).tag(Optional(category.id))
                        }
                    }
                }
            }
            .pickerStyle(.menu)
            if !store.accounts.isEmpty {
                Picker("Cuenta", selection: $accountFilter) {
                    Text("Todas las cuentas").tag(String?.none)
                    ForEach(store.accounts) { account in
                        Text(account.name).tag(Optional(account.id))
                    }
                }
                .pickerStyle(.menu)
            }
        } label: {
            Image(systemName: categoryFilter == nil && accountFilter == nil
                  ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
        .accessibilityLabel("Filtros")
    }
}

// MARK: - Detalle

struct TransactionDetailView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let movement: Movement
    @State private var note = ""
    @State private var showingCategories = false
    @State private var showingEdit = false

    /// Versión actual (puede cambiar mientras la vista está abierta).
    private var current: Movement { store.transactions.first { $0.id == movement.id } ?? movement }

    var body: some View {
        let movement = current
        let category = store.category(movement.categoryId)
        let sameMerchant = store.transactions.filter { $0.merchantKey == movement.merchantKey && $0.id != movement.id }
        List {
            Section {
                VStack(spacing: 10) {
                    CategoryIcon(category: category, size: 56)
                    Text(movement.merchant).font(.title3.weight(.semibold)).multilineTextAlignment(.center)
                    AmountText(amount: movement.amount, style: .largeTitle, weight: .bold)
                    Text(dateText(movement)).font(.subheadline).foregroundStyle(.secondary)
                    if movement.isPending {
                        Text("Pendiente de contabilizar")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Theme.track, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section {
                Button { showingCategories = true } label: {
                    HStack {
                        Text("Categoría").foregroundStyle(Color.primary)
                        Spacer()
                        Text(category.name).foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                }
                if let account = store.account(movement.accountId) {
                    LabeledContent("Cuenta", value: "\(store.institution(for: account).name) · \(account.name)")
                }
                LabeledContent("Descripción del banco") {
                    Text(movement.rawDescription).multilineTextAlignment(.trailing).textSelection(.enabled)
                }
                LabeledContent("Origen", value: sourceText(movement.source))
            }

            Section("Nota") {
                TextField("Agregar una nota", text: $note, axis: .vertical)
                    .onSubmit(saveNote)
            }

            if !sameMerchant.isEmpty {
                let total = sameMerchant.filter { $0.amount < 0 }.reduce(0) { $0 - $1.amount } - min(movement.amount, 0)
                Section {
                    LabeledContent("Veces", value: "\(sameMerchant.count + 1)")
                    LabeledContent("Total gastado", value: MoneyFormat.clp(total))
                    ForEach(sameMerchant.prefix(5)) { other in
                        HStack {
                            Text(store.calendar.mediumDate(other.date)).foregroundStyle(.secondary)
                            Spacer()
                            AmountText(amount: other.amount, style: .subheadline, weight: .regular)
                        }
                    }
                } header: {
                    Text("Historial en \(movement.merchant)")
                }
            }

            if movement.source == .manual {
                Section {
                    Button("Editar movimiento") { showingEdit = true }
                    Button("Eliminar movimiento", role: .destructive) {
                        store.delete([movement.id])
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { note = movement.note ?? "" }
        .onDisappear(perform: saveNote)
        .sheet(isPresented: $showingCategories) {
            CategoryPickerSheet(movement: movement)
        }
        .sheet(isPresented: $showingEdit) {
            AddTransactionView(editing: movement)
        }
    }

    private func saveNote() {
        var updated = current
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let newNote: String? = trimmed.isEmpty ? nil : trimmed
        guard newNote != updated.note else { return }
        updated.note = newNote
        store.update(updated)
    }

    private func dateText(_ movement: Movement) -> String {
        let day = store.calendar.longDayTitle(movement.date)
        let year = store.calendar.calendar.component(.year, from: movement.date)
        let withYear = year == store.calendar.calendar.component(.year, from: Date()) ? day : "\(day) \(year)"
        return movement.hasTime ? "\(withYear) · \(store.calendar.timeString(movement.date))" : withYear
    }

    private func sourceText(_ source: DataSource) -> String {
        switch source {
        case .bank: return "Sincronizado con el banco"
        case .csv: return "Importado de cartola"
        case .manual: return "Ingresado a mano"
        case .demo: return "Datos de ejemplo"
        }
    }
}

/// Selector de categoría con opción de aplicar a todo el comercio.
struct CategoryPickerSheet: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let movement: Movement
    @State private var applyToMerchant = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Aplicar a todos los de \(movement.merchant)", isOn: $applyToMerchant)
                } footer: {
                    Text("Se creará una regla y los próximos movimientos de este comercio usarán la misma categoría.")
                }
                ForEach(groups, id: \.self) { group in
                    Section(group.title) {
                        ForEach(store.categories(in: group)) { category in
                            Button {
                                Haptics.tap()
                                store.setCategory(category.id, for: movement, applyToMerchant: applyToMerchant)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    CategoryIcon(category: category, size: 30)
                                    Text(category.name).foregroundStyle(Color.primary)
                                    Spacer()
                                    if category.id == movement.categoryId {
                                        Image(systemName: "checkmark").fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
        }
    }

    private var groups: [CategoryGroup] {
        movement.amount > 0 ? [.income, .transfer, .needs, .wants, .savings] : [.needs, .wants, .savings, .transfer, .income]
    }
}
