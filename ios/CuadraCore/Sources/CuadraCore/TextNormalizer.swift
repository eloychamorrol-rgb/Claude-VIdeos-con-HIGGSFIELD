import Foundation

public enum TextNormalizer {
    /// Mayúsculas, sin tildes y solo letras/números separados por un espacio.
    /// "Compra Nac. ÑUÑOA*Café" -> "COMPRA NAC NUNOA CAFE"
    public static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_CL"))
            .uppercased()
        var result = ""
        result.reserveCapacity(folded.count)
        var lastWasSpace = true
        for scalar in folded.unicodeScalars {
            let isAlnum = (scalar.value >= 48 && scalar.value <= 57) || (scalar.value >= 65 && scalar.value <= 90)
            if isAlnum {
                result.unicodeScalars.append(scalar)
                lastWasSpace = false
            } else if !lastWasSpace {
                result.append(" ")
                lastWasSpace = true
            }
        }
        if result.hasSuffix(" ") { result.removeLast() }
        return result
    }

    /// Palabras que los bancos anteponen a la glosa y que no son parte del comercio.
    static let leadingNoise: Set<String> = [
        "COMPRA", "COMPRAS", "NAC", "NACIONAL", "NACIONALES", "INTERNAC", "INTERNACIONAL", "INT", "PAGO", "PAGOS",
        "EN", "LINEA", "WEB", "POS", "REDCOMPRA", "CARGO", "CARGOS", "ABONO", "TEF", "TRANSF", "TRANSFERENCIA",
        "TRANSFERENCIAS", "A", "DE", "DESDE", "PARA", "OTROS", "OTRO", "BANCOS", "BANCO", "TERCEROS", "CUENTA",
        "CTA", "PAC", "PAT", "AUTOMATICO", "AUTOMATICA", "MERPAGO", "WWW", "COM", "CL", "DEBITO", "CREDITO",
        "TARJETA", "TC", "TD", "VENTA", "OPERACION"
    ]

    /// Sufijos frecuentes (ciudades, razón social) que ensucian el nombre.
    static let trailingNoise: Set<String> = [
        "SANTIAGO", "CL", "CHL", "CHILE", "SPA", "LTDA", "SA", "S", "EIRL", "PROVIDENCIA", "NUNOA", "VITACURA",
        "CONDES", "LAS", "MAIPU", "FLORIDA", "LA", "VINA", "MAR", "DEL", "CONCEPCION", "VALPARAISO", "ANTOFAGASTA",
        "TEMUCO", "RANCAGUA", "TALCA", "SERENA", "HUECHURABA", "RECOLETA", "INDEPENDENCIA", "QUILICURA",
        "PENALOLEN", "MACUL", "COLINA", "LAMPA", "PUDAHUEL", "CERRILLOS", "ESTACION", "CENTRAL", "LO", "BARNECHEA",
        "COM", "WWW", "CHILENA", "STGO", "RM"
    ]

    /// Obtiene un nombre de comercio legible a partir de la glosa del banco.
    public static func merchantName(from rawDescription: String) -> String {
        var tokens = normalize(rawDescription)
            .split(separator: " ")
            .map(String.init)
            .filter { token in !token.contains(where: \.isNumber) }
        while let first = tokens.first, leadingNoise.contains(first) { tokens.removeFirst() }
        while let last = tokens.last, trailingNoise.contains(last), tokens.count > 1 { tokens.removeLast() }
        if tokens.count == 1, trailingNoise.contains(tokens[0]) { tokens.removeAll() }
        guard !tokens.isEmpty else {
            let trimmed = rawDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Sin descripción" : trimmed
        }
        return tokens.prefix(4).map(titleCase).joined(separator: " ")
    }

    static let acronyms: Set<String> = ["TAG", "SII", "BCI", "ATM", "AFP", "APV", "HBO", "IVA", "UF", "EFE", "BIP", "VTR", "WOM", "GTD", "CGE", "BICE", "HSBC", "DUOC"]

    static func titleCase(_ word: String) -> String {
        // Siglas se mantienen en mayúsculas (KFC, TAG, SII).
        let vowels: Set<Character> = ["A", "E", "I", "O", "U"]
        if acronyms.contains(word) || (word.count <= 4 && !word.contains(where: { vowels.contains($0) })) { return word }
        return word.prefix(1) + word.dropFirst().lowercased()
    }
}
