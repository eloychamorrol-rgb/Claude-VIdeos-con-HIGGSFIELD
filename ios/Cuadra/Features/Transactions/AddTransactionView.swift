import SwiftUI
import CuadraCore

/// Registrar o editar un movimiento manual (por ejemplo, gastos en efectivo).
struct AddTransactionView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var editing: Movement?

    @State private var isExpense = true
    @State private var amount: Pesos?
    @State private var merchant = ""
    @State private var categoryId = CategoryID.otherExpense
    @State private var accountId = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var categoryTouched = false
    @State private var loaded = false

    private static let cashAccountId = "manual-cash"

    private var groups: [CategoryGroup] { isExpense ? [.needs, .wants, .savings] : [.income] }

    private var canSave: Bool {
        (amount ?? 0) > 0 && !merchant.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo", selection: $isExpense) {
                        Text("Gasto").tag(true)
                        Text("Ingreso").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    PesosField(title: "$0", value: $amount, font: Theme.amountFont(.largeTitle, weight: .bold))
                    TextField(isExpense ? "¿Dónde o en qué?" : "¿De dónde?", text: $merchant)
                        .textInputAutocapitalization(.sentences)
                        .onChange(of: merchant) { _, text in suggestCategory(for: text) }
                }

                Section {
                    Picker("Categoría", selection: Binding(get: { categoryId }, set: { categoryId = $0; categoryTouched = true })) {
                        ForEach(groups, id: \.self) { group in
                            Section(group.title) {
                                ForEach(store.categories(in: group)) { category in
                                    Label(category.name, systemImage: category.symbol).tag(category.id)
                                }
                            }
                        }
                    }
                    Picker("Cuenta", selection: $accountId) {
                        Text("Efectivo").tag(Self.cashAccountId)
                        ForEach(store.accounts.filter { $0.id != Self.cashAccountId }) { account in
                            Text("\(store.institution(for: account).name) · \(account.name)").tag(account.id)
                        }
                    }
                    DatePicker("Fecha", selection: $date, in: ...Date())
                }

                Section("Nota") {
                    TextField("Opcional", text: $note, axis: .vertical)
                }
            }
            .navigationTitle(editing == nil ? "Nuevo movimiento" : "Editar movimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: save).disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onChange(of: isExpense) { _, expense in
                let group = store.category(categoryId).group
                if expense && group == .income { categoryId = CategoryID.otherExpense }
                if !expense && group != .income { categoryId = CategoryID.otherIncome }
                categoryTouched = false
                suggestCategory(for: merchant)
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        accountId = store.accounts.first(where: { $0.source == .manual && $0.kind == .cash })?.id ?? Self.cashAccountId
        guard let editing else { return }
        isExpense = editing.amount < 0
        amount = abs(editing.amount)
        merchant = editing.merchant
        categoryId = editing.categoryId
        categoryTouched = true
        accountId = editing.accountId
        date = editing.date
        note = editing.note ?? ""
    }

    /// Mientras se escribe, sugiere la categoría con las mismas reglas que los movimientos del banco.
    private func suggestCategory(for text: String) {
        guard !categoryTouched, !text.isEmpty else { return }
        let categorizer = Categorizer(userRules: store.rules, categories: store.categories)
        let result = categorizer.categorize(description: text, amount: isExpense ? -1 : 1)
        let group = store.category(result.categoryId).group
        if groups.contains(group) { categoryId = result.categoryId }
    }

    private func save() {
        guard let amount, amount > 0 else { return }
        if accountId == Self.cashAccountId, store.account(Self.cashAccountId) == nil {
            store.addCashAccount(id: Self.cashAccountId)
        }
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let movement = Movement(
            id: editing?.id ?? "manual-" + UUID().uuidString,
            accountId: accountId,
            amount: isExpense ? -amount : amount,
            date: date,
            hasTime: true,
            rawDescription: editing?.rawDescription ?? trimmedMerchant,
            merchant: trimmedMerchant,
            categoryId: categoryId,
            categorySource: .user,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            source: editing?.source ?? .manual
        )
        if editing == nil { store.add(movement) } else { store.update(movement) }
        Haptics.success()
        dismiss()
    }
}
