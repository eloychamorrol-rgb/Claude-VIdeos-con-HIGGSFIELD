import Foundation

/// Formato de montos en pesos chilenos, independiente de la configuración regional del teléfono.
public enum MoneyFormat {
    /// 1234567 -> "$1.234.567"; -2500 -> "-$2.500"; con `signed` los positivos llevan "+".
    public static func clp(_ amount: Pesos, signed: Bool = false) -> String {
        let sign = amount < 0 ? "-" : (signed && amount > 0 ? "+" : "")
        return "\(sign)$\(grouped(amount.magnitude))"
    }

    /// Formato compacto para ejes de gráficos: "$850", "$12 mil", "$1,2 M", "$15 M".
    public static func compact(_ amount: Pesos) -> String {
        let sign = amount < 0 ? "-" : ""
        let value = Double(amount.magnitude)
        if value >= 1_000_000 {
            let millions = value / 1_000_000
            let text = millions >= 10 ? "\(Int(millions.rounded()))" : decimal(millions)
            return "\(sign)$\(text) M"
        }
        if value >= 1_000 {
            return "\(sign)$\(Int((value / 1_000).rounded())) mil"
        }
        return "\(sign)$\(Int(value))"
    }

    /// 0.256 -> "26 %"
    public static func percent(_ value: Double, decimals: Int = 0) -> String {
        guard value.isFinite else { return "–" }
        let scaled = value * 100
        if decimals == 0 { return "\(Int(scaled.rounded())) %" }
        return "\(decimal(scaled, digits: decimals)) %"
    }

    /// Variación porcentual con signo: "+12 %", "-8 %".
    public static func change(_ value: Double) -> String {
        guard value.isFinite else { return "–" }
        let rounded = Int((value * 100).rounded())
        return rounded > 0 ? "+\(rounded) %" : "\(rounded) %"
    }

    static func grouped(_ value: UInt) -> String {
        let digits = String(value)
        var result = ""
        for (index, char) in digits.enumerated() {
            if index > 0 && (digits.count - index) % 3 == 0 { result.append(".") }
            result.append(char)
        }
        return result
    }

    static func decimal(_ value: Double, digits: Int = 1) -> String {
        let factor = pow(10.0, Double(digits))
        let rounded = (value * factor).rounded() / factor
        let integerPart = Int(rounded)
        let fraction = Int(((rounded - Double(integerPart)) * factor).rounded())
        if fraction == 0 { return "\(integerPart)" }
        var fractionText = String(fraction)
        while fractionText.count < digits { fractionText = "0" + fractionText }
        return "\(integerPart),\(fractionText)"
    }

    /// Interpreta montos escritos a la chilena o en formato internacional.
    /// "$ 1.234.567" -> 1234567, "-12.990" -> -12990, "1.234,50" -> 1235, "(5.000)" -> -5000, "1,234.56" -> 1235
    public static func parse(_ text: String) -> Pesos? {
        var raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        var negative = false
        if raw.hasPrefix("(") && raw.hasSuffix(")") {
            negative = true
            raw = String(raw.dropFirst().dropLast())
        }
        raw = raw.replacingOccurrences(of: "CLP", with: "").replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\u{00A0}", with: "")
        if raw.hasPrefix("-") { negative.toggle(); raw.removeFirst() } else if raw.hasPrefix("+") { raw.removeFirst() }
        if raw.hasSuffix("-") { negative.toggle(); raw.removeLast() }
        guard !raw.isEmpty, raw.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == "." || $0 == ",") }),
              raw.contains(where: \.isNumber) else { return nil }

        let lastDot = raw.lastIndex(of: ".")
        let lastComma = raw.lastIndex(of: ",")
        var integerText = raw
        var fractionText = ""

        func split(at index: String.Index) {
            integerText = String(raw[..<index])
            fractionText = String(raw[raw.index(after: index)...])
        }

        switch (lastDot, lastComma) {
        case let (dot?, comma?):
            split(at: max(dot, comma))
        case let (dot?, nil):
            if !isThousandsGrouping(raw, separator: ".") { split(at: dot) }
        case let (nil, comma?):
            if !isThousandsGrouping(raw, separator: ",") { split(at: comma) }
        case (nil, nil):
            break
        }
        integerText.removeAll(where: { $0 == "." || $0 == "," })
        guard let integerValue = Int(integerText.isEmpty ? "0" : integerText) else { return nil }
        var value = integerValue
        if let first = fractionText.first, let digit = first.wholeNumberValue, digit >= 5 { value += 1 }
        return negative ? -value : value
    }

    private static func isThousandsGrouping(_ text: String, separator: Character) -> Bool {
        let parts = text.split(separator: separator, omittingEmptySubsequences: false)
        guard parts.count > 1, let first = parts.first, !first.isEmpty, first.count <= 3 else { return false }
        return parts.dropFirst().allSatisfy { $0.count == 3 }
    }
}
