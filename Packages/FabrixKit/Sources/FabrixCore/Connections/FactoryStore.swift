import Foundation
import Observation

/// The Paperclip servers this device is connected to. Factory records and their auth
/// configuration live in `UserDefaults`; secrets live in a `CredentialStore` (the Keychain by default).
@MainActor
@Observable
public final class FactoryStore {
    public private(set) var factories: [Factory]

    @ObservationIgnored private var authConfigurations: [Factory.ID: FactoryAuthConfiguration]
    /// One provider per factory, so concurrent services share a single token refresh.
    @ObservationIgnored private var oidcProviders: [Factory.ID: OIDCAuthProvider] = [:]
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let credentials: any CredentialStore
    @ObservationIgnored private let session: URLSession
    private static let defaultsKey = "fabrix.factories"

    private struct StoredFactory: Codable {
        var factory: Factory
        var auth: FactoryAuthConfiguration
    }

    public init(defaults: UserDefaults = .standard, credentials: any CredentialStore = KeychainCredentialStore(), session: URLSession = .shared) {
        self.defaults = defaults
        self.credentials = credentials
        self.session = session
        let stored = defaults.data(forKey: Self.defaultsKey)
            .flatMap { try? JSONDecoder().decode([StoredFactory].self, from: $0) } ?? []
        factories = stored.map(\.factory)
        authConfigurations = Dictionary(stored.map { ($0.factory.id, $0.auth) }, uniquingKeysWith: { _, last in last })
    }

    /// Connects with a board API key, or without credentials when `credential` is nil or blank.
    @discardableResult
    public func connect(url: URL, credential: String?, name: String? = nil) async throws -> Factory {
        let key = Self.trimmed(credential)
        return try await connect(url: url, auth: key == nil ? .none : .boardKey, boardKey: key, name: name, webAuthenticator: nil)
    }

    /// Signs in as `auth` describes, checks the result against the server, then saves the factory.
    ///
    /// - Parameters:
    ///   - url: Server address. A trailing `/api` is ignored.
    ///   - auth: Which layers to use. OIDC sign-in runs first when `auth.oidc` is set.
    ///   - boardKey: The Paperclip board API key; required when `auth.usesBoardKey`, ignored otherwise.
    ///   - name: Display name. Defaults to the server's host, or the saved name when reconnecting.
    ///   - webAuthenticator: Shows the OIDC login page; required when `auth.oidc` is set.
    /// - Returns: The saved factory. Connecting to a server that is already saved updates it in place.
    /// - Throws: `PaperclipError` (`.invalidServerURL`, `.invalidAuthConfiguration`, `.unauthorized`, …),
    ///   `OIDCError` from the identity provider, or `KeychainError`. Nothing is saved when it throws.
    @discardableResult
    public func connect(
        url: URL, auth: FactoryAuthConfiguration, boardKey: String?, name: String? = nil,
        webAuthenticator: (any WebAuthenticator)?
    ) async throws -> Factory {
        let baseURL = try PaperclipClient.serverURL(url)
        try auth.validate()
        let key = auth.usesBoardKey ? Self.trimmed(boardKey) : nil
        if auth.usesBoardKey, key == nil {
            throw PaperclipError.invalidAuthConfiguration("Enter a board API key.")
        }

        var oidcTokens: OIDCTokens?
        if let oidc = auth.oidc {
            oidcTokens = try await signInToIdentityProvider(oidc, for: baseURL, webAuthenticator: webAuthenticator)
        }
        return try await validateAndSave(baseURL: baseURL, auth: auth, boardKey: key, oidcTokens: oidcTokens, name: name)
    }

    /// Starts a browser sign-in. Show `approvalURL` to the user, then call `completeSignIn`.
    ///
    /// - Parameters:
    ///   - frontDoor: OIDC settings for a reverse proxy in front of Paperclip. Its `tokenHeader` must not be
    ///     `Authorization`, because the issued board key goes there. Sign-in to the identity provider runs first.
    ///   - webAuthenticator: Shows the OIDC login page; required with `frontDoor`.
    public func startSignIn(
        url: URL, clientName: String, frontDoor: OIDCSettings? = nil, webAuthenticator: (any WebAuthenticator)? = nil
    ) async throws -> SignInChallenge {
        let baseURL = try PaperclipClient.serverURL(url)
        var oidcTokens: OIDCTokens?
        if let frontDoor {
            try FactoryAuthConfiguration(oidc: frontDoor, usesBoardKey: true).validate()
            oidcTokens = try await signInToIdentityProvider(frontDoor, for: baseURL, webAuthenticator: webAuthenticator)
        }
        let staged = try stage(frontDoor, oidcTokens)
        var challenge = try await PaperclipClient(baseURL: baseURL, auth: Self.chain(oidc: staged?.provider, boardKey: nil), session: session)
            .startSignIn(clientName: clientName)
        challenge.frontDoor = frontDoor
        challenge.oidcTokens = try staged?.store.load()
        return challenge
    }

    /// Waits until the user approves the sign-in in the browser, then connects with the issued key
    /// (behind the challenge's OIDC front door, if any). Cancel the calling task to stop waiting.
    ///
    /// - Throws: `PaperclipError.signInCancelled` or `.signInExpired` when the challenge ends without approval.
    @discardableResult
    public func completeSignIn(_ challenge: SignInChallenge, name: String? = nil) async throws -> Factory {
        let staged = try stage(challenge.frontDoor, challenge.oidcTokens)
        let client = PaperclipClient(baseURL: challenge.serverURL, auth: Self.chain(oidc: staged?.provider, boardKey: nil), session: session)
        while true {
            switch try await client.signInStatus(challenge) {
            case .approved:
                return try await validateAndSave(
                    baseURL: challenge.serverURL, auth: FactoryAuthConfiguration(oidc: challenge.frontDoor, usesBoardKey: true),
                    boardKey: challenge.boardAPIToken, oidcTokens: staged?.store.load(), name: name
                )
            case .cancelled: throw PaperclipError.signInCancelled
            case .expired: throw PaperclipError.signInExpired
            case .pending: try await Task.sleep(for: challenge.pollInterval)
            }
        }
    }

