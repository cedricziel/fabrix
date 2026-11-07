import FabrixCore
import Foundation

public struct FactoryConnection: Sendable {
    public var factory: Factory
    public var service: any FactoryService
    /// Whether a rejected or expiring Paperclip key can be replaced by signing in again.
    public var usesBoardKey: Bool

    public init(factory: Factory, service: any FactoryService, usesBoardKey: Bool = false) {
        self.factory = factory
        self.service = service
        self.usesBoardKey = usesBoardKey
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
    /// Paperclip issues a key once the user approves Fabrix in their browser.
    case browser
    case paperclip(apiKey: String)
    case oidc(issuer: URL, clientID: String)
    /// OIDC for the proxy, then browser sign-in for the Paperclip key behind it.
    case oidcWithBrowser(issuer: URL, clientID: String)
    case oidcWithPaperclip(issuer: URL, clientID: String, apiKey: String)

    public var usesBrowserSignIn: Bool {
        switch self {
        case .browser, .oidcWithBrowser: true
        case .paperclip, .oidc, .oidcWithPaperclip: false
        }
    }
}

/// Turns the onboarding form into a live factory and reopens saved ones.
/// Without one the form stays visible but disabled.
@MainActor
public protocol FactoryConnector: AnyObject, Sendable {
    /// - Parameters:
    ///   - headers: Extra headers for every request to the factory, such as a proxy access token.
    ///   - webAuthenticator: Shows the identity provider's login page for OIDC.
    func connect(
        baseURL: URL, auth: FactoryAuth, headers: [CustomHeader], webAuthenticator: (any WebAuthenticator)?
    ) async throws -> FactoryConnection

    /// Every factory saved on this device, in the order they were added.
    var factories: [Factory] { get }

    /// Bumped on every saved-factory change, including reconnecting with new credentials.
    var revision: Int { get }

    /// A saved factory from an earlier launch, or nil if it is gone.
    ///
    /// - Throws: `ReconnectNeeded` when the factory is saved but some of its secrets are missing.
    func restore(factoryID: Factory.ID) throws -> FactoryConnection?

    /// Deletes a saved factory and its credentials from this device.
    func forget(factoryID: Factory.ID) throws

    /// Creates a browser sign-in request for an auth whose `usesBrowserSignIn` is true.
    func startBrowserSignIn(
        baseURL: URL, auth: FactoryAuth, headers: [CustomHeader], webAuthenticator: (any WebAuthenticator)?
    ) async throws -> SignInChallenge

    /// A browser sign-in request that replaces the key of a saved factory.
    func startReauthentication(factoryID: Factory.ID) async throws -> SignInChallenge

    /// Waits for approval, then saves the factory. Cancel the calling task to stop waiting.
    func completeBrowserSignIn(_ challenge: SignInChallenge) async throws -> FactoryConnection
}

/// A saved factory that needs the connect form again, e.g. its custom header values were lost moving devices.
public struct ReconnectNeeded: Error, Equatable, Sendable {
    public var factory: Factory
    public var headerNames: [String]
    public var reason: String

    public init(factory: Factory, headerNames: [String], reason: String) {
        self.factory = factory
        self.headerNames = headerNames
        self.reason = reason
    }
}

struct ConnectForm: Equatable {
    enum Method: String, CaseIterable, Identifiable {
        case browser, paperclip, oidcWithBrowser, oidcWithPaperclip, oidc
        var id: Self { self }

        var usesAPIKey: Bool { self == .paperclip || self == .oidcWithPaperclip }
        var usesOIDC: Bool { self != .browser && self != .paperclip }
    }

    struct HeaderRow: Identifiable, Equatable {
        let id = UUID()
        var name = ""
        var value = ""

        var isBlank: Bool {
            name.trimmingCharacters(in: .whitespaces).isEmpty && value.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    enum Problem: Error, Equatable {
        case address, apiKey, issuer, clientID
    }

    var address = ""
    var method = Method.browser
    var apiKey = ""
    var issuer = ""
    var clientID = ""
    /// Checked by FabrixCore when connecting; the form only drops empty rows.
    var headers: [HeaderRow] = []

    func validated() throws(Problem) -> (baseURL: URL, auth: FactoryAuth, headers: [CustomHeader]) {
        guard let baseURL = Self.url(from: address) else { throw .address }
        let headers = headers.filter { !$0.isBlank }.map { CustomHeader(name: $0.name, value: $0.value) }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if method.usesAPIKey, key.isEmpty { throw .apiKey }
        guard method.usesOIDC else { return (baseURL, method == .browser ? .browser : .paperclip(apiKey: key), headers) }
        guard let issuerURL = Self.url(from: issuer) else { throw .issuer }
        let client = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !client.isEmpty else { throw .clientID }
        let auth: FactoryAuth = switch method {
        case .oidc: .oidc(issuer: issuerURL, clientID: client)
        case .oidcWithBrowser: .oidcWithBrowser(issuer: issuerURL, clientID: client)
        default: .oidcWithPaperclip(issuer: issuerURL, clientID: client, apiKey: key)
        }
        return (baseURL, auth, headers)
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

extension ConnectForm {
    /// The address and header names of a saved factory, with the values left for the user to enter.
    init(reconnecting request: ReconnectNeeded) {
        self.init(address: request.factory.baseURL.absoluteString)
        headers = request.headerNames.map { HeaderRow(name: $0) }
    }
}
