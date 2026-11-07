import Foundation
import os
import Synchronization

/// OIDC tokens kept as one JSON item in a `CredentialStore`. Every access goes through one lock, so a
/// provider's compare-and-save can't interleave with a `FactoryStore` connect or remove.
struct OIDCTokenStore: Sendable {
    let credentials: any CredentialStore
    let account: String

    private static let lock = Mutex(())
    static let unreadableMessage = "The saved sign-in can't be read. Sign in again."

    enum SaveOutcome {
        case saved
        /// The store no longer holds the expected refresh token: another sign-in or a removal won.
        case replaced
    }

    /// Nil when nothing is stored. Throws `PaperclipError.signInRequired` for an unreadable blob.
    func load() throws -> OIDCTokens? {
        try Self.lock.withLock { _ in try unlockedLoad() }
    }

    func save(_ tokens: OIDCTokens?) throws {
        try Self.lock.withLock { _ in try unlockedSave(tokens) }
    }

    /// Whether the store still holds `refreshToken`. Missing tokens count as replaced.
    func holds(refreshToken: String?) throws -> Bool {
        try load().map { $0.refreshToken == refreshToken } ?? false
    }

    /// Writes `tokens` only if the store still holds `expectedRefreshToken`, atomically.
    func save(_ tokens: OIDCTokens, ifStoredRefreshTokenIs expectedRefreshToken: String?) throws -> SaveOutcome {
        try Self.lock.withLock { _ in
            guard let stored = try unlockedLoad(), stored.refreshToken == expectedRefreshToken else { return .replaced }
            try unlockedSave(tokens)
            return .saved
        }
    }

    private func unlockedLoad() throws -> OIDCTokens? {
        guard let json = try credentials.credential(for: account) else { return nil }
        guard let tokens = try? JSONDecoder().decode(OIDCTokens.self, from: Data(json.utf8)) else {
            throw PaperclipError.signInRequired(Self.unreadableMessage)
        }
        return tokens
    }

    private func unlockedSave(_ tokens: OIDCTokens?) throws {
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
    /// The refresh token this provider last read from or wrote to the store. A different value in the
    /// store means the factory was reconnected or removed, so this provider must not write again.
    private var persistedRefreshToken: String?
    private var replaced = false
    /// Set once the identity provider rejects the refresh token; every later request fails fast.
    private var refreshRejection: PaperclipError?
    private var refreshing: Task<OIDCTokens, Error>?
    private static let logger = Logger(subsystem: "com.cedricziel.fabrix", category: "auth")

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

    /// Refreshes only for a proxy-side `401` on the token this provider currently holds. If another
    /// request already refreshed it, retrying with the new token is enough.
    public func refreshAfterUnauthorized(_ failure: UnauthorizedResponse) async throws -> Bool {
        guard !failure.isFromPaperclip else { return false }
        let tokens = try current()
        guard failure.request.value(forHTTPHeaderField: settings.tokenHeader) == "Bearer \(tokens.accessToken)" else { return true }
        guard tokens.refreshToken != nil else { return false }
        _ = try await refreshed(from: tokens)
        return true
    }

    private func current() throws -> OIDCTokens {
        if replaced {
            throw Self.replacedError
        }
        if let refreshRejection {
            throw refreshRejection
        }
        if let cached {
            return cached
        }
        guard let stored = try store.load() else { throw PaperclipError.signInRequired("Sign in to the identity provider again.") }
        cached = stored
        persistedRefreshToken = stored.refreshToken
        return stored
    }

    private static let replacedError = PaperclipError.unauthorized("This factory was reconnected or removed. Open it again.")

    /// One refresh at a time; every waiter gets the same tokens or the same error.
    private func refreshed(from tokens: OIDCTokens) async throws -> OIDCTokens {
        if let refreshing {
            return try await refreshing.value
        }
        let task = Task { try await self.performRefresh(from: tokens) }
        refreshing = task
        defer { refreshing = nil }
        return try await task.value
    }

    private func performRefresh(from tokens: OIDCTokens) async throws -> OIDCTokens {
        // Don't spend the refresh token if a newer sign-in or a removal already replaced it.
        // If the Keychain can't be read right now, refresh anyway and decide after.
        if (try? store.holds(refreshToken: persistedRefreshToken)) == false {
            throw markReplaced()
        }

        let fresh: OIDCTokens
        do {
            fresh = try await flow.refresh(tokens)
        } catch let OIDCError.provider(code, description) where code == "invalid_grant" {
            let rejection = PaperclipError.signInRequired(description)
            refreshRejection = rejection
            cached = nil
            throw rejection
        }

        // The old refresh token is spent now: keep the new tokens in memory whatever the Keychain does.
        do {
            switch try store.save(fresh, ifStoredRefreshTokenIs: persistedRefreshToken) {
            case .saved:
                persistedRefreshToken = fresh.refreshToken
            case .replaced:
                throw markReplaced()
            }
        } catch let error as PaperclipError where error == Self.replacedError {
            throw error
        } catch {
            Self.logger.error("Couldn't store refreshed OIDC tokens: \(String(describing: error), privacy: .public)")
        }
        cached = fresh
        return fresh
    }

    private func markReplaced() -> PaperclipError {
        replaced = true
        cached = nil
        return Self.replacedError
    }
}
