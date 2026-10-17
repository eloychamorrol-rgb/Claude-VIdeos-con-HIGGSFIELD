import SwiftUI
import CuadraCore

@main
struct CuadraApp: App {
    @State private var store = FinanceStore()
    @State private var lock = AppLock()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(lock)
                .environment(\.locale, Locale(identifier: "es_CL"))
                .tint(Theme.ink)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                lock.lock()
            case .active:
                if lock.isLocked { Task { await lock.unlock() } }
                store.refreshDerivedData()
                Task { await store.syncIfStale() }
            default:
                break
            }
        }
    }
}

struct RootView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(AppLock.self) private var lock
    @State private var selection = Tab.home

    enum Tab: Hashable { case home, movements, analysis, advisor, settings }

    var body: some View {
        ZStack {
            if store.hasProfile {
                TabView(selection: $selection) {
                    HomeView(selection: $selection)
                        .tabItem { Label("Inicio", systemImage: "house") }
                        .tag(Tab.home)
                    TransactionsView()
                        .tabItem { Label("Movimientos", systemImage: "list.bullet") }
                        .tag(Tab.movements)
                    AnalysisView()
                        .tabItem { Label("Análisis", systemImage: "chart.pie") }
                        .tag(Tab.analysis)
                    AdvisorView()
                        .tabItem { Label("Asesor", systemImage: "sparkle") }
                        .tag(Tab.advisor)
                    SettingsView()
                        .tabItem { Label("Ajustes", systemImage: "gearshape") }
                        .tag(Tab.settings)
                }
            } else {
                OnboardingView()
            }

            if lock.isLocked {
                LockView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: lock.isLocked)
        .alert("Algo salió mal", isPresented: Binding(get: { store.errorMessage != nil },
                                                      set: { if !$0 { store.errorMessage = nil } })) {
            Button("Entendido", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .overlay(alignment: .top) {
            if let info = store.infoMessage {
                ToastView(text: info)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: info) {
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation { store.infoMessage = nil }
                    }
            }
        }
        .animation(.snappy, value: store.infoMessage)
    }
}

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

struct LockView: View {
    @Environment(AppLock.self) private var lock

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThickMaterial).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 34, weight: .medium))
                Text("Cuadra está bloqueada")
                    .font(.headline)
                Button("Desbloquear con \(lock.biometryName)") {
                    Task { await lock.unlock() }
                }
                .buttonStyle(.primary)
                .frame(maxWidth: 280)
            }
        }
        .task { await lock.unlock() }
    }
}
