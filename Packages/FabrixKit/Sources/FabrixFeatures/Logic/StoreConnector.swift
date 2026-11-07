import FabrixCore
import Foundation

/// Connects through FabrixCore's `FactoryStore`, which validates credentials against the
/// server and keeps factories in UserDefaults and their secrets in the Keychain.
@MainActor
public final class StoreConnector: FactoryConnector {
    /// Where the identity provider sends the user back. ASWebAuthenticationSession catches the
    /// custom scheme, so the app needs no URL-scheme registration.
    static let redirectURI = URL(string: "com.cedricziel.fabrix:/oauth/callback")!
    /// With a board key in `Authorization`, the proxy's OIDC token goes in this header instead.
    static let proxyTokenHeader = "X-Forwarded-Access-Token"

    private let store: FactoryStore

    public init(store: FactoryStore = FactoryStore()) {
        self.store = store
    }

    public func connect(
        baseURL: URL, auth: FactoryAuth, headers: [CustomHeader], webAuthenticator: (any WebAuthenticator)?
    ) async throws -> FactoryConnection {
        let (configuration, boardKey) = Self.configuration(for: auth)
        let factory = try await store.connect(
            url: baseURL, auth: configuration, boardKey: boardKey, headers: headers, webAuthenticator: webAuthenticator
        )
        return try FactoryConnection(factory: factory, service: store.service(for: factory))
    }

    public func restore(factoryID: Factory.ID) -> FactoryConnection? {
        guard let factory = store.factories.first(where: { $0.id == factoryID }),
              let service = try? store.service(for: factory)
        else { return nil }
        return FactoryConnection(factory: factory, service: service)
    }

    public func forget(factoryID: Factory.ID) throws {
        guard let factory = store.factories.first(where: { $0.id == factoryID }) else { return }
        try store.remove(factory)
    }

    static func configuration(for auth: FactoryAuth) -> (FactoryAuthConfiguration, boardKey: String?) {
        switch auth {
        case let .paperclip(apiKey):
            (.boardKey, apiKey)
        case let .oidc(issuer, clientID):
            (FactoryAuthConfiguration(oidc: OIDCSettings(issuer: issuer, clientID: clientID, redirectURI: redirectURI)), nil)
        case let .oidcWithPaperclip(issuer, clientID, apiKey):
            (
                FactoryAuthConfiguration(
                    oidc: OIDCSettings(issuer: issuer, clientID: clientID, redirectURI: redirectURI, tokenHeader: proxyTokenHeader),
                    usesBoardKey: true
                ),
                apiKey
            )
        }
    }
}
