import Foundation

/// OIDC tokens kept as one JSON item in a `CredentialStore`.
struct OIDCTokenStore: Sendable {
    let credentials: any CredentialStore
    let account: String

    func load() throws -> OIDCTokens? {
        try credentials.credential(for: account).flatMap { try? JSONDecoder().decode(OIDCTokens.self, from: Data($0.utf8)) }
    }

    func save(_ tokens: OIDCTokens?) throws {
        let json = try tokens.map { try String(decoding: JSONEncoder().encode($0), as: UTF8.self) }
        try credentials.setCredential(json, for: account)
    }
}

/// Sends an OIDC access token and keeps it fresh with the refresh token.
/// Concurrent requests that need a refresh wait for one shared token request.
public actor OIDCAuthProvider: AuthProvider {
    private let settings: OIDCSettings
    private let store: OIDCTokenStore
    private let flow: OIDCFlow
    private let now: @Sendable () -> Date
    private var cached: OIDCTokens?
    private var refreshing: Task<OIDCTokens, Error>?

    /// Refresh this long before the access token expires.
    private static let expiryMargin: TimeInterval = 60

    init(settings: OIDCSettings, tokens: OIDCTokenStore, session: URLSession, now: @escaping @Sendable () -> Date = { .now }) {
        self.settings = settings
        store = tokens
        flow = OIDCFlow(settings: settings, session: session, now: now)
        self.now = now
    }

    public func authorize(_ request: URLRequest) async throws -> URLRequest {
        var tokens = try current()
        if let expiresAt = tokens.expiresAt, tokens.refreshToken != nil, expiresAt.timeIntervalSince(now()) < Self.expiryMargin {
            tokens = try await refreshed(from: tokens)
        }
        var request = request
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: settings.tokenHeader)
        return request
    }

    public func refreshAfterUnauthorized() async throws -> Bool {
        let tokens = try current()
        guard tokens.refreshToken != nil else { return false }
        _ = try await refreshed(from: tokens)
        return true
    }

    private func current() throws -> OIDCTokens {
        if let cached {
            return cached
        }
        guard let stored = try store.load() else { throw PaperclipError.unauthorized("Sign in to the identity provider again.") }
        cached = stored
        return stored
    }

    private func refreshed(from tokens: OIDCTokens) async throws -> OIDCTokens {
        if let refreshing {
            return try await refreshing.value
        }
        let task = Task { [flow] in try await flow.refresh(tokens) }
        refreshing = task
        defer { refreshing = nil }
        do {
            let fresh = try await task.value
            try store.save(fresh)
            cached = fresh
            return fresh
        } catch let OIDCError.provider(code, description) where code == "invalid_grant" {
            throw PaperclipError.unauthorized(description)
        }
    }
}
