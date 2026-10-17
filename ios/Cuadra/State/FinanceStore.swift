import Foundation
import Observation
import CuadraCore

/// Transporte HTTP real para el cliente del backend.
struct URLSessionTransport: HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}

/// Estado central de la app. Todo cambio pasa por aquí, se recalculan las conclusiones y se guarda en disco.
@MainActor
@Observable
final class FinanceStore {
    private(set) var snapshot: FinanceSnapshot
    private(set) var engine: AnalyticsEngine
    private(set) var insights: [Insight] = []
    private(set) var healthScore: HealthScore?
    private(set) var recurring: [RecurringCharge] = []
    private(set) var plan: BudgetPlan?
    private(set) var budgetStatuses: [BudgetStatus] = []
    private(set) var estimatedIncome: Pesos?
    private(set) var isSyncing = false
    /// Hay un servidor configurado y este iPhone tiene su token en el Llavero.
    private(set) var isDeviceRegistered = false
    var errorMessage: String?
    var infoMessage: String?

    let calendar = FinanceCalendar.chile
    private let persistence: Persistence
    private static let serverURLKey = "serverURL"
    private static let tokenKey = "backendToken"

    init(persistence: Persistence = .shared) {
        self.persistence = persistence
        var loaded = persistence.load() ?? FinanceSnapshot()
        loaded.ensureDefaultCategories()
        snapshot = loaded
        engine = AnalyticsEngine(categories: loaded.categories, calendar: .chile)
        isDeviceRegistered = Keychain.get(Self.tokenKey) != nil && UserDefaults.standard.string(forKey: Self.serverURLKey) != nil
        recompute()
    }

    // MARK: Lectura

    var hasProfile: Bool { snapshot.profile != nil }
    var profile: UserProfile { snapshot.profile ?? UserProfile() }
    var transactions: [Movement] { snapshot.transactions }
    var accounts: [Account] { snapshot.accounts }
    var visibleAccounts: [Account] { snapshot.accounts.filter { !$0.isHidden } }
    var links: [BankLink] { snapshot.links }
    var categories: [FinanceCategory] { snapshot.categories }
    var budgets: [Budget] { snapshot.budgets }
    var goals: [SavingsGoal] { snapshot.goals }
    var rules: [UserRule] { snapshot.rules }
    var isDemo: Bool { snapshot.accounts.contains { $0.source == .demo } }

    var advisor: FinancialAdvisor { FinancialAdvisor(engine: engine) }

    func category(_ id: String) -> FinanceCategory { engine.category(id) }

    func account(_ id: String) -> Account? { snapshot.accounts.first { $0.id == id } }

    func institution(for account: Account) -> Institution { Institution.known(account.institutionId) }

    func categories(in group: CategoryGroup) -> [FinanceCategory] {
        snapshot.categories.filter { $0.group == group }
    }

    /// Movimientos de cuentas visibles (las cuentas ocultas no cuentan en el análisis).
    var analyzedTransactions: [Movement] {
        let hidden = Set(snapshot.accounts.filter(\.isHidden).map(\.id))
        return hidden.isEmpty ? snapshot.transactions : snapshot.transactions.filter { !hidden.contains($0.accountId) }
    }

    func summary(for period: Period) -> PeriodSummary {
        engine.summary(of: analyzedTransactions, in: period, now: Date(), smallExpenseThreshold: profile.smallExpenseThreshold)
    }

    var advisorInput: AdvisorInput {
        AdvisorInput(transactions: analyzedTransactions, accounts: visibleAccounts, budgets: snapshot.budgets,
                     goals: snapshot.goals, profile: profile, now: Date())
    }

    // MARK: Perfil y datos generales

    func saveProfile(_ profile: UserProfile) {
        snapshot.profile = profile
        commit()
    }

    func loadDemo() {
        snapshot = DemoData.snapshot(now: Date())
        engine = AnalyticsEngine(categories: snapshot.categories, calendar: calendar)
        commit()
    }

    /// Quita los datos de demostración y conserva el perfil.
    func clearDemo() {
        let profile = snapshot.profile
        snapshot = FinanceSnapshot(profile: profile)
        engine = AnalyticsEngine(categories: snapshot.categories, calendar: calendar)
        commit()
    }

    func resetAll() {
        snapshot = FinanceSnapshot()
        engine = AnalyticsEngine(categories: snapshot.categories, calendar: calendar)
        Keychain.set(nil, for: Self.tokenKey)
        isDeviceRegistered = false
        persistence.delete()
        recompute()
    }

