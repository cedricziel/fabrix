@testable import FabrixCore
import Foundation
import Synchronization
import Testing

struct OIDCAuthProviderTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let credentials = InMemoryCredentialStore()
    private let request = URLRequest(url: URL(string: "https://paperclip.test/api/companies")!)

    private func provider(_ server: FakeServer, tokenHeader: String = "Authorization", stored: OIDCTokens) throws -> OIDCAuthProvider {
        try OIDCTokenStore(credentials: credentials, account: "f1.oidc").save(stored)
        return OIDCAuthProvider(
            settings: OIDCFixtures.settings(issuer: server.baseURL, tokenHeader: tokenHeader),
            tokens: OIDCTokenStore(credentials: credentials, account: "f1.oidc"),
            session: server.session, now: { now }
        )
    }

    private func tokens(_ server: FakeServer, access: String = "access-1", refresh: String? = "refresh-1", expiresIn: TimeInterval) -> OIDCTokens {
        OIDCTokens(accessToken: access, refreshToken: refresh, expiresAt: now + expiresIn, tokenEndpoint: server.baseURL.appending(path: "token"))
    }

    @Test func sendsValidAccessTokenWithoutRefreshing() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [:], recorder: recorder)
        let auth = try provider(server, stored: tokens(server, expiresIn: 3600))

        let authorized = try await auth.authorize(request)

        #expect(authorized.value(forHTTPHeaderField: "Authorization") == "Bearer access-1")
        #expect(recorder.requests.isEmpty)
    }

    @Test func placesTokenInConfiguredHeader() async throws {
        let server = FakeServer(routes: [:])
        let auth = try provider(server, tokenHeader: "X-Forwarded-Access-Token", stored: tokens(server, expiresIn: 3600))

        let authorized = try await auth.authorize(request)

        #expect(authorized.value(forHTTPHeaderField: "X-Forwarded-Access-Token") == "Bearer access-1")
        #expect(authorized.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func refreshesExpiringTokenAndStoresRotation() async throws {
        let server = FakeServer(routes: ["POST /token": .json(OIDCFixtures.tokens(access: "access-2", refresh: "refresh-2", expiresIn: 300))])
        let auth = try provider(server, stored: tokens(server, expiresIn: 30))

        let authorized = try await auth.authorize(request)

        #expect(authorized.value(forHTTPHeaderField: "Authorization") == "Bearer access-2")
        let stored = try OIDCTokenStore(credentials: credentials, account: "f1.oidc").load()
        #expect(stored?.accessToken == "access-2")
        #expect(stored?.refreshToken == "refresh-2")
    }

    @Test func concurrentRequestsShareOneRefresh() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["POST /token": .json(OIDCFixtures.tokens(access: "access-2"))], recorder: recorder)
        let auth = try provider(server, stored: tokens(server, expiresIn: -10))

        let headers = try await withThrowingTaskGroup(of: String?.self) { group in
            for _ in 0 ..< 8 {
                group.addTask { try await auth.authorize(request).value(forHTTPHeaderField: "Authorization") }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(headers == Array(repeating: "Bearer access-2", count: 8))
        #expect(recorder.requests.count == 1)
    }

    @Test func refreshesAfterUnauthorized() async throws {
        let server = FakeServer(routes: ["POST /token": .json(OIDCFixtures.tokens(access: "access-2"))])
        let auth = try provider(server, stored: tokens(server, expiresIn: 3600))

        #expect(try await auth.refreshAfterUnauthorized(.fromProxy(value: "Bearer access-1")))
        #expect(try await auth.authorize(request).value(forHTTPHeaderField: "Authorization") == "Bearer access-2")
    }

    @Test func doesNotRetryWithoutRefreshToken() async throws {
        let server = FakeServer(routes: [:])
        let auth = try provider(server, stored: tokens(server, refresh: nil, expiresIn: 3600))

        #expect(try await auth.refreshAfterUnauthorized(.fromProxy(value: "Bearer access-1")) == false)
    }

    @Test func rejectedRefreshIsUnauthorized() async throws {
        let server = FakeServer(routes: ["POST /token": .json(#"{"error":"invalid_grant","error_description":"Token expired"}"#, status: 400)])
        let auth = try provider(server, stored: tokens(server, expiresIn: -10))

        await #expect(throws: PaperclipError.unauthorized("Token expired")) { try await auth.authorize(request) }
    }

    @Test func missingTokensAreUnauthorized() async throws {
        let server = FakeServer(routes: [:])
        let auth = OIDCAuthProvider(
            settings: OIDCFixtures.settings(issuer: server.baseURL),
            tokens: OIDCTokenStore(credentials: credentials, account: "none.oidc"), session: server.session
        )

        await #expect {
            try await auth.authorize(request)
        } throws: { error in
            if case .unauthorized = error as? PaperclipError {
                true
            } else {
                false
            }
        }
    }

    @Test func paperclip401DoesNotRefreshOIDC() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["POST /token": .json(OIDCFixtures.tokens(access: "access-2"))], recorder: recorder)
        let auth = try provider(server, tokenHeader: "X-Forwarded-Access-Token", stored: tokens(server, expiresIn: 3600))

        let retry = try await auth.refreshAfterUnauthorized(.fromPaperclip(sentWith: "X-Forwarded-Access-Token", value: "Bearer access-1"))

        #expect(retry == false)
        #expect(recorder.requests.isEmpty)
    }

    @Test func staleTokenRetriesWithoutAnotherRefresh() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["POST /token": .json(OIDCFixtures.tokens(access: "access-2"))], recorder: recorder)
        let auth = try provider(server, stored: tokens(server, expiresIn: 3600))
        #expect(try await auth.refreshAfterUnauthorized(.fromProxy(value: "Bearer access-1")))

        let retry = try await auth.refreshAfterUnauthorized(.fromProxy(value: "Bearer access-1"))

        #expect(retry)
        #expect(recorder.requests.count == 1)
    }

    @Test func keepsRotatedTokensWhenSavingFails() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["POST /token": .json(OIDCFixtures.tokens(access: "access-2", refresh: "refresh-2"))], recorder: recorder)
        let flaky = FlakyCredentialStore()
        try OIDCTokenStore(credentials: flaky, account: "f1.oidc").save(tokens(server, expiresIn: -10))
        let auth = OIDCAuthProvider(
            settings: OIDCFixtures.settings(issuer: server.baseURL),
            tokens: OIDCTokenStore(credentials: flaky, account: "f1.oidc"), session: server.session, now: { now }
        )
        flaky.failWrites { _ in true }

        await #expect(throws: KeychainError.self) { try await auth.authorize(request) }
        let authorized = try await auth.authorize(request)

        #expect(authorized.value(forHTTPHeaderField: "Authorization") == "Bearer access-2")
        #expect(recorder.requests.count == 1)
    }
}
