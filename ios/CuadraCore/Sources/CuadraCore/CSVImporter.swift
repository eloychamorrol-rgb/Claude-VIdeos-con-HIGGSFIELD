import Foundation

public enum CSVImportError: Error, Equatable, LocalizedError {
    case empty
    case headerNotFound
    case noValidRows

    public var errorDescription: String? {
        switch self {
        case .empty: return "El archivo está vacío."
        case .headerNotFound: return "No encontré las columnas de fecha, descripción y monto. Revisa que la cartola tenga encabezados."
        case .noValidRows: return "No encontré movimientos válidos en el archivo."
        }
    }
}

public struct ImportedRow: Equatable, Sendable {
    public let date: Date
    public let hasTime: Bool
    public let description: String
    public let amount: Pesos
}

public struct CSVImportResult: Sendable {
    public let rows: [ImportedRow]
    public let skippedRows: Int
}

/// Importa cartolas exportadas por los bancos (CSV con `;`, `,` o tabulaciones).
/// Reconoce columnas de fecha, descripción y monto (o cargo/abono por separado).
public struct CSVImporter: Sendable {
    public let calendar: FinanceCalendar

    public init(calendar: FinanceCalendar = .chile) { self.calendar = calendar }

    public func parse(_ text: String) throws -> CSVImportResult {
        let cleaned = text.replacingOccurrences(of: "\u{FEFF}", with: "")
        let lines = cleaned.split(omittingEmptySubsequences: true, whereSeparator: { $0 == "\n" || $0 == "\r\n" || $0 == "\r" })
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !lines.isEmpty else { throw CSVImportError.empty }

        let delimiter = detectDelimiter(Array(lines.prefix(30)))
        let table = lines.map { splitLine($0, delimiter: delimiter) }

        guard let header = findHeader(table) else { throw CSVImportError.headerNotFound }
        var rows: [ImportedRow] = []
        var skipped = 0

        for fields in table[(header.row + 1)...] {
            func field(_ index: Int?) -> String {
                guard let index, index < fields.count else { return "" }
                return fields[index].trimmingCharacters(in: .whitespaces)
            }
            guard let parsedDate = parseDate(field(header.date), time: field(header.time)) else {
                skipped += 1
                continue
            }
            var amount: Pesos?
            if let amountColumn = header.amount {
                amount = MoneyFormat.parse(field(amountColumn))
            } else {
                let debit = MoneyFormat.parse(field(header.debit)).map { abs($0) } ?? 0
                let credit = MoneyFormat.parse(field(header.credit)).map { abs($0) } ?? 0
                amount = (debit == 0 && credit == 0) ? nil : credit - debit
            }
            let description = field(header.description)
            guard let amount, amount != 0, !description.isEmpty else {
                skipped += 1
                continue
            }
            rows.append(ImportedRow(date: parsedDate.date, hasTime: parsedDate.hasTime, description: description, amount: amount))
        }
        guard !rows.isEmpty else { throw CSVImportError.noValidRows }
        return CSVImportResult(rows: rows, skippedRows: skipped)
    }

    /// Convierte filas importadas en movimientos con id estable (reimportar no duplica).
    public func transactions(from rows: [ImportedRow], accountId: String, categorizer: Categorizer) -> [Transaction] {
        var seen: [String: Int] = [:]
        return rows.map { row in
            let base = "\(accountId)|\(Int(row.date.timeIntervalSince1970))|\(row.amount)|\(TextNormalizer.normalize(row.description))"
            let occurrence = seen[base, default: 0]
            seen[base] = occurrence + 1
            let result = categorizer.categorize(description: row.description, amount: row.amount)
            return Transaction(id: "csv-" + StableHash.hex("\(base)|\(occurrence)"), accountId: accountId, amount: row.amount,
                               date: row.date, hasTime: row.hasTime, rawDescription: row.description,
                               merchant: result.merchant, categoryId: result.categoryId,
                               categorySource: result.source, source: .csv)
        }
    }

    // MARK: Detección

    struct Header {
        let row: Int
        let date: Int
        let time: Int?
        let description: Int
        let amount: Int?
        let debit: Int?
        let credit: Int?
    }

