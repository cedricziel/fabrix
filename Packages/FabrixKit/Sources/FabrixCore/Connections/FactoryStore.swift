import Foundation
import Observation

/// The Paperclip servers this device is connected to. Factory records and their auth
/// configuration live in `UserDefaults`; secrets live in a `CredentialStore` (the Keychain by default).
@MainActor
@Observable
public final class FactoryStore {
    public private(set) var factories: [Factory]
    /// Changes whenever a factory is saved, reconnected or removed, even when its record looks
    /// the same, so open windows can pick up new credentials.
    public private(set) var revision = 0

    @ObservationIgnored private var authConfigurations: [Factory.ID: FactoryAuthConfiguration]
    @ObservationIgnored private var headerNames: [Factory.ID: [String]]
    /// One provider per factory, so concurrent services share a single token refresh.
    @ObservationIgnored private var oidcProviders: [Factory.ID: OIDCAuthProvider] = [:]
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let credentials: any CredentialStore
    @ObservationIgnored private let session: URLSession
    private static let defaultsKey = "fabrix.factories"

    private struct StoredFactory: Codable {
        var factory: Factory
        var auth: FactoryAuthConfiguration
        /// Custom header names; their values are in the credential store. Missing in records from older versions.
        var headerNames: [String]?
    }

    public init(defaults: UserDefaults = .standard, credentials: any CredentialStore = KeychainCredentialStore(), session: URLSession = .shared) {
        self.defaults = defaults
        self.credentials = credentials
        self.session = session
        let stored = defaults.data(forKey: Self.defaultsKey)
            .flatMap { try? JSONDecoder().decode([StoredFactory].self, from: $0) } ?? []
        factories = stored.map(\.factory)
        authConfigurations = Dictionary(stored.map { ($0.factory.id, $0.auth) }, uniquingKeysWith: { _, last in last })
        headerNames = Dictionary(stored.map { ($0.factory.id, $0.headerNames ?? []) }, uniquingKeysWith: { _, last in last })
    }

    /// Connects with a board API key, or without credentials when `credential` is nil or blank.
    @discardableResult
    public func connect(url: URL, credential: String?, name: String? = nil, headers: [CustomHeader] = []) async throws -> Factory {
        let key = Self.trimmed(credential)
        return try await connect(url: url, auth: key == nil ? .none : .boardKey, boardKey: key, name: name, headers: headers, webAuthenticator: nil)
    }

    /// Signs in as `auth` describes, checks the result against the server, then saves the factory.
    ///
    /// - Parameters:
    ///   - url: Server address. A trailing `/api` is ignored.
    ///   - auth: Which layers to use. OIDC sign-in runs first when `auth.oidc` is set.
    ///   - boardKey: The Paperclip board API key; required when `auth.usesBoardKey`, ignored otherwise.
    ///   - name: Display name. Defaults to the server's host, or the saved name when reconnecting.
    ///   - headers: Extra headers sent with every request to this server, checked with `CustomHeader.validated(_:for:)`.
    ///   - webAuthenticator: Shows the OIDC login page; required when `auth.oidc` is set.
    /// - Returns: The saved factory. Connecting to a server that is already saved updates it in place.
    /// - Throws: `PaperclipError` (`.invalidServerURL`, `.invalidAuthConfiguration`, `.unauthorized`, …),
    ///   `OIDCError` from the identity provider, or `KeychainError`. Nothing is saved when it throws.
    @discardableResult
    public func connect(
        url: URL, auth: FactoryAuthConfiguration, boardKey: String?, name: String? = nil, headers: [CustomHeader] = [],
        webAuthenticator: (any WebAuthenticator)?
    ) async throws -> Factory {
        let baseURL = try PaperclipClient.serverURL(url)
        try auth.validate()
        let headers = try CustomHeader.validated(headers, for: auth)
        let key = auth.usesBoardKey ? Self.trimmed(boardKey) : nil
        if auth.usesBoardKey, key == nil {
            throw PaperclipError.invalidAuthConfiguration("Enter a board API key.")
        }

        var oidcTokens: OIDCTokens?
        if let oidc = auth.oidc {
            // An OIDC token is a credential too; fail before the user goes through a login that can't be used.
            guard PaperclipClient.allowsCredentials(to: baseURL) else { throw PaperclipError.insecureConnection }
            oidcTokens = try await signInToIdentityProvider(oidc, webAuthenticator: webAuthenticator)
        }
        return try await validateAndSave(baseURL: baseURL, auth: auth, boardKey: key, headers: headers, oidcTokens: oidcTokens, name: name)
    }

