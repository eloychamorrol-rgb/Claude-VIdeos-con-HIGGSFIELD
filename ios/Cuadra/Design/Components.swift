import SwiftUI
import CuadraCore

// SwiftUI ya tiene un tipo `Transaction` y el runtime de Objective-C uno `Category`;
// estos alias evitan ambigüedades en toda la app.
typealias Movement = CuadraCore.Transaction
typealias FinanceCategory = CuadraCore.Category

/// Ícono redondeado de categoría (estilo Ajustes de iOS).
struct CategoryIcon: View {
    let category: FinanceCategory
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(category.color.gradient, in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Monto en pesos con color según signo.
struct AmountText: View {
    let amount: Pesos
    var style: Font.TextStyle = .body
    var weight: Font.Weight = .semibold
    var signed = true
    var colored = true

    var body: some View {
        Text(MoneyFormat.clp(amount, signed: signed))
            .font(Theme.amountFont(style, weight: weight))
            .foregroundStyle(colored && amount > 0 ? Theme.positive : Color.primary)
            .contentTransition(.numericText(value: Double(amount)))
    }
}

struct SectionTitle: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.weight(.semibold))
            Spacer()
            if let trailing {
                Text(trailing).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
}

struct ProgressBar: View {
    let value: Double
    var tint: Color = Theme.ink
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule().fill(tint)
                    .frame(width: max(height, proxy.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
        .accessibilityValue(MoneyFormat.percent(value))
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
    }
}

/// Selector de período con navegación anterior/siguiente.
struct PeriodSelector: View {
    @Binding var kind: PeriodKind
    @Binding var period: Period
    let calendar: FinanceCalendar
    @State private var showingCustom = false
    @State private var customStart = Date()
    @State private var customEnd = Date()

    var body: some View {
        VStack(spacing: 12) {
            Picker("Período", selection: $kind) {
                ForEach(PeriodKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Button { step(-1) } label: {
                    Image(systemName: "chevron.left").frame(width: 36, height: 36)
                }
                .accessibilityLabel("Período anterior")
                Spacer()
                Button {
                    if kind == .custom {
                        customStart = period.start
                        customEnd = calendar.adding(days: -1, to: period.end)
                        showingCustom = true
                    }
                } label: {
                    Text(calendar.title(for: period))
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                }
                .disabled(kind != .custom)
                Spacer()
                Button { step(1) } label: {
                    Image(systemName: "chevron.right").frame(width: 36, height: 36)
                }
                .disabled(period.end > Date())
                .accessibilityLabel("Período siguiente")
            }
            .tint(Theme.ink)
        }
        .onChange(of: kind) { _, newKind in
            if newKind == .custom {
                customStart = calendar.adding(days: -29, to: Date())
                customEnd = Date()
                period = calendar.customPeriod(from: customStart, through: customEnd)
                showingCustom = true
            } else {
                period = calendar.period(newKind, containing: Date())
            }
        }
        .sheet(isPresented: $showingCustom) {
            NavigationStack {
                Form {
                    DatePicker("Desde", selection: $customStart, in: ...Date(), displayedComponents: .date)
                    DatePicker("Hasta", selection: $customEnd, in: ...Date(), displayedComponents: .date)
                }
                .environment(\.locale, Locale(identifier: "es_CL"))
                .navigationTitle("Rango personalizado")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Listo") {
                            period = calendar.customPeriod(from: customStart, through: customEnd)
                            showingCustom = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func step(_ direction: Int) {
        Haptics.tap()
        withAnimation(.snappy) { period = calendar.shifted(period, by: direction) }
    }
}

/// Fila de movimiento reutilizable.
struct MovementRow: View {
    let movement: Movement
    let category: FinanceCategory
    var showDate = false
    let calendar: FinanceCalendar

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: category)
            VStack(alignment: .leading, spacing: 2) {
                Text(movement.merchant)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(category.name)
                    if showDate {
                        Text("·")
                        Text(calendar.shortDate(movement.date))
                    } else if movement.hasTime {
                        Text("·")
                        Text(calendar.timeString(movement.date))
                    }
                    if movement.isPending {
                        Text("· Pendiente")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer(minLength: 8)
            AmountText(amount: movement.amount, style: .body, weight: .medium)
                .opacity(category.group == .transfer ? 0.5 : 1)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
