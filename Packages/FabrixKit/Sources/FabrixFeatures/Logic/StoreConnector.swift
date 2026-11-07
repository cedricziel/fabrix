import FabrixCore
import Foundation
#if canImport(UIKit)
    import UIKit
#endif

/// Connects through FabrixCore's `FactoryStore`, which validates credentials against the
/// server and keeps factories in UserDefaults and their secrets in the Keychain.
@MainActor
public final class StoreConnector: FactoryConnector {
    /// Where the identity provider sends the user back. ASWebAuthenticationSession catches the
    /// custom scheme, so the app needs no URL-scheme registration.
    static let redirectURI = URL(string: "com.cedricziel.fabrix:/oauth/callback")!
    static let callbackScheme = redirectURI.scheme!
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
        return try connection(for: factory)
    }

    public var factories: [Factory] {
        store.factories
    }

    public var revision: Int {
        store.revision
    }

    public func restore(factoryID: Factory.ID) throws -> FactoryConnection? {
        guard let factory = store.factories.first(where: { $0.id == factoryID }) else { return nil }
        do {
            return try connection(for: factory)
        } catch let error as PaperclipError {
            guard case let .missingHeaderValues(names) = error else { return nil }
            throw ReconnectNeeded(factory: factory, headerNames: names, reason: error.localizedDescription, auth: store.auth(for: factory))
        } catch {
            return nil
        }
    }

    public func startBrowserSignIn(
        baseURL: URL, auth: FactoryAuth, headers: [CustomHeader], webAuthenticator: (any WebAuthenticator)?
    ) async throws -> SignInChallenge {
        let (configuration, _) = Self.configuration(for: auth)
        return try await store.startSignIn(
            url: baseURL, clientName: Self.clientName, frontDoor: configuration.oidc, headers: headers, webAuthenticator: webAuthenticator
        )
    }

    public func startReauthentication(factoryID: Factory.ID, webAuthenticator: (any WebAuthenticator)?) async throws -> SignInChallenge {
        try await store.startReauthentication(of: savedFactory(factoryID), clientName: Self.clientName, webAuthenticator: webAuthenticator)
    }

    public func signInAgainToIdentityProvider(factoryID: Factory.ID, webAuthenticator: any WebAuthenticator) async throws -> FactoryConnection {
        try await connection(for: store.signInAgainToIdentityProvider(of: savedFactory(factoryID), webAuthenticator: webAuthenticator))
    }

    private func savedFactory(_ id: Factory.ID) throws -> Factory {
        guard let factory = store.factories.first(where: { $0.id == id }) else { throw PaperclipError.notFound(nil) }
        return factory
    }

    public func cancelBrowserSignIn(_ challenge: SignInChallenge) async throws {
        try await store.cancelSignIn(challenge)
    }

    public func completeBrowserSignIn(_ challenge: SignInChallenge) async throws -> FactoryConnection {
        let factory = try await store.completeSignIn(challenge)
        return try connection(for: factory)
    }

    /// How the request appears on Paperclip's approval page. Paperclip names the issued key after it,
    /// so users can tell this device's key apart in `paperclipai token board list` and revoke it.
    static var clientName: String {
        #if os(macOS)
            let device = Host.current().localizedName ?? "Mac"
        #else
            let device = UIDevice.current.name
        #endif
        return "Fabrix (\(device.prefix(100)))"
    }

    public func forget(factoryID: Factory.ID) throws {
        guard let factory = store.factories.first(where: { $0.id == factoryID }) else { return }
        store.remove(factory)
    }

    static func configuration(for auth: FactoryAuth) -> (FactoryAuthConfiguration, boardKey: String?) {
        switch auth {
        case .browser:
            (.boardKey, nil)
        case let .paperclip(apiKey):
            (.boardKey, apiKey)
        case let .oidcWithBrowser(issuer, clientID):
            (proxyInFrontOfPaperclip(issuer: issuer, clientID: clientID), nil)
        case let .oidc(issuer, clientID):
            (FactoryAuthConfiguration(oidc: OIDCSettings(issuer: issuer, clientID: clientID, redirectURI: redirectURI)), nil)
        case let .oidcWithPaperclip(issuer, clientID, apiKey):
            (proxyInFrontOfPaperclip(issuer: issuer, clientID: clientID), apiKey)
        }
    }

    private static func proxyInFrontOfPaperclip(issuer: URL, clientID: String) -> FactoryAuthConfiguration {
        FactoryAuthConfiguration(
            oidc: OIDCSettings(issuer: issuer, clientID: clientID, redirectURI: redirectURI, tokenHeader: proxyTokenHeader),
            usesBoardKey: true
        )
    }

    private func connection(for factory: Factory) throws -> FactoryConnection {
        let auth = store.auth(for: factory)
        return try FactoryConnection(factory: factory, service: store.service(for: factory), usesBoardKey: auth.usesBoardKey, usesOIDC: auth.oidc != nil)
    }
}