    // MARK: Movimientos

    func add(_ movement: Movement) {
        snapshot.transactions.append(movement)
        snapshot.transactions.sort { $0.date > $1.date }
        commit()
    }

    func update(_ movement: Movement) {
        guard let index = snapshot.transactions.firstIndex(where: { $0.id == movement.id }) else { return }
        snapshot.transactions[index] = movement
        snapshot.transactions.sort { $0.date > $1.date }
        commit()
    }

    func delete(_ ids: Set<String>) {
        snapshot.transactions.removeAll { ids.contains($0.id) }
        commit()
    }

    /// Cambia la categoría; opcionalmente crea una regla para todos los movimientos del mismo comercio.
    func setCategory(_ categoryId: String, for movement: Movement, applyToMerchant: Bool) {
        if applyToMerchant {
            let key = movement.merchantKey
            snapshot.rules.removeAll { $0.merchantKey == key }
            snapshot.rules.append(UserRule(merchantKey: key, categoryId: categoryId))
            for index in snapshot.transactions.indices where snapshot.transactions[index].merchantKey == key {
                if snapshot.transactions[index].id == movement.id || snapshot.transactions[index].categorySource != .user {
                    snapshot.transactions[index].categoryId = categoryId
                    snapshot.transactions[index].categorySource = snapshot.transactions[index].id == movement.id ? .user : .userRule
                }
            }
        } else if let index = snapshot.transactions.firstIndex(where: { $0.id == movement.id }) {
            snapshot.transactions[index].categoryId = categoryId
            snapshot.transactions[index].categorySource = .user
        }
        commit()
    }

    func deleteRule(_ rule: UserRule) {
        snapshot.rules.removeAll { $0.id == rule.id }
        let categorizer = Categorizer(userRules: snapshot.rules, categories: snapshot.categories)
        for index in snapshot.transactions.indices where snapshot.transactions[index].categorySource == .userRule
            && snapshot.transactions[index].merchantKey == rule.merchantKey {
            snapshot.transactions[index].categorySource = .automatic
            snapshot.transactions[index] = categorizer.apply(to: snapshot.transactions[index])
        }
        commit()
    }

    func addCategory(name: String, symbol: String, colorHex: String, group: CategoryGroup) {
        let id = "custom-" + UUID().uuidString.prefix(8).lowercased()
        snapshot.categories.append(FinanceCategory(id: id, name: name, symbol: symbol, colorHex: colorHex, group: group, isCustom: true))
        engine = AnalyticsEngine(categories: snapshot.categories, calendar: calendar)
        commit()
    }

    func deleteCategory(_ category: FinanceCategory) {
        guard category.isCustom else { return }
        let fallback = category.group == .income ? CategoryID.otherIncome : CategoryID.otherExpense
        snapshot.categories.removeAll { $0.id == category.id }
        snapshot.rules.removeAll { $0.categoryId == category.id }
        snapshot.budgets.removeAll { $0.categoryId == category.id }
        for index in snapshot.transactions.indices where snapshot.transactions[index].categoryId == category.id {
            snapshot.transactions[index].categoryId = fallback
            snapshot.transactions[index].categorySource = .automatic
        }
        engine = AnalyticsEngine(categories: snapshot.categories, calendar: calendar)
        commit()
    }

    // MARK: Presupuestos y metas

    func setBudget(_ limit: Pesos?, for categoryId: String) {
        snapshot.budgets.removeAll { $0.categoryId == categoryId }
        if let limit, limit > 0 { snapshot.budgets.append(Budget(categoryId: categoryId, monthlyLimit: limit)) }
        commit()
    }

    func apply(_ plan: BudgetPlan) {
        snapshot.budgets = plan.lines.filter { $0.suggested > 0 }.map { Budget(categoryId: $0.categoryId, monthlyLimit: $0.suggested) }
        commit()
    }

    func save(_ goal: SavingsGoal) {
        if let index = snapshot.goals.firstIndex(where: { $0.id == goal.id }) {
            snapshot.goals[index] = goal
        } else {
            snapshot.goals.append(goal)
        }
        commit()
    }

    func deleteGoal(_ goal: SavingsGoal) {
        snapshot.goals.removeAll { $0.id == goal.id }
        commit()
    }

    // MARK: Cuentas

    func addManualAccount(name: String, kind: AccountKind, institutionId: String, balance: Pesos?) -> Account {
        let account = Account(id: "manual-" + UUID().uuidString, institutionId: institutionId, name: name, kind: kind,
                              balance: balance, availableBalance: balance, source: .manual)
        snapshot.accounts.append(account)
        commit()
        return account
    }

