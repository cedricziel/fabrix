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
        var oidcProvider: OIDCAuthProvider?
        if let oidc = auth.oidc {
            guard let webAuthenticator else {
                throw PaperclipError.invalidAuthConfiguration("OIDC sign-in needs a web authenticator.")
            }
            let tokens = try await OIDCFlow(settings: oidc, session: session).signIn(using: webAuthenticator)
            let staged = OIDCTokenStore(credentials: InMemoryCredentialStore(), account: "candidate")
            try staged.save(tokens)
            oidcTokens = tokens
            oidcProvider = OIDCAuthProvider(settings: oidc, tokens: staged, session: session)
        }
        let candidate = PaperclipClient(baseURL: baseURL, auth: Self.chain(oidc: oidcProvider, boardKey: key), session: session)
        _ = try await candidate.boardSession()

        let existing = factories.firstIndex { $0.baseURL == baseURL }
        let factory = Factory(
            id: existing.map { factories[$0].id } ?? UUID().uuidString,
            name: name ?? existing.map { factories[$0].name } ?? baseURL.host() ?? baseURL.absoluteString,
            baseURL: baseURL,
            isOnline: true
        )
        try credentials.setCredential(key, for: factory.id)
        try oidcTokenStore(factory.id).save(oidcTokens)
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

    /// Starts a browser sign-in. Show `approvalURL` to the user, then call `completeSignIn`.
    public func startSignIn(url: URL, clientName: String) async throws -> SignInChallenge {
        try await PaperclipClient(baseURL: PaperclipClient.serverURL(url), session: session).startSignIn(clientName: clientName)
    }

    /// Waits until the user approves the sign-in in the browser, then connects with the issued key.
    /// Cancel the calling task to stop waiting.
    ///
    /// - Throws: `PaperclipError.signInCancelled` or `.signInExpired` when the challenge ends without approval.
    @discardableResult
    public func completeSignIn(_ challenge: SignInChallenge, name: String? = nil) async throws -> Factory {
        let client = PaperclipClient(baseURL: challenge.serverURL, session: session)
        while true {
            switch try await client.signInStatus(challenge) {
            case .approved: return try await connect(url: challenge.serverURL, credential: challenge.boardAPIToken, name: name)
            case .cancelled: throw PaperclipError.signInCancelled
            case .expired: throw PaperclipError.signInExpired
            case .pending: try await Task.sleep(for: challenge.pollInterval)
            }
        }
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
