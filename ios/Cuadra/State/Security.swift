import Foundation
import LocalAuthentication
import Observation
import Security

/// Acceso mínimo al Llavero para el token del backend.
enum Keychain {
    private static let service = "cl.cuadra.app"

    static func set(_ value: String?, for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        guard let value, let data = value.data(using: .utf8) else { return }
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

/// Bloqueo con Face ID / Touch ID / código del iPhone.
@MainActor
@Observable
final class AppLock {
    private(set) var isLocked = false
    private(set) var isEnabled: Bool
    private var isAuthenticating = false

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "lockEnabled")
    }

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: "lockEnabled")
        isLocked = isEnabled
    }

    var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "código del iPhone"
        }
    }

    func lock() {
        if isEnabled { isLocked = true }
    }

    func unlock() async {
        // Evita dos solicitudes de Face ID simultáneas (al abrir la app y al mostrarse la pantalla de bloqueo).
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Sin código configurado no hay forma de autenticar: no se bloquea al usuario fuera de sus datos.
            isLocked = false
            return
        }
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                           localizedReason: "Desbloquea para ver tus finanzas")
            if success { isLocked = false }
        } catch {
            isLocked = true
        }
    }
}
