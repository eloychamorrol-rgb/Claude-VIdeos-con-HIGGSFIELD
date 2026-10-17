import SwiftUI
import UIKit
import CuadraCore

/// Paleta sobria: tinta casi negra como acento, verde solo para ingresos y rojo solo para alertas.
enum Theme {
    static let ink = Color(light: UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1),
                           dark: UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1))
    static let inkInverse = Color(light: .white, dark: UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1))
    static let positive = Color(light: UIColor(red: 0.12, green: 0.55, blue: 0.33, alpha: 1),
                                dark: UIColor(red: 0.30, green: 0.78, blue: 0.52, alpha: 1))
    static let negative = Color(light: UIColor(red: 0.84, green: 0.24, blue: 0.22, alpha: 1),
                                dark: UIColor(red: 1.00, green: 0.42, blue: 0.40, alpha: 1))
    static let warning = Color(light: UIColor(red: 0.85, green: 0.52, blue: 0.08, alpha: 1),
                               dark: UIColor(red: 1.00, green: 0.70, blue: 0.25, alpha: 1))
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let separator = Color(uiColor: .separator)
    static let track = Color(uiColor: .tertiarySystemFill)

    static let cornerRadius: CGFloat = 22
    static let padding: CGFloat = 16

    static func color(for kind: InsightKind) -> Color {
        switch kind {
        case .alert: return negative
        case .warning: return warning
        case .info: return Color.secondary
        case .positive: return positive
        }
    }

    /// Fuente para montos: redondeada y con dígitos de ancho fijo.
    static func amountFont(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .rounded).weight(weight).monospacedDigit()
    }
}

extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    /// "#RRGGBB" -> Color. Valores inválidos devuelven gris.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            self = .gray
            return
        }
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}

extension CuadraCore.Category {
    var color: Color { Color(hex: colorHex) }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.padding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

extension View {
    func card(padding: CGFloat = Theme.padding) -> some View { modifier(CardModifier(padding: padding)) }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

/// Botón principal: cápsula de tinta, como en las apps de Apple.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.inkInverse)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.ink.opacity(isEnabled ? 1 : 0.3), in: Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
