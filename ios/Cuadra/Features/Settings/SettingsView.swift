import SwiftUI
import UniformTypeIdentifiers
import CuadraCore

struct SettingsView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(AppLock.self) private var lock
    @State private var notificationsOn = NotificationScheduler.isEnabled
    @State private var confirmingReset = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        HStack(spacing: 14) {
                            Text(initials)
                                .font(.headline)
                                .foregroundStyle(Theme.inkInverse)
                                .frame(width: 44, height: 44)
                                .background(Theme.ink, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.profile.name.isEmpty ? "Tu perfil" : store.profile.name).font(.headline)
                                Text("\(store.profile.goal.title) · \(store.profile.splitRule.name)")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Datos") {
                    NavigationLink { BankConnectionView() } label: {
                        Label("Conexión bancaria", systemImage: "building.columns")
                    }
                    NavigationLink { AccountsView() } label: {
                        Label("Cuentas", systemImage: "creditcard")
                    }
                    NavigationLink { ImportCSVView() } label: {
                        Label("Importar cartola (CSV)", systemImage: "square.and.arrow.down")
                    }
                    NavigationLink { CategoriesView() } label: {
                        Label("Categorías y reglas", systemImage: "tag")
                    }
                }

                Section("Preferencias") {
                    Toggle(isOn: Binding(get: { lock.isEnabled }, set: { lock.setEnabled($0) })) {
                        Label("Bloquear con \(lock.biometryName)", systemImage: "faceid")
                    }
                    Toggle(isOn: $notificationsOn) {
                        Label("Avisos de presupuesto y cobros", systemImage: "bell")
                    }
                    .onChange(of: notificationsOn) { _, enabled in
                        Task {
                            let granted = await NotificationScheduler.setEnabled(enabled)
                            if enabled && !granted {
                                notificationsOn = false
                                store.errorMessage = "Activa las notificaciones para Cuadra en Ajustes de iOS."
                            } else if granted {
                                store.refreshDerivedData()
                            }
                        }
                    }
                }

                Section {
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("Compartir archivo CSV", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            exportURL = store.exportCSV()
                        } label: {
                            Label("Exportar movimientos", systemImage: "tablecells")
                        }
                        .disabled(store.transactions.isEmpty)
                    }
                    if store.isDemo {
                        Button {
                            store.clearDemo()
                        } label: {
                            Label("Quitar datos de ejemplo", systemImage: "wand.and.stars.inverse")
                        }
                    } else if store.transactions.isEmpty {
                        Button {
                            let profile = store.profile
                            store.loadDemo()
                            store.saveProfile(profile)
                        } label: {
                            Label("Cargar datos de ejemplo", systemImage: "wand.and.stars")
                        }
                    }
                    Button(role: .destructive) {
                        confirmingReset = true
                    } label: {
                        Label("Borrar todos los datos", systemImage: "trash")
                    }
                } header: {
                    Text("Tus datos")
                } footer: {
                    Text("Tus movimientos se guardan solo en este iPhone, cifrados por iOS. Nada se envía a terceros salvo la consulta a tu banco a través de tu servidor.")
                }

                Section {
                    LabeledContent("Versión", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                } footer: {
                    Text("Cuadra entrega recomendaciones educativas basadas en tus datos; no constituye asesoría financiera regulada.")
                }
            }
            .navigationTitle("Ajustes")
            .confirmationDialog("¿Borrar todos los datos?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Borrar todo", role: .destructive) { store.resetAll() }
            } message: {
                Text("Se eliminarán movimientos, cuentas, presupuestos, metas y tu perfil de este iPhone. Esta acción no se puede deshacer.")
            }
            .onChange(of: store.transactions.count) { _, _ in exportURL = nil }
        }
    }

    private var initials: String {
        let parts = store.profile.name.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? "C" : letters.uppercased()
    }
}

// MARK: - Perfil

struct ProfileView: View {
    @Environment(FinanceStore.self) private var store
    @State private var profile = UserProfile()
    @State private var income: Pesos?
    @State private var threshold: Pesos?
    @State private var useCustomRule = false
    @State private var needs = 50.0
    @State private var wants = 30.0
    @State private var loaded = false

