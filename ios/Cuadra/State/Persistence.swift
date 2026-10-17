import Foundation
import CuadraCore

/// Guarda el estado en Application Support con la protección de datos de iOS
/// (el archivo queda cifrado mientras el iPhone está bloqueado).
final class Persistence: @unchecked Sendable {
    static let shared = Persistence()

    private let queue = DispatchQueue(label: "cl.cuadra.persistence", qos: .utility)
    let fileURL: URL

    init(fileName: String = "finanzas.json") {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = base.appendingPathComponent("Cuadra", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent(fileName)
    }

    func load() -> FinanceSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? FinanceSnapshot.decoder().decode(FinanceSnapshot.self, from: data)
    }

    /// Escritura en segundo plano, en orden.
    func save(_ snapshot: FinanceSnapshot) {
        guard let data = try? FinanceSnapshot.encoder().encode(snapshot) else { return }
        let url = fileURL
        queue.async {
            try? data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        }
    }

    func delete() {
        let url = fileURL
        queue.async { try? FileManager.default.removeItem(at: url) }
    }
}
