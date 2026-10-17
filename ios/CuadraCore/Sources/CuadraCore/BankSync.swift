import Foundation

// MARK: - Formato que entrega el backend (es el mismo de la API de Fintoc)

public struct RemoteInstitution: Codable, Hashable, Sendable {
    public let id: String
    public let name: String
}

public struct RemoteLink: Codable, Hashable, Sendable {
    public let id: String
    public let institution: RemoteInstitution
    public let holderName: String?
    public let createdAt: Date
}

public struct RemoteBalance: Codable, Hashable, Sendable {
    public let available: Int?
    public let current: Int?
    public let limit: Int?
}

public struct RemoteAccount: Codable, Hashable, Sendable {
    public let id: String
    public let name: String?
    public let officialName: String?
    public let number: String?
    public let type: String?
    public let currency: String?
    public let balance: RemoteBalance?

    enum CodingKeys: String, CodingKey {
        case id, name, number, type, currency, balance
        case officialName = "official_name"
    }
}

public struct RemoteCounterparty: Codable, Hashable, Sendable {
    public let holderName: String?

    enum CodingKeys: String, CodingKey { case holderName = "holder_name" }
}

public struct RemoteMovement: Codable, Hashable, Sendable {
    public let id: String
    public let amount: Int
    public let currency: String?
    public let description: String?
    public let postDate: String?
    public let transactionDate: String?
    public let type: String?
    public let pending: Bool?
    public let senderAccount: RemoteCounterparty?
    public let recipientAccount: RemoteCounterparty?
    public let comment: String?

    enum CodingKeys: String, CodingKey {
        case id, amount, currency, description, type, pending, comment
        case postDate = "post_date"
        case transactionDate = "transaction_date"
        case senderAccount = "sender_account"
        case recipientAccount = "recipient_account"
    }
}

/// Convierte datos del agregador al modelo de la app.
public struct BankMapper: Sendable {
    public let calendar: FinanceCalendar

    public init(calendar: FinanceCalendar = .chile) { self.calendar = calendar }

    public static func localAccountId(linkId: String, remoteId: String) -> String { "bank-\(linkId)-\(remoteId)" }

    public func account(_ remote: RemoteAccount, link: BankLink, existing: Account?, now: Date) -> Account {
        let kind: AccountKind
        switch remote.type ?? "" {
        case "checking_account": kind = .checking
        case "sight_account": kind = .sight
        case "savings_account": kind = .savings
        case "line_of_credit": kind = .creditLine
        case "credit_card": kind = .creditCard
        default: kind = .other
        }
        let number = remote.number ?? ""
        let masked = number.count > 4 ? "•••• " + number.suffix(4) : number
        let fallbackName = remote.officialName ?? kind.title
        return Account(
            id: Self.localAccountId(linkId: link.id, remoteId: remote.id),
            institutionId: link.institutionId,
            name: existing?.name ?? ((remote.name?.isEmpty == false ? remote.name : nil) ?? fallbackName),
            numberMasked: masked, kind: kind, currency: remote.currency ?? "CLP",
            balance: remote.balance?.current, availableBalance: remote.balance?.available,
            source: .bank, linkId: link.id, externalId: remote.id, lastSyncedAt: now,
            isHidden: existing?.isHidden ?? false
        )
    }

