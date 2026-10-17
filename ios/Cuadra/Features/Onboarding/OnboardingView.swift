import SwiftUI
import CuadraCore

struct OnboardingView: View {
    @Environment(FinanceStore.self) private var store
    @State private var step = 0
    @State private var profile = UserProfile()
    @State private var income: Pesos?

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0: welcome
                case 1: profileForm
                default: start
                }
            }
            .animation(.snappy, value: step)
        }
    }

    // MARK: Paso 1

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                Text("Cuadra")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("Tus finanzas, claras y en orden.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 20) {
                feature("building.columns", "Conecta tus bancos", "Santander, Banco de Chile, BancoEstado, BCI y más, o importa tu cartola.")
                feature("chart.pie", "Entiende tus gastos", "Categorías automáticas y estadísticas por día, semana o mes.")
                feature("sparkle", "Recibe consejos", "Un asesor que analiza tus hábitos y te propone un plan.")
                feature("lock", "Privado", "Tus datos se guardan solo en este iPhone, protegidos con Face ID.")
            }
            Spacer()
            Button("Comenzar") { step = 1 }
                .buttonStyle(.primary)
        }
        .padding(24)
    }

    private func feature(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Paso 2

    private var profileForm: some View {
        Form {
            Section {
                TextField("Tu nombre", text: $profile.name)
                    .textContentType(.givenName)
            } header: {
                Text("Sobre ti")
            }

            Section {
                PesosField(title: "Ingreso mensual líquido (opcional)", value: $income)
            } footer: {
                Text("Si lo dejas en blanco, lo calcularé a partir de tus movimientos.")
            }

            Section("Tu objetivo principal") {
                Picker("Objetivo", selection: $profile.goal) {
                    ForEach(FinancialGoal.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Tu hogar") {
                Picker("Vivienda", selection: $profile.housing) {
                    ForEach(HousingSituation.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                Stepper("Personas a tu cargo: \(profile.dependents)", value: $profile.dependents, in: 0...10)
            }

            Section {
                Picker("Distribución", selection: $profile.splitRule) {
                    ForEach(SplitRule.presets, id: \.self) { rule in
                        Text(rule.name).tag(rule)
                    }
                }
            } header: {
                Text("Cómo repartir tus ingresos")
            } footer: {
                Text("Necesidades / deseos / ahorro. La regla 50/30/20 es un buen punto de partida; 70/20/10 se adapta mejor si tus gastos fijos son altos.")
            }
        }
        .navigationTitle("Tu perfil")
        .safeAreaInset(edge: .bottom) {
            Button("Continuar") {
                profile.declaredMonthlyIncome = income
                step = 2
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Theme.background)
        }
    }

    // MARK: Paso 3

    private var start: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Cómo quieres empezar?")
                .font(.largeTitle.weight(.bold))
                .padding(.top, 24)
            Text("Puedes cambiarlo cuando quieras desde Ajustes.")
                .foregroundStyle(.secondary)
            Spacer()
            option("building.columns.fill", "Conectar mi banco", "Te llevará a Ajustes para conectar tu primera cuenta.") {
                store.saveProfile(profile)
            }
            option("doc.text.fill", "Importar una cartola", "Descarga el CSV desde la web de tu banco y agrégalo en Ajustes.") {
                store.saveProfile(profile)
            }
            option("wand.and.stars", "Probar con datos de ejemplo", "Seis meses de movimientos ficticios para recorrer la app.") {
                store.loadDemo()
                var demoProfile = profile
                if demoProfile.name.isEmpty { demoProfile.name = "Demo" }
                store.saveProfile(demoProfile)
            }
            Spacer()
        }
        .padding(24)
    }

    private func option(_ symbol: String, _ title: String, _ subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .foregroundStyle(Color.primary)
            .card()
        }
        .buttonStyle(.plain)
    }
}