    func findHeader(_ table: [[String]]) -> Header? {
        for (rowIndex, fields) in table.prefix(40).enumerated() {
            let names = fields.map { TextNormalizer.normalize($0) }
            func column(_ candidates: [String], excluding: Set<Int> = []) -> Int? {
                for candidate in candidates {
                    if let index = names.indices.first(where: { !excluding.contains($0) && names[$0] == candidate }) { return index }
                }
                for candidate in candidates {
                    if let index = names.indices.first(where: { !excluding.contains($0) && names[$0].contains(candidate) }) { return index }
                }
                return nil
            }
            guard let date = column(["FECHA", "FECHA OPERACION", "FECHA MOVIMIENTO", "FECHA TRANSACCION", "DATE"]) else { continue }
            let time = column(["HORA", "TIME"], excluding: [date])
            guard let description = column(["DESCRIPCION", "DETALLE", "GLOSA", "MOVIMIENTO", "CONCEPTO", "COMERCIO",
                                             "DESCRIPTION", "TRANSACCION", "NOMBRE"], excluding: [date]) else { continue }
            let used: Set<Int> = [date, description]
            let amount = column(["MONTO", "IMPORTE", "AMOUNT", "VALOR"], excluding: used)
            let debit = column(["CARGO", "CARGOS", "DEBITO", "DEBITOS", "GIROS", "EGRESO", "EGRESOS"], excluding: used)
            let credit = column(["ABONO", "ABONOS", "DEPOSITOS", "CREDITO", "CREDITOS", "INGRESO", "INGRESOS"], excluding: used)
            if debit != nil || credit != nil {
                return Header(row: rowIndex, date: date, time: time, description: description, amount: nil, debit: debit, credit: credit)
            }
            if let amount {
                return Header(row: rowIndex, date: date, time: time, description: description, amount: amount, debit: nil, credit: nil)
            }
        }
        return nil
    }

    func detectDelimiter(_ lines: [String]) -> Character {
        let candidates: [Character] = [";", "\t", ","]
        var best: Character = ","
        var bestScore = 0
        for candidate in candidates {
            let score = lines.reduce(0) { $0 + splitLine($1, delimiter: candidate).count - 1 }
            if score > bestScore {
                best = candidate
                bestScore = score
            }
        }
        return best
    }

    func splitLine(_ line: String, delimiter: Character) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = Array(line).makeIterator()
        var pending: Character? = nil
        while let char = pending ?? iterator.next() {
            pending = nil
            if char == "\"" {
                if inQuotes {
                    if let next = iterator.next() {
                        if next == "\"" { current.append("\"") } else { inQuotes = false; pending = next }
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if char == delimiter && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }

    /// Acepta dd/mm/aaaa, dd-mm-aaaa, dd.mm.aaaa, dd/mm/aa, aaaa-mm-dd y hora opcional hh:mm[:ss].
    func parseDate(_ text: String, time: String = "") -> (date: Date, hasTime: Bool)? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(whereSeparator: { $0 == " " || $0 == "T" }).map(String.init)
        guard let datePart = parts.first else { return nil }
        let numbers = datePart.split(whereSeparator: { $0 == "/" || $0 == "-" || $0 == "." }).compactMap { Int($0) }
        guard numbers.count == 3 else { return nil }

        var day: Int, month: Int, year: Int
        if numbers[0] > 31 {
            (year, month, day) = (numbers[0], numbers[1], numbers[2])
        } else {
            (day, month, year) = (numbers[0], numbers[1], numbers[2])
            if year < 100 { year += 2000 }
        }
        guard (1...12).contains(month), (1...31).contains(day), (1990...2100).contains(year) else { return nil }

        let timeText = time.isEmpty ? (parts.count > 1 ? parts[1] : "") : time
        let timeNumbers = timeText.split(separator: ":").compactMap { Int($0.prefix(2)) }
        let hasTime = timeNumbers.count >= 2 && (0...23).contains(timeNumbers[0]) && (0...59).contains(timeNumbers[1])
            && !(timeNumbers[0] == 0 && timeNumbers[1] == 0)

        var components = DateComponents(year: year, month: month, day: day)
        if hasTime {
            components.hour = timeNumbers[0]
            components.minute = timeNumbers[1]
        } else {
            components.hour = 12
        }
        guard let date = calendar.calendar.date(from: components),
              calendar.calendar.component(.day, from: date) == day else { return nil }
        return (date, hasTime)
    }
}

/// Hash FNV-1a de 64 bits: estable entre ejecuciones (a diferencia de `hashValue`).
public enum StableHash {
    public static func hex(_ text: String) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        let hex = String(hash, radix: 16)
        return String(repeating: "0", count: 16 - hex.count) + hex
    }
}
