import Foundation
import Observation

/// The Paperclip servers this device is connected to. Factory records live in
/// `UserDefaults`; credentials live in a `CredentialStore` (the Keychain by default).
@MainActor
@Observable
public final class FactoryStore {
    public private(set) var factories: [Factory]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let credentials: any CredentialStore
    @ObservationIgnored private let session: URLSession
    private static let defaultsKey = "fabrix.factories"

    public init(defaults: UserDefaults = .standard, credentials: any CredentialStore = KeychainCredentialStore(), session: URLSession = .shared) {
        self.defaults = defaults
        self.credentials = credentials
        self.session = session
        factories = defaults.data(forKey: Self.defaultsKey)
            .flatMap { try? JSONDecoder().decode([Factory].self, from: $0) } ?? []
    }

    /// Checks the credential against the server, then saves the factory.
    ///
    /// - Parameters:
    ///   - url: Server address. A trailing `/api` is ignored.
    ///   - credential: A board API key (`pcp_board_…`), or nil for servers in `local_trusted` mode.
    ///   - name: Display name. Defaults to the server's host.
    /// - Returns: The saved factory. Connecting to a server that is already saved updates it in place.
    /// - Throws: `PaperclipError`, for example `.unauthorized` for a rejected key, or `KeychainError`.
    @discardableResult
    public func connect(url: URL, credential: String?, name: String? = nil) async throws -> Factory {
        let baseURL = try PaperclipClient.serverURL(url)
        let credential = credential?.trimmingCharacters(in: .whitespacesAndNewlines)
        let secret = credential?.isEmpty == false ? credential : nil

        _ = try await PaperclipClient(baseURL: baseURL, credential: secret, session: session).boardSession()

        let existing = factories.firstIndex { $0.baseURL == baseURL }
        let factory = Factory(
            id: existing.map { factories[$0].id } ?? UUID().uuidString,
            name: name ?? existing.map { factories[$0].name } ?? baseURL.host() ?? baseURL.absoluteString,
            baseURL: baseURL,
            isOnline: true
        )
        try credentials.setCredential(secret, for: factory.id)
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

    /// Forgets the factory and deletes its credential.
    public func remove(_ factory: Factory) throws {
        try credentials.setCredential(nil, for: factory.id)
        factories.removeAll { $0.id == factory.id }
        save()
    }

    /// A live `FactoryService` for a saved factory, using its stored credential.
    public func service(for factory: Factory) throws -> PaperclipFactoryService {
        let client = try PaperclipClient(baseURL: factory.baseURL, credential: credentials.credential(for: factory.id), session: session)
        return PaperclipFactoryService(client: client)
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(factories), forKey: Self.defaultsKey)
    }
}
