import SwiftUI
import WebKit
import CuadraCore

/// Conexiones bancarias vía el backend propio + agregador (Fintoc).
struct BankConnectionView: View {
    @Environment(FinanceStore.self) private var store
    @State private var serverAddress = ""
    @State private var appSecret = ""
    @State private var isRegistering = false
    @State private var showingConnect = false
    @State private var linkToRemove: BankLink?

    var body: some View {
        List {
            if !store.isDeviceRegistered {
                setupSection
            } else {
                Section {
                    ForEach(store.links) { link in
                        linkRow(link)
                            .swipeActions {
                                Button("Desconectar", role: .destructive) { linkToRemove = link }
                            }
                    }
                    Button {
                        showingConnect = true
                    } label: {
                        Label("Conectar un banco", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Bancos conectados")
                } footer: {
                    Text("Santander, Banco de Chile, BancoEstado, BCI, Itaú, Scotiabank, Security, BICE, Falabella y otros, según disponibilidad del conector. Tu clave del banco se ingresa en la ventana segura del conector: Cuadra nunca la ve ni la guarda.")
                }

                if !store.links.isEmpty {
                    Section {
                        Button {
                            Task { await store.sync() }
                        } label: {
                            HStack {
                                Text("Actualizar ahora")
                                Spacer()
                                if store.isSyncing { ProgressView() }
                            }
                        }
                        .disabled(store.isSyncing)
                    }
                }

                Section {
                    LabeledContent("Servidor", value: store.serverURL?.host() ?? "–")
                    Button("Cambiar servidor") {
                        serverAddress = store.serverURL?.absoluteString ?? ""
                        store.serverURL = nil
                        store.forgetDevice()
                    }
                } footer: {
                    Text("El servidor guarda cifradas las credenciales de acceso del conector y nunca almacena tus movimientos.")
                }
            }
        }
        .navigationTitle("Conexión bancaria")
        .sheet(isPresented: $showingConnect) {
            if let url = store.connectPageURL() {
                ConnectBankSheet(url: url) { exchangeToken in
                    showingConnect = false
                    Task { await store.completeConnection(exchangeToken: exchangeToken) }
                }
            }
        }
        .confirmationDialog("¿Desconectar \(linkToRemove?.institutionName ?? "el banco")?",
                            isPresented: Binding(get: { linkToRemove != nil }, set: { if !$0 { linkToRemove = nil } }),
                            titleVisibility: .visible) {
            if let link = linkToRemove {
                Button("Desconectar y conservar movimientos") {
                    Task { await store.removeLink(link, deleteData: false) }
                }
                Button("Desconectar y borrar sus movimientos", role: .destructive) {
                    Task { await store.removeLink(link, deleteData: true) }
                }
            }
        }
    }

    private var setupSection: some View {
        Section {
            TextField("Dirección del servidor", text: $serverAddress)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            SecureField("Clave de la app (APP_SECRET)", text: $appSecret)
            Button {
                isRegistering = true
                Task {
                    defer { isRegistering = false }
                    do {
                        try await store.registerDevice(serverAddress: serverAddress, appSecret: appSecret)
                        appSecret = ""
                        Haptics.success()
                    } catch {
                        store.errorMessage = error.localizedDescription
                        Haptics.error()
                    }
                }
            } label: {
                HStack {
                    Text("Vincular este iPhone")
                    Spacer()
                    if isRegistering { ProgressView() }
                }
            }
            .disabled(serverAddress.isEmpty || appSecret.count < 16 || isRegistering)
        } header: {
            Text("Configurar servidor")
        } footer: {
            Text("Para conectar bancos necesitas tu propio servidor de Cuadra (carpeta backend del proyecto), que guarda la llave secreta del conector fuera del teléfono. Mientras tanto puedes importar cartolas o registrar gastos a mano.")
        }
    }

    private func linkRow(_ link: BankLink) -> some View {
        let institution = Institution.known(link.institutionId)
        let accounts = store.accounts.filter { $0.linkId == link.id }
        return HStack(spacing: 12) {
            Text(String(institution.name.prefix(1)))
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: institution.colorHex), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(link.institutionName).font(.body.weight(.medium))
                Group {
                    switch link.status {
                    case .active:
                        if let date = link.lastSyncedAt {
                            Text("\(accounts.count) \(accounts.count == 1 ? "cuenta" : "cuentas") · actualizado \(date.formatted(.relative(presentation: .named)))")
                        } else {
                            Text("Conectado")
                        }
                    case .needsReconnect:
                        Text("Requiere reconectar").foregroundStyle(Theme.negative)
                    case .error:
                        Text(link.lastError ?? "Error al actualizar").foregroundStyle(Theme.warning)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
            Spacer()
            if link.status == .needsReconnect {
                Button("Reconectar") { showingConnect = true }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
            }
        }
    }
}

/// Muestra la página /connect del backend, que abre el widget del conector bancario.
struct ConnectBankSheet: View {
    let url: URL
    let onSuccess: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ConnectWebView(url: url) { message in
                switch message["type"] as? String ?? "" {
                case "success":
                    if let token = message["exchangeToken"] as? String { onSuccess(token) }
                case "exit":
                    dismiss()
                case "error":
                    errorText = message["message"] as? String ?? "No se pudo conectar."
                default:
                    break
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Conectar banco")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
            .alert("No se pudo conectar", isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
                Button("Cerrar", role: .cancel) { dismiss() }
            } message: {
                Text(errorText ?? "")
            }
        }
    }
}

struct ConnectWebView: UIViewRepresentable {
    let url: URL
    let onMessage: ([String: Any]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onMessage: onMessage) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.add(WeakMessageHandler(context.coordinator), name: "cuadra")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "cuadra")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        let onMessage: ([String: Any]) -> Void

        init(onMessage: @escaping ([String: Any]) -> Void) { self.onMessage = onMessage }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any] else { return }
            DispatchQueue.main.async { self.onMessage(body) }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            guard !Self.isCancellation(error) else { return }
            onMessage(["type": "error", "message": error.localizedDescription])
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            guard !Self.isCancellation(error) else { return }
            onMessage(["type": "error", "message": "No se pudo abrir la página de conexión: \(error.localizedDescription)"])
        }

        private static func isCancellation(_ error: Error) -> Bool {
            let nsError = error as NSError
            return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
        }

        /// El widget puede abrir ventanas nuevas (p. ej. la web del banco): se cargan en la misma vista.
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
            return nil
        }
    }

    /// Evita el ciclo de retención entre WKUserContentController y el coordinador.
    final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
        weak var target: WKScriptMessageHandler?

        init(_ target: WKScriptMessageHandler) { self.target = target }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            target?.userContentController(userContentController, didReceive: message)
        }
    }
}
