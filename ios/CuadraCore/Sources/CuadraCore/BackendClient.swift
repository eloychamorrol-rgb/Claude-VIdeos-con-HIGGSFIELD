import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum BackendError: Error, Equatable, LocalizedError {
    case notConfigured
    case unauthorized
    case linkNeedsReconnect(String)
    case server(Int, String)
    case network(String)
    case decoding(String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Configura la dirección del servidor en Ajustes › Conexión bancaria."
        case .unauthorized:
            return "La sesión con el servidor expiró. Vuelve a conectar el dispositivo en Ajustes."
        case .linkNeedsReconnect(let message):
            return message.isEmpty ? "El banco pidió volver a ingresar tus credenciales. Reconecta la cuenta." : message
        case .server(let status, let message):
            return message.isEmpty ? "El servidor respondió con un error (\(status))." : message
        case .network(let message):
            return "No hay conexión con el servidor. \(message)"
        case .decoding:
            return "La respuesta del servidor no tiene el formato esperado."
        }
    }
}

/// Permite reemplazar la red en pruebas.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public enum BackendJSON {
    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = BankMapper.parseISO(raw) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Fecha inválida: \(raw)")
            }
            return date
        }
        return decoder
    }
}

/// Cliente del backend propio (que a su vez habla con el agregador bancario).
public struct BackendClient: Sendable {
    public let baseURL: URL
    public let token: String?
    let transport: HTTPTransport

    public init(baseURL: URL, token: String?, transport: HTTPTransport) {
        self.baseURL = baseURL
        self.token = token
        self.transport = transport
    }

    struct RegisterResponse: Decodable { let token: String }
    struct LinkResponse: Decodable { let link: RemoteLink }
    struct LinksResponse: Decodable { let links: [RemoteLink] }
    struct AccountsResponse: Decodable { let accounts: [RemoteAccount] }
    struct MovementsResponse: Decodable { let movements: [RemoteMovement] }
    struct ErrorResponse: Decodable { let error: String?; let code: String? }

    /// Registra este dispositivo y devuelve un token propio (se guarda en el Llavero).
    public func register(appSecret: String) async throws -> String {
        let response: RegisterResponse = try await request("POST", "v1/devices", body: ["appSecret": appSecret], authenticated: false)
        return response.token
    }

    public func exchange(exchangeToken: String) async throws -> RemoteLink {
        let response: LinkResponse = try await request("POST", "v1/links", body: ["exchangeToken": exchangeToken])
        return response.link
    }

    public func links() async throws -> [RemoteLink] {
        let response: LinksResponse = try await request("GET", "v1/links")
        return response.links
    }

    public func deleteLink(id: String) async throws {
        let _: [String: Bool] = try await request("DELETE", "v1/links/\(id)")
    }

    public func accounts(linkId: String) async throws -> [RemoteAccount] {
        let response: AccountsResponse = try await request("GET", "v1/links/\(linkId)/accounts")
        return response.accounts
    }

    public func movements(linkId: String, accountId: String, since: Date?) async throws -> [RemoteMovement] {
        var query: [URLQueryItem] = []
        if let since {
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!
            let c = utc.dateComponents([.year, .month, .day], from: since)
            let pad: (Int) -> String = { $0 < 10 ? "0\($0)" : "\($0)" }
            query.append(URLQueryItem(name: "since", value: "\(c.year ?? 2000)-\(pad(c.month ?? 1))-\(pad(c.day ?? 1))"))
        }
        let response: MovementsResponse = try await request("GET", "v1/links/\(linkId)/accounts/\(accountId)/movements", query: query)
        return response.movements
    }

    /// URL de la página que abre el widget del agregador dentro de la app.
    public var connectPageURL: URL { baseURL.appendingPathComponent("connect") }

    // MARK: Infraestructura

    func request<Response: Decodable>(_ method: String, _ path: String, query: [URLQueryItem] = [],
                                      body: [String: String]? = nil, authenticated: Bool = true) async throws -> Response {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw BackendError.notConfigured
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw BackendError.notConfigured }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authenticated {
            guard let token, !token.isEmpty else { throw BackendError.unauthorized }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch let error as BackendError {
            throw error
        } catch {
            throw BackendError.network(error.localizedDescription)
        }

        guard (200..<300).contains(response.statusCode) else {
            let payload = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let message = payload?.error ?? ""
            switch (response.statusCode, payload?.code) {
            case (401, _): throw BackendError.unauthorized
            case (_, "link_needs_reconnect"?): throw BackendError.linkNeedsReconnect(message)
            default: throw BackendError.server(response.statusCode, message)
            }
        }
        do {
            return try BackendJSON.decoder().decode(Response.self, from: data)
        } catch {
            throw BackendError.decoding(String(describing: error))
        }
    }
}