    public func transaction(_ remote: RemoteMovement, accountId: String, categorizer: Categorizer) -> Transaction? {
        let resolved = resolveDate(transactionDate: remote.transactionDate, postDate: remote.postDate)
        guard let resolved else { return nil }
        let description = (remote.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? (remote.amount >= 0 ? "Abono" : "Cargo")
        let counterparty = remote.amount >= 0 ? remote.senderAccount?.holderName : remote.recipientAccount?.holderName
        let result = categorizer.categorize(description: description, amount: remote.amount, counterpartyName: counterparty)
        return Transaction(id: "bank-\(remote.id)", accountId: accountId, amount: remote.amount,
                           currency: remote.currency ?? "CLP", date: resolved.date, hasTime: resolved.hasTime,
                           rawDescription: description, merchant: result.merchant, categoryId: result.categoryId,
                           categorySource: result.source, note: remote.comment, isPending: remote.pending ?? false,
                           source: .bank)
    }

    /// Las fechas sin hora llegan como medianoche UTC; si se interpretan tal cual, en Chile caen el día anterior.
    /// Por eso se toma el día calendario UTC y se ubica al mediodía de Santiago.
    func resolveDate(transactionDate: String?, postDate: String?) -> (date: Date, hasTime: Bool)? {
        for raw in [transactionDate, postDate].compactMap({ $0 }) {
            guard let instant = Self.parseISO(raw) else { continue }
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!
            let comps = utc.dateComponents([.year, .month, .day, .hour, .minute, .second], from: instant)
            let isDateOnly = (comps.hour ?? 0) == 0 && (comps.minute ?? 0) == 0 && (comps.second ?? 0) == 0
            if isDateOnly || raw.count <= 10 {
                let local = DateComponents(year: comps.year, month: comps.month, day: comps.day, hour: 12)
                if let date = calendar.calendar.date(from: local) { return (date, false) }
            } else {
                return (instant, true)
            }
        }
        return nil
    }

    static func parseISO(_ raw: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        if let date = plain.date(from: raw) { return date }
        let dateOnly = ISO8601DateFormatter()
        dateOnly.formatOptions = [.withFullDate]
        return dateOnly.date(from: raw)
    }
}

// MARK: - Fusión

public struct MergeResult: Sendable {
    public let transactions: [Transaction]
    public let inserted: Int
    public let updated: Int
    public let removedPending: Int
}

public enum TransactionMerger {
    /// Fusiona movimientos nuevos con los existentes:
    /// - no duplica (misma id),
    /// - conserva categorías y notas puestas por el usuario,
    /// - elimina pendientes de las cuentas sincronizadas que ya no vienen en la respuesta (el banco los contabilizó con otra id).
    public static func merge(existing: [Transaction], incoming: [Transaction], syncedAccounts: Set<String> = [],
                             since: Date? = nil) -> MergeResult {
        var byId: [String: Transaction] = [:]
        var order: [String] = []
        for transaction in existing where byId[transaction.id] == nil {
            byId[transaction.id] = transaction
            order.append(transaction.id)
        }
        let incomingIds = Set(incoming.map(\.id))
        var inserted = 0, updated = 0, removedPending = 0

        for transaction in incoming {
            if let old = byId[transaction.id] {
                var merged = transaction
                if old.categorySource != .automatic {
                    merged.categoryId = old.categoryId
                    merged.categorySource = old.categorySource
                }
                if old.note != nil && (merged.note ?? "").isEmpty { merged.note = old.note }
                if merged.merchant.isEmpty { merged.merchant = old.merchant }
                if merged != old {
                    byId[transaction.id] = merged
                    updated += 1
                }
            } else {
                byId[transaction.id] = transaction
                order.append(transaction.id)
                inserted += 1
            }
        }

        if !syncedAccounts.isEmpty {
            for id in order {
                guard let transaction = byId[id], transaction.isPending, syncedAccounts.contains(transaction.accountId),
                      !incomingIds.contains(id), since.map({ transaction.date >= $0 }) ?? true else { continue }
                byId[id] = nil
                removedPending += 1
            }
        }

        let merged = order.compactMap { byId[$0] }.sorted { $0.date != $1.date ? $0.date > $1.date : $0.id < $1.id }
        return MergeResult(transactions: merged, inserted: inserted, updated: updated, removedPending: removedPending)
    }

    /// Marca como "entre mis cuentas" pares salida/entrada del mismo monto en cuentas propias distintas (máx. 3 días).
    public static func markInternalTransfers(_ transactions: [Transaction], calendar: FinanceCalendar = .chile) -> [Transaction] {
        let candidates: Set<String> = [CategoryID.transfersOut, CategoryID.transfersIn, CategoryID.otherExpense,
                                       CategoryID.otherIncome, CategoryID.ownTransfer]
        var result = transactions
        var used = Set<Int>()
        let outflows = result.indices.filter {
            result[$0].amount < 0 && result[$0].categorySource == .automatic && candidates.contains(result[$0].categoryId)
        }
        let inflows = result.indices.filter {
            result[$0].amount > 0 && result[$0].categorySource == .automatic && candidates.contains(result[$0].categoryId)
        }
        let window: TimeInterval = 3 * 86_400
        for out in outflows {
            guard let match = inflows.first(where: { index in
                !used.contains(index) && result[index].accountId != result[out].accountId
                    && result[index].amount == -result[out].amount && result[index].currency == result[out].currency
                    && abs(result[index].date.timeIntervalSince(result[out].date)) <= window
            }) else { continue }
            used.insert(match)
            for index in [out, match] {
                result[index].categoryId = CategoryID.ownTransfer
                result[index].merchant = "Entre mis cuentas"
            }
        }
        return result
    }
}
