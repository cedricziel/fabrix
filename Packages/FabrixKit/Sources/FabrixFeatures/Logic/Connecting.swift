import FabrixCore
import Foundation

public struct FactoryConnection: Sendable {
    public var factory: Factory
    public var service: any FactoryService

    public init(factory: Factory, service: any FactoryService) {
        self.factory = factory
        self.service = service
    }

    public static func demo() -> FactoryConnection {
        FactoryConnection(
            factory: Factory(id: "demo", name: "Demo factory", baseURL: URL(string: "https://demo.invalid")!, isOnline: true),
            service: DemoFactoryService()
        )
    }
}

/// How Fabrix signs in to one factory. OIDC sits in front of Paperclip as a reverse proxy,
/// optionally with a Paperclip key behind it.
public enum FactoryAuth: Hashable, Sendable {
    case paperclip(apiKey: String)
    case oidc(issuer: URL, clientID: String)
    case oidcWithPaperclip(issuer: URL, clientID: String, apiKey: String)
}

/// Turns the onboarding form into a live factory. The app passes one in once server
/// connections ship; without it the form stays visible but disabled.
public protocol FactoryConnector: Sendable {
    func connect(baseURL: URL, auth: FactoryAuth) async throws -> FactoryConnection
}

struct ConnectForm: Equatable {
    enum Method: String, CaseIterable, Identifiable {
        case paperclip, oidc, oidcWithPaperclip
        var id: Self { self }

        var usesAPIKey: Bool { self != .oidc }
        var usesOIDC: Bool { self != .paperclip }
    }

    enum Problem: Error, Equatable {
        case address, apiKey, issuer, clientID
    }

    var address = ""
    var method = Method.paperclip
    var apiKey = ""
    var issuer = ""
    var clientID = ""

    func validated() throws(Problem) -> (baseURL: URL, auth: FactoryAuth) {
        guard let baseURL = Self.url(from: address) else { throw .address }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if method.usesAPIKey, key.isEmpty { throw .apiKey }
        guard method.usesOIDC else { return (baseURL, .paperclip(apiKey: key)) }
        guard let issuerURL = Self.url(from: issuer) else { throw .issuer }
        let client = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !client.isEmpty else { throw .clientID }
        return method == .oidc
            ? (baseURL, .oidc(issuer: issuerURL, clientID: client))
            : (baseURL, .oidcWithPaperclip(issuer: issuerURL, clientID: client, apiKey: key))
    }

    static func url(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: withScheme),
              ["http", "https"].contains(url.scheme?.lowercased()),
              url.host()?.isEmpty == false
        else { return nil }
        return url
    }
}