    func addCashAccount(id: String) {
        guard account(id) == nil else { return }
        snapshot.accounts.append(Account(id: id, institutionId: "cash", name: "Efectivo", kind: .cash, source: .manual))
        commit()
    }

    func update(_ account: Account) {
        guard let index = snapshot.accounts.firstIndex(where: { $0.id == account.id }) else { return }
        snapshot.accounts[index] = account
        commit()
    }

    func deleteAccount(_ account: Account) {
        snapshot.accounts.removeAll { $0.id == account.id }
        snapshot.transactions.removeAll { $0.accountId == account.id }
        commit()
    }

    /// Importa una cartola CSV a una cuenta. Devuelve (nuevos, filas omitidas).
    func importCSV(_ text: String, into accountId: String) throws -> (inserted: Int, skipped: Int) {
        let importer = CSVImporter(calendar: calendar)
        let result = try importer.parse(text)
        let categorizer = Categorizer(userRules: snapshot.rules, categories: snapshot.categories)
        let incoming = importer.transactions(from: result.rows, accountId: accountId, categorizer: categorizer)
        let merged = TransactionMerger.merge(existing: snapshot.transactions, incoming: incoming)
        snapshot.transactions = TransactionMerger.markInternalTransfers(merged.transactions, calendar: calendar)
        commit()
        return (merged.inserted, result.skippedRows)
    }