    /// Starts a browser sign-in. Show `approvalURL` to the user, then call `completeSignIn`.
    ///
    /// - Parameters:
    ///   - frontDoor: OIDC settings for a reverse proxy in front of Paperclip. Its `tokenHeader` must not be
    ///     `Authorization`, because the issued board key goes there. Sign-in to the identity provider runs first.
    ///   - headers: Extra headers sent with the sign-in requests and saved with the factory.
    ///   - webAuthenticator: Shows the OIDC login page; required with `frontDoor`.
    public func startSignIn(
        url: URL, clientName: String, frontDoor: OIDCSettings? = nil, headers: [CustomHeader] = [],
        webAuthenticator: (any WebAuthenticator)? = nil
    ) async throws -> SignInChallenge {
        let baseURL = try PaperclipClient.serverURL(url)
        guard PaperclipClient.allowsCredentials(to: baseURL) else { throw PaperclipError.insecureConnection }
        let auth = FactoryAuthConfiguration(oidc: frontDoor, usesBoardKey: true)
        try auth.validate()
        let headers = try CustomHeader.validated(headers, for: auth)
        var oidcTokens: OIDCTokens?
        if let frontDoor {
            oidcTokens = try await signInToIdentityProvider(frontDoor, webAuthenticator: webAuthenticator)
        }
        return try await createChallenge(baseURL: baseURL, clientName: clientName, frontDoor: frontDoor, oidcTokens: oidcTokens, headers: headers)
    }

    /// Starts a browser sign-in that replaces the board key of a saved factory, for example after it expired.
    /// The factory's custom headers and saved OIDC tokens are reused, so there is no second OIDC login.
    /// `completeSignIn` then keeps the factory's ID, name and settings.
    ///
    /// - Throws: `PaperclipError.invalidAuthConfiguration` when the factory doesn't use a board key.
    public func startReauthentication(of factory: Factory, clientName: String) async throws -> SignInChallenge {
        let auth = auth(for: factory)
        guard auth.usesBoardKey else {
            throw PaperclipError.invalidAuthConfiguration("This factory doesn't use a Paperclip key, so there is nothing to sign in again for.")
        }
        guard PaperclipClient.allowsCredentials(to: factory.baseURL) else { throw PaperclipError.insecureConnection }
        let tokens = auth.oidc == nil ? nil : try oidcTokenStore(factory.id).load()
        return try await createChallenge(
            baseURL: factory.baseURL, clientName: clientName, frontDoor: auth.oidc, oidcTokens: tokens, headers: customHeaders(for: factory)
        )
    }

    private func createChallenge(
        baseURL: URL, clientName: String, frontDoor: OIDCSettings?, oidcTokens: OIDCTokens?, headers: [CustomHeader]
    ) async throws -> SignInChallenge {
        let staged = try stage(frontDoor, oidcTokens)
        var challenge = try await PaperclipClient(baseURL: baseURL, auth: Self.chain(oidc: staged?.provider, boardKey: nil, headers: headers), session: session)
            .startSignIn(clientName: clientName)
        challenge.frontDoor = frontDoor
        challenge.customHeaders = headers
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
        let client = PaperclipClient(
            baseURL: challenge.serverURL, auth: Self.chain(oidc: staged?.provider, boardKey: nil, headers: challenge.customHeaders), session: session
        )
        while true {
            // The app may have been in the background for longer than the request lives.
            if let expiresAt = challenge.expiresAt, expiresAt <= .now { throw PaperclipError.signInExpired }
            switch try await client.signInStatus(challenge) {
            case .approved:
                return try await validateAndSave(
                    baseURL: challenge.serverURL, auth: FactoryAuthConfiguration(oidc: challenge.frontDoor, usesBoardKey: true),
                    boardKey: challenge.boardAPIToken, headers: challenge.customHeaders, oidcTokens: staged?.store.load(), name: name
                )
            case .cancelled: throw PaperclipError.signInCancelled
            case .expired: throw PaperclipError.signInExpired
            case .pending: try await Task.sleep(for: challenge.pollInterval)
            }
        }
    }