    /// Checks the Paperclip transport first, so the user isn't sent through a login that can't be used.
    private func signInToIdentityProvider(
        _ settings: OIDCSettings, for baseURL: URL, webAuthenticator: (any WebAuthenticator)?
    ) async throws -> OIDCTokens {
        guard PaperclipClient.allowsCredentials(to: baseURL) else { throw PaperclipError.insecureConnection }
        guard let webAuthenticator else {
            throw PaperclipError.invalidAuthConfiguration("OIDC sign-in needs a web authenticator.")
        }
        return try await OIDCFlow(settings: settings, session: session).signIn(using: webAuthenticator)
    }

    /// An OIDC provider over in-memory tokens, for requests made before the factory is saved.
    private func stage(_ settings: OIDCSettings?, _ tokens: OIDCTokens?) throws -> (provider: OIDCAuthProvider, store: OIDCTokenStore)? {
        guard let settings, let tokens else { return nil }
        let store = OIDCTokenStore(credentials: InMemoryCredentialStore(), account: "candidate")
        try store.save(tokens)
        return (OIDCAuthProvider(settings: settings, tokens: store, session: session), store)
    }

    /// Checks the credentials against the server, then writes secrets and the record. Nothing is saved when it throws.
    private func validateAndSave(
        baseURL: URL, auth: FactoryAuthConfiguration, boardKey: String?, oidcTokens: OIDCTokens?, name: String?
    ) async throws -> Factory {
        let staged = try stage(auth.oidc, oidcTokens)
        _ = try await PaperclipClient(baseURL: baseURL, auth: Self.chain(oidc: staged?.provider, boardKey: boardKey), session: session)
            .boardSession()
        // Validation may have refreshed (and rotated) the tokens; keep the latest ones.
        let tokensToSave = try staged?.store.load()

        let existing = factories.firstIndex { $0.baseURL == baseURL }
        let factory = Factory(
            id: existing.map { factories[$0].id } ?? UUID().uuidString,
            name: name ?? existing.map { factories[$0].name } ?? baseURL.host() ?? baseURL.absoluteString,
            baseURL: baseURL,
            isOnline: true
        )
        let previousKey = try credentials.credential(for: factory.id)
        try credentials.setCredential(boardKey, for: factory.id)
        do {
            try oidcTokenStore(factory.id).save(tokensToSave)
        } catch {
            try? credentials.setCredential(previousKey, for: factory.id)
            throw error
        }
        oidcProviders[factory.id] = nil
        authConfigurations[factory.id] = auth
        if let existing {
            factories[existing] = factory
        } else {
            factories.append(factory)
        }
        save()
        return factory
    }

    /// The saved auth configuration, or `.none` for an unknown factory.
    public func auth(for factory: Factory) -> FactoryAuthConfiguration {
        authConfigurations[factory.id] ?? .none
    }

    /// Forgets the factory and deletes its board key and OIDC tokens.
    public func remove(_ factory: Factory) throws {
        try credentials.setCredential(nil, for: factory.id)
        try oidcTokenStore(factory.id).save(nil)
        oidcProviders[factory.id] = nil
        authConfigurations[factory.id] = nil
        factories.removeAll { $0.id == factory.id }
        save()
    }

    /// A live `FactoryService` for a saved factory, authenticated with its stored configuration.
    public func service(for factory: Factory) throws -> PaperclipFactoryService {
        let auth = auth(for: factory)
        let key = auth.usesBoardKey ? try credentials.credential(for: factory.id) : nil
        let client = PaperclipClient(baseURL: factory.baseURL, auth: Self.chain(oidc: oidcProvider(for: factory, settings: auth.oidc), boardKey: key), session: session)
        return PaperclipFactoryService(client: client)
    }

    private func oidcProvider(for factory: Factory, settings: OIDCSettings?) -> OIDCAuthProvider? {
        guard let settings else { return nil }
        if let cached = oidcProviders[factory.id] {
            return cached
        }
        let provider = OIDCAuthProvider(settings: settings, tokens: oidcTokenStore(factory.id), session: session)
        oidcProviders[factory.id] = provider
        return provider
    }

    private static func chain(oidc: OIDCAuthProvider?, boardKey: String?) -> any AuthProvider {
        let layers: [(any AuthProvider)?] = [oidc, boardKey.map { BearerTokenAuth(token: $0) }]
        return ChainedAuth(layers.compactMap(\.self))
    }

    private func oidcTokenStore(_ factoryID: Factory.ID) -> OIDCTokenStore {
        OIDCTokenStore(credentials: credentials, account: "\(factoryID).oidc")
    }

    private static func trimmed(_ secret: String?) -> String? {
        guard let secret = secret?.trimmingCharacters(in: .whitespacesAndNewlines), !secret.isEmpty else { return nil }
        return secret
    }

    private func save() {
        let stored = factories.map { StoredFactory(factory: $0, auth: auth(for: $0)) }
        defaults.set(try? JSONEncoder().encode(stored), forKey: Self.defaultsKey)
    }
}