    func exportCSV() -> URL? {
        let text = CSVExporter.export(snapshot.transactions, categories: snapshot.categories, accounts: snapshot.accounts,
                                      calendar: calendar)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("movimientos-cuadra.csv")
        do {
            // BOM para que Excel reconozca los acentos.
            try Data(("\u{FEFF}" + text).utf8).write(to: url, options: .atomic)
            return url
        } catch {
            errorMessage = "No se pudo exportar: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: Conexión bancaria

    var serverURL: URL? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: Self.serverURLKey) else { return nil }
            return URL(string: raw)
        }
        set { UserDefaults.standard.set(newValue?.absoluteString, forKey: Self.serverURLKey) }
    }

    private func client() throws -> BackendClient {
        guard let serverURL else { throw BackendError.notConfigured }
        return BackendClient(baseURL: serverURL, token: Keychain.get(Self.tokenKey), transport: URLSessionTransport())
    }

    func registerDevice(serverAddress: String, appSecret: String) async throws {
        var address = serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if !address.lowercased().hasPrefix("http") { address = "https://" + address }
        while address.hasSuffix("/") { address.removeLast() }
        guard let url = URL(string: address), url.host != nil else { throw BackendError.notConfigured }
        let token = try await BackendClient(baseURL: url, token: nil, transport: URLSessionTransport())
            .register(appSecret: appSecret.trimmingCharacters(in: .whitespacesAndNewlines))
        serverURL = url
        Keychain.set(token, for: Self.tokenKey)
        isDeviceRegistered = true
    }

    /// Olvida el token de este iPhone (para vincularlo a otro servidor).
    func forgetDevice() {
        Keychain.set(nil, for: Self.tokenKey)
        isDeviceRegistered = false
    }

    func connectPageURL() -> URL? { try? client().connectPageURL }

    /// Se llama cuando el widget del banco entrega el exchangeToken.
    func completeConnection(exchangeToken: String) async {
        do {
            let remote = try await client().exchange(exchangeToken: exchangeToken)
            let institution = Institution.resolve(id: remote.institution.id, name: remote.institution.name)
            let link = BankLink(id: remote.id, institutionId: institution.id, institutionName: institution.name,
                                holderName: remote.holderName, createdAt: remote.createdAt)
            snapshot.links.removeAll { $0.id == link.id }
            snapshot.links.append(link)
            commit()
            Haptics.success()
            await sync(linkIds: [link.id])
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    func removeLink(_ link: BankLink, deleteData: Bool) async {
        do {
            try await client().deleteLink(id: link.id)
        } catch BackendError.server(404, _) {
            // Ya no existe en el servidor: se elimina localmente igual.
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        snapshot.links.removeAll { $0.id == link.id }
        let accountIds = Set(snapshot.accounts.filter { $0.linkId == link.id }.map(\.id))
        if deleteData {
            snapshot.accounts.removeAll { accountIds.contains($0.id) }
            snapshot.transactions.removeAll { accountIds.contains($0.accountId) }
        } else {
            for index in snapshot.accounts.indices where accountIds.contains(snapshot.accounts[index].id) {
                snapshot.accounts[index].linkId = nil
                snapshot.accounts[index].source = .manual
            }
        }
        commit()
    }

    /// Sincroniza si la última actualización tiene más de `hours` horas.
    func syncIfStale(hours: Double = 6) async {
        guard isDeviceRegistered, !snapshot.links.isEmpty else { return }
        let last = snapshot.links.compactMap(\.lastSyncedAt).min() ?? .distantPast
        if Date().timeIntervalSince(last) > hours * 3_600 { await sync() }
    }

    func sync(linkIds: Set<String>? = nil) async {
        guard !isSyncing else { return }
        let client: BackendClient
        do { client = try self.client() } catch {
            errorMessage = error.localizedDescription
            return
        }
        isSyncing = true
        defer { isSyncing = false }

        let mapper = BankMapper(calendar: calendar)
        let categorizer = Categorizer(userRules: snapshot.rules, categories: snapshot.categories)
        var inserted = 0
        var failures: [String] = []

        for link in snapshot.links where linkIds?.contains(link.id) ?? true {
            var updatedLink = link
            do {
                let remoteAccounts = try await client.accounts(linkId: link.id)
                for remote in remoteAccounts {
                    let localId = BankMapper.localAccountId(linkId: link.id, remoteId: remote.id)
                    let existing = snapshot.accounts.first { $0.id == localId }
                    // Primera vez: 12 meses. Después: desde la última sincronización con 7 días de margen
                    // (los bancos a veces contabilizan movimientos con atraso).
                    let since = existing?.lastSyncedAt.map { calendar.adding(days: -7, to: $0) }
                        ?? calendar.adding(months: -12, to: Date())
                    let movements = try await client.movements(linkId: link.id, accountId: remote.id, since: since)
                    let account = mapper.account(remote, link: link, existing: existing, now: Date())
                    if let index = snapshot.accounts.firstIndex(where: { $0.id == localId }) {
                        snapshot.accounts[index] = account
                    } else {
                        snapshot.accounts.append(account)
                    }
                    let incoming = movements.compactMap { mapper.transaction($0, accountId: localId, categorizer: categorizer) }
                    let merged = TransactionMerger.merge(existing: snapshot.transactions, incoming: incoming,
                                                         syncedAccounts: [localId], since: since)
                    snapshot.transactions = merged.transactions
                    inserted += merged.inserted
                }
                updatedLink.status = .active
                updatedLink.lastError = nil
                updatedLink.lastSyncedAt = Date()
            } catch BackendError.linkNeedsReconnect(let message) {
                updatedLink.status = .needsReconnect
                updatedLink.lastError = message
                failures.append("\(link.institutionName): requiere reconectar")
            } catch {
                updatedLink.status = .error
                updatedLink.lastError = error.localizedDescription
                failures.append("\(link.institutionName): \(error.localizedDescription)")
            }
            if let index = snapshot.links.firstIndex(where: { $0.id == link.id }) {
                snapshot.links[index] = updatedLink
            }
        }

        snapshot.transactions = TransactionMerger.markInternalTransfers(snapshot.transactions, calendar: calendar)
        commit()
        if failures.isEmpty {
            infoMessage = inserted == 0 ? "Todo al día" : (inserted == 1 ? "1 movimiento nuevo" : "\(inserted) movimientos nuevos")
        } else {
            errorMessage = failures.joined(separator: "\n")
        }
    }

    // MARK: Recalcular y guardar

    private func commit() {
        recompute()
        persistence.save(snapshot)
        NotificationScheduler.update(
            statuses: budgetStatuses,
            upcoming: advisor.recurring.upcoming(recurring, now: Date(), days: 7),
            categories: Dictionary(uniqueKeysWithValues: snapshot.categories.map { ($0.id, $0.name) }),
            calendar: calendar
        )
    }

    private func recompute() {
        let advisor = self.advisor
        let input = advisorInput
        estimatedIncome = advisor.estimatedMonthlyIncome(input)
        recurring = advisor.recurring.detect(input.transactions, now: input.now)
        budgetStatuses = advisor.budgetStatuses(input)
        insights = snapshot.profile == nil && snapshot.transactions.isEmpty ? [] : advisor.insights(input)
        healthScore = advisor.healthScore(input)
        plan = advisor.suggestedPlan(input)
    }

    /// Recalcula al volver a la app (por ejemplo, si cambió el mes).
    func refreshDerivedData() { recompute() }
}
