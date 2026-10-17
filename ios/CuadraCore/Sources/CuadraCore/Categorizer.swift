import Foundation

public struct CategorizationResult: Equatable, Sendable {
    public let categoryId: String
    public let merchant: String
    public let source: CategorySource
}

/// Asigna categoría y nombre de comercio a un movimiento.
/// Prioridad: reglas del usuario > reglas del sistema > categoría genérica según el signo.
public struct Categorizer: Sendable {
    private let userRules: [String: String]
    private let validCategoryIds: Set<String>

    public init(userRules: [UserRule], categories: [Category]) {
        var map: [String: String] = [:]
        // La regla más reciente gana si hay duplicados.
        for rule in userRules.sorted(by: { $0.createdAt < $1.createdAt }) {
            map[rule.merchantKey] = rule.categoryId
        }
        self.userRules = map
        self.validCategoryIds = Set(categories.map(\.id))
    }

    public func categorize(description: String, amount: Pesos, counterpartyName: String? = nil) -> CategorizationResult {
        let normalized = TextNormalizer.normalize(description)
        let padded = " \(normalized) "
        let isInflow = amount > 0

        var merchant = TextNormalizer.merchantName(from: description)
        var categoryId: String?

        for rule in MerchantRules.all {
            switch rule.direction {
            case .inflow where !isInflow, .outflow where isInflow: continue
            default: break
            }
            if rule.matches(paddedText: padded) {
                categoryId = rule.categoryId
                if let canonical = rule.merchant { merchant = canonical }
                break
            }
        }

        // En transferencias, el nombre de la contraparte es más útil que la glosa.
        if let name = counterpartyName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
           categoryId == nil || categoryId == CategoryID.transfersIn || categoryId == CategoryID.transfersOut {
            merchant = name.split(separator: " ").prefix(3).map { TextNormalizer.titleCase(TextNormalizer.normalize(String($0))) }
                .joined(separator: " ")
            if categoryId == nil { categoryId = isInflow ? CategoryID.transfersIn : CategoryID.transfersOut }
        }

        if let ruleCategory = userRules[TextNormalizer.normalize(merchant)], validCategoryIds.contains(ruleCategory) {
            return CategorizationResult(categoryId: ruleCategory, merchant: merchant, source: .userRule)
        }

        let fallback = isInflow ? CategoryID.otherIncome : CategoryID.otherExpense
        var resolved = categoryId ?? fallback
        if !validCategoryIds.contains(resolved) { resolved = fallback }
        return CategorizationResult(categoryId: resolved, merchant: merchant, source: .automatic)
    }

    /// Re-categoriza respetando los cambios manuales del usuario.
    public func apply(to transaction: Transaction) -> Transaction {
        guard transaction.categorySource != .user else { return transaction }
        var updated = transaction
        let result = categorize(description: transaction.rawDescription, amount: transaction.amount)
        // Si el comercio fue fijado desde la contraparte (transferencias), se conserva.
        let merchantKeyRule = userRules[transaction.merchantKey]
        if let merchantKeyRule, validCategoryIds.contains(merchantKeyRule) {
            updated.categoryId = merchantKeyRule
            updated.categorySource = .userRule
        } else {
            updated.categoryId = result.categoryId
            updated.categorySource = result.source
        }
        return updated
    }
}