    private func signInToIdentityProvider(_ settings: OIDCSettings, webAuthenticator: (any WebAuthenticator)?) async throws -> OIDCTokens {
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
        baseURL: URL, auth: FactoryAuthConfiguration, boardKey: String?, headers: [CustomHeader], oidcTokens: OIDCTokens?, name: String?
    ) async throws -> Factory {
        let staged = try stage(auth.oidc, oidcTokens)
        _ = try await PaperclipClient(baseURL: baseURL, auth: Self.chain(oidc: staged?.provider, boardKey: boardKey, headers: headers), session: session)
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
        let previousHeaderValues = try credentials.credential(for: Self.headersAccount(factory.id))
        try credentials.setCredential(boardKey, for: factory.id)
        do {
            try credentials.setCredential(Self.encodedValues(headers), for: Self.headersAccount(factory.id))
            try oidcTokenStore(factory.id).save(tokensToSave)
        } catch {
            try? credentials.setCredential(previousKey, for: factory.id)
            try? credentials.setCredential(previousHeaderValues, for: Self.headersAccount(factory.id))
            throw error
        }
        oidcProviders[factory.id] = nil
        authConfigurations[factory.id] = auth
        headerNames[factory.id] = headers.map(\.name)
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

    /// The saved custom headers, with their values read from the credential store.
    public func customHeaders(for factory: Factory) throws -> [CustomHeader] {
        let names = headerNames[factory.id] ?? []
        guard !names.isEmpty, let stored = try credentials.credential(for: Self.headersAccount(factory.id)) else { return [] }
        let values = try JSONDecoder().decode([String: String].self, from: Data(stored.utf8))
        return names.compactMap { name in values[name].map { CustomHeader(name: name, value: $0) } }
    }

    /// Forgets the factory and deletes its board key, custom header values and OIDC tokens.
    ///
    /// The record goes first, so a factory is never left listed without its secrets. Deleting the
    /// secrets afterwards is best effort: a leftover Keychain item is unreachable and harmless.
    public func remove(_ factory: Factory) {
        oidcProviders[factory.id] = nil
        authConfigurations[factory.id] = nil
        headerNames[factory.id] = nil
        factories.removeAll { $0.id == factory.id }
        save()
        try? credentials.setCredential(nil, for: factory.id)
        try? credentials.setCredential(nil, for: Self.headersAccount(factory.id))
        try? oidcTokenStore(factory.id).save(nil)
    }

    /// A live `FactoryService` for a saved factory, authenticated with its stored configuration.
    public func service(for factory: Factory) throws -> PaperclipFactoryService {
        let auth = auth(for: factory)
        let key = auth.usesBoardKey ? try credentials.credential(for: factory.id) : nil
        let client = PaperclipClient(
            baseURL: factory.baseURL,
            auth: Self.chain(oidc: oidcProvider(for: factory, settings: auth.oidc), boardKey: key, headers: try customHeaders(for: factory)),
            session: session
        )
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

    private static func chain(oidc: OIDCAuthProvider?, boardKey: String?, headers: [CustomHeader]) -> any AuthProvider {
        let layers: [(any AuthProvider)?] = [
            headers.isEmpty ? nil : CustomHeadersAuth(headers: headers), oidc, boardKey.map { BearerTokenAuth(token: $0) },
        ]
        return ChainedAuth(layers.compactMap(\.self))
    }

    private func oidcTokenStore(_ factoryID: Factory.ID) -> OIDCTokenStore {
        OIDCTokenStore(credentials: credentials, account: "\(factoryID).oidc")
    }

    private static func headersAccount(_ factoryID: Factory.ID) -> String {
        "\(factoryID).headers"
    }

    /// Header values as a JSON object keyed by name, or nil when there are none.
    private static func encodedValues(_ headers: [CustomHeader]) throws -> String? {
        guard !headers.isEmpty else { return nil }
        let values = Dictionary(uniqueKeysWithValues: headers.map { ($0.name, $0.value) })
        return try String(decoding: JSONEncoder().encode(values), as: UTF8.self)
    }

    private static func trimmed(_ secret: String?) -> String? {
        guard let secret = secret?.trimmingCharacters(in: .whitespacesAndNewlines), !secret.isEmpty else { return nil }
        return secret
    }

    private func save() {
        revision += 1
        let stored = factories.map { StoredFactory(factory: $0, auth: auth(for: $0), headerNames: headerNames[$0.id]) }
        defaults.set(try? JSONEncoder().encode(stored), forKey: Self.defaultsKey)
    }
}