    var body: some View {
        Form {
            Section("Sobre ti") {
                TextField("Nombre", text: $profile.name)
                Picker("Vivienda", selection: $profile.housing) {
                    ForEach(HousingSituation.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                Stepper("Personas a tu cargo: \(profile.dependents)", value: $profile.dependents, in: 0...10)
            }

            Section {
                PesosField(title: "Ingreso mensual líquido", value: $income)
            } header: {
                Text("Ingreso")
            } footer: {
                if income == nil, let estimated = store.estimatedIncome {
                    Text("Estimado a partir de tus movimientos: \(MoneyFormat.clp(estimated)).")
                } else {
                    Text("Déjalo vacío para que se estime automáticamente.")
                }
            }

            Section("Objetivo") {
                Picker("Objetivo principal", selection: $profile.goal) {
                    ForEach(FinancialGoal.allCases, id: \.self) { Text($0.title).tag($0) }
                }
            }

            Section {
                Toggle("Distribución personalizada", isOn: $useCustomRule)
                if useCustomRule {
                    VStack(alignment: .leading) {
                        Text("Necesidades: \(Int(needs)) %")
                        Slider(value: $needs, in: 30...80, step: 5)
                    }
                    VStack(alignment: .leading) {
                        Text("Deseos: \(Int(wants)) %")
                        Slider(value: $wants, in: 0...max(0, 100 - needs), step: 5)
                    }
                    LabeledContent("Ahorro", value: "\(Int(max(0, 100 - needs - wants))) %")
                } else {
                    Picker("Regla", selection: $profile.splitRule) {
                        ForEach(SplitRule.presets, id: \.self) { Text($0.name).tag($0) }
                    }
                }
            } header: {
                Text("Distribución del ingreso")
            } footer: {
                Text("Necesidades: vivienda, cuentas, supermercado, transporte, salud, educación, créditos. Deseos: restaurantes, compras, entretención, suscripciones, viajes.")
            }

            Section {
                PesosField(title: "Monto", value: $threshold)
            } header: {
                Text("Gastos hormiga")
            } footer: {
                Text("Compras en deseos bajo este monto se cuentan como gastos hormiga.")
            }
        }
        .navigationTitle("Perfil")
        .onAppear(perform: load)
        .onChange(of: needs) { _, newNeeds in wants = min(wants, 100 - newNeeds) }
        .onDisappear(perform: save)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        profile = store.profile
        income = profile.declaredMonthlyIncome
        threshold = profile.smallExpenseThreshold
        useCustomRule = !SplitRule.presets.contains(profile.splitRule)
        needs = profile.splitRule.needs * 100
        wants = profile.splitRule.wants * 100
    }

    private func save() {
        var updated = profile
        updated.declaredMonthlyIncome = (income ?? 0) > 0 ? income : nil
        updated.smallExpenseThreshold = max(500, threshold ?? 5_000)
        if useCustomRule {
            let savings = max(0, 100 - needs - wants)
            updated.splitRule = SplitRule(name: "\(Int(needs))/\(Int(wants))/\(Int(savings))",
                                          needs: needs / 100, wants: wants / 100, savings: savings / 100)
        }
        if updated != store.profile { store.saveProfile(updated) }
    }
}

// MARK: - Cuentas

struct AccountsView: View {
    @Environment(FinanceStore.self) private var store
    @State private var showingAdd = false
    @State private var accountToDelete: Account?

    var body: some View {
        List {
            if store.accounts.isEmpty {
                EmptyStateView(symbol: "creditcard", title: "Sin cuentas",
                               message: "Conecta un banco, importa una cartola o crea una cuenta manual.")
                    .listRowBackground(Color.clear)
            }
            ForEach(store.accounts) { account in
                NavigationLink { AccountEditor(account: account) } label: {
                    HStack(spacing: 12) {
                        Circle().fill(Color(hex: store.institution(for: account).colorHex)).frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name).font(.body.weight(.medium))
                            Text("\(store.institution(for: account).name) · \(account.kind.title)\(account.numberMasked.isEmpty ? "" : " · \(account.numberMasked)")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if let balance = account.availableBalance ?? account.balance {
                                Text(MoneyFormat.clp(balance)).font(Theme.amountFont(.subheadline))
                            }
                            if account.isHidden {
                                Text("Oculta").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .swipeActions {
                    if account.source != .bank {
                        Button("Eliminar", role: .destructive) { accountToDelete = account }
                    }
                }
            }
        }
        .navigationTitle("Cuentas")
        .toolbar {
            Button { showingAdd = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("Nueva cuenta")
        }
        .sheet(isPresented: $showingAdd) { NewAccountSheet() }
        .confirmationDialog("¿Eliminar \(accountToDelete?.name ?? "la cuenta")?",
                            isPresented: Binding(get: { accountToDelete != nil }, set: { if !$0 { accountToDelete = nil } }),
                            titleVisibility: .visible) {
            if let account = accountToDelete {
                Button("Eliminar cuenta y sus movimientos", role: .destructive) { store.deleteAccount(account) }
            }
        }
    }
}

struct AccountEditor: View {
    @Environment(FinanceStore.self) private var store
    @State var account: Account
    @State private var balance: Pesos?

    var body: some View {
        Form {
            Section {
                TextField("Nombre", text: $account.name)
                Toggle("Ocultar del análisis", isOn: $account.isHidden)
            } footer: {
                Text("Las cuentas ocultas no se consideran en estadísticas ni recomendaciones (útil para cuentas de la empresa o de terceros).")
            }
            if account.source != .bank {
                Section("Saldo actual") {
                    PesosField(title: "Saldo", value: $balance)
                }
            } else if let synced = account.lastSyncedAt {
                Section {
                    LabeledContent("Última actualización", value: synced.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { balance = account.availableBalance ?? account.balance }
        .onDisappear {
            var updated = account
            if updated.source != .bank {
                updated.balance = balance
                updated.availableBalance = balance
            }
            if updated.name.trimmingCharacters(in: .whitespaces).isEmpty, let original = store.account(account.id) {
                updated.name = original.name
            }
            store.update(updated)
        }
    }
}

struct NewAccountSheet: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var onCreate: ((Account) -> Void)?
    @State private var name = ""
    @State private var kind = AccountKind.checking
    @State private var institutionId = "santander"
    @State private var balance: Pesos?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nombre (ej. Cuenta corriente)", text: $name)
                Picker("Institución", selection: $institutionId) {
                    ForEach(Institution.catalog) { Text($0.name).tag($0.id) }
                }
                Picker("Tipo", selection: $kind) {
                    ForEach(AccountKind.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                PesosField(title: "Saldo actual (opcional)", value: $balance)
            }
            .navigationTitle("Nueva cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        let account = store.addManualAccount(name: name.trimmingCharacters(in: .whitespaces), kind: kind,
                                                             institutionId: institutionId, balance: balance)
                        onCreate?(account)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Importar cartola

struct ImportCSVView: View {
    @Environment(FinanceStore.self) private var store
    @State private var accountId: String?
    @State private var showingImporter = false
    @State private var showingNewAccount = false
    @State private var result: String?

    var body: some View {
        Form {
            Section {
                Picker("Cuenta de destino", selection: $accountId) {
                    Text("Elegir…").tag(String?.none)
                    ForEach(store.accounts) { account in
                        Text("\(store.institution(for: account).name) · \(account.name)").tag(Optional(account.id))
                    }
                }
                Button("Crear cuenta nueva") { showingNewAccount = true }
            } footer: {
                Text("Los movimientos importados quedan asociados a esta cuenta. Importar dos veces la misma cartola no duplica movimientos.")
            }

            Section {
                Button {
                    showingImporter = true
                } label: {
                    Label("Elegir archivo CSV", systemImage: "doc.badge.plus")
                }
                .disabled(accountId == nil)
            } footer: {
                Text("En la web de tu banco, descarga la cartola o los últimos movimientos en Excel y guárdala como CSV (en Numbers: Archivo › Exportar a › CSV). Se reconocen columnas de fecha, descripción y monto, o cargos y abonos.")
            }

            if let result {
                Section("Resultado") {
                    Text(result)
                }
            }
        }
        .navigationTitle("Importar cartola")
        .onAppear {
            if accountId == nil { accountId = store.accounts.first(where: { $0.source != .bank })?.id }
        }
        .sheet(isPresented: $showingNewAccount) {
            NewAccountSheet { accountId = $0.id }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.commaSeparatedText, .plainText, .text, .data]) { outcome in
            switch outcome {
            case .success(let url):
                importFile(url)
            case .failure(let error):
                store.errorMessage = error.localizedDescription
            }
        }
    }

    private func importFile(_ url: URL) {
        guard let accountId else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            // Las cartolas chilenas suelen venir en UTF-8 o Latin-1 (Windows-1252).
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1252)
                    ?? String(data: data, encoding: .isoLatin1) else {
                store.errorMessage = "No se pudo leer el archivo. Asegúrate de que sea un CSV de texto."
                return
            }
            let outcome = try store.importCSV(text, into: accountId)
            Haptics.success()
            result = outcome.inserted == 0
                ? "No había movimientos nuevos."
                : "Se importaron \(outcome.inserted) movimientos\(outcome.skipped > 0 ? " (\(outcome.skipped) filas omitidas)" : "")."
        } catch {
            store.errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}

// MARK: - Categorías y reglas

struct CategoriesView: View {
    @Environment(FinanceStore.self) private var store
    @State private var showingNew = false

    var body: some View {
        List {
            Section {
                if store.rules.isEmpty {
                    Text("Cuando cambies la categoría de un movimiento y elijas aplicarla a todo el comercio, la regla aparecerá aquí.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(store.rules) { rule in
                    let category = store.category(rule.categoryId)
                    HStack(spacing: 12) {
                        CategoryIcon(category: category, size: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(rule.merchantKey.capitalized).font(.subheadline.weight(.medium))
                            Text("→ \(category.name)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button("Eliminar", role: .destructive) { store.deleteRule(rule) }
                    }
                }
            } header: {
                Text("Tus reglas")
            }

            ForEach(CategoryGroup.allCases, id: \.self) { group in
                Section(group.title) {
                    ForEach(store.categories(in: group)) { category in
                        HStack(spacing: 12) {
                            CategoryIcon(category: category, size: 28)
                            Text(category.name)
                            Spacer()
                            if category.isCustom {
                                Text("Personalizada").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            if category.isCustom {
                                Button("Eliminar", role: .destructive) { store.deleteCategory(category) }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Categorías")
        .toolbar {
            Button { showingNew = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("Nueva categoría")
        }
        .sheet(isPresented: $showingNew) { NewCategorySheet() }
    }
}

struct NewCategorySheet: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var group = CategoryGroup.wants
    @State private var symbol = CategoryStyleOptions.symbols[0]
    @State private var colorHex = CategoryStyleOptions.colors[0]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        CategoryIcon(category: FinanceCategory(id: "preview", name: name, symbol: symbol, colorHex: colorHex, group: group), size: 64)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                Section {
                    TextField("Nombre", text: $name)
                    Picker("Tipo", selection: $group) {
                        ForEach([CategoryGroup.needs, .wants, .savings, .income], id: \.self) { Text($0.title).tag($0) }
                    }
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(CategoryStyleOptions.colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay { if hex == colorHex { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white) } }
                                .onTapGesture { colorHex = hex }
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Ícono") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(CategoryStyleOptions.symbols, id: \.self) { item in
                            Image(systemName: item)
                                .frame(width: 36, height: 36)
                                .background(item == symbol ? Theme.track : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { symbol = item }
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Nueva categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        store.addCategory(name: name.trimmingCharacters(in: .whitespaces), symbol: symbol, colorHex: colorHex, group: group)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
