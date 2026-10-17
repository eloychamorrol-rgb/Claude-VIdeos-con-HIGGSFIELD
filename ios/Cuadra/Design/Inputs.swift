import SwiftUI
import CuadraCore

/// Campo de monto en pesos: solo dígitos, se muestra con separador de miles.
struct PesosField: View {
    let title: String
    @Binding var value: Pesos?
    var font: Font = Theme.amountFont(.body, weight: .regular)
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.numberPad)
            .font(font)
            .focused($focused)
            .onAppear { text = value.map { MoneyFormat.clp($0) } ?? "" }
            .onChange(of: text) { _, newText in
                let digits = String(newText.filter(\.isNumber).prefix(12))
                let parsed = Int(digits)
                if parsed != value { value = parsed }
                let formatted = parsed.map { MoneyFormat.clp($0) } ?? ""
                if formatted != newText { text = formatted }
            }
            .onChange(of: value) { _, newValue in
                let formatted = newValue.map { MoneyFormat.clp($0) } ?? ""
                if formatted != text { text = formatted }
            }
            .toolbar {
                if focused {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Listo") { focused = false }
                    }
                }
            }
    }
}

/// Elección de ícono y color para categorías personalizadas.
enum CategoryStyleOptions {
    static let symbols = ["tag.fill", "star.fill", "heart.fill", "leaf.fill", "gamecontroller.fill", "music.note",
                          "camera.fill", "paintbrush.fill", "wrench.and.screwdriver.fill", "graduationcap.fill",
                          "stroller.fill", "figure.and.child.holdinghands", "dumbbell.fill", "cup.and.saucer.fill",
                          "wineglass.fill", "tshirt.fill", "laptopcomputer", "iphone", "bicycle", "fuelpump.fill",
                          "building.2.fill", "bag.fill", "creditcard.fill", "banknote.fill"]
    static let colors = ["#5E7CE2", "#3FA66B", "#E07A3F", "#D9534F", "#8E5BD9", "#D46BA3", "#2BA6B5", "#C9A227",
                         "#4C6A88", "#A7845A", "#7D8590", "#2E9E6A"]
}
