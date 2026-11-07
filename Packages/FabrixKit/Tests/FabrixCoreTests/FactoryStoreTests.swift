@testable import FabrixCore
import Foundation
import Synchronization
import Testing

@MainActor
struct FactoryStoreTests {
    private let defaults = UserDefaults(suiteName: "FactoryStoreTests-\(UUID().uuidString)")!
    private let credentials = InMemoryCredentialStore()

    private func store(_ server: FakeServer) -> FactoryStore {
        FactoryStore(defaults: defaults, credentials: credentials, session: server.session)
    }

    @Test func connectValidatesThenPersistsFactoryAndCredential() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)], recorder: recorder)
        let store = store(server)

        let factory = try await store.connect(url: server.baseURL.appending(path: "api/"), credential: " pcp_board_secret\n", name: "Home lab")

        #expect(factory.name == "Home lab")
        #expect(factory.baseURL == server.baseURL)
        #expect(factory.isOnline)
        #expect(store.factories == [factory])
        #expect(try credentials.credential(for: factory.id) == "pcp_board_secret")
        #expect(recorder.requests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer pcp_board_secret")
    }

    @Test func factoriesSurviveRelaunch() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let factory = try await store(server).connect(url: server.baseURL, credential: "k")

        let relaunched = store(server)

        #expect(relaunched.factories == [factory])
    }

    @Test func connectDefaultsNameToHost() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])

        let factory = try await store(server).connect(url: server.baseURL, credential: nil)

        #expect(factory.name == server.baseURL.host())
        #expect(try credentials.credential(for: factory.id) == nil)
    }

    @Test func rejectedCredentialPersistsNothing() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(#"{"error":"Board authentication required"}"#, status: 401)])
        let store = store(server)

        await #expect(throws: PaperclipError.unauthorized("Board authentication required")) {
            try await store.connect(url: server.baseURL, credential: "wrong")
        }
        #expect(store.factories.isEmpty)
        #expect(credentials.isEmpty)
    }

    @Test func rejectsNonHTTPURLs() async throws {
        let server = FakeServer(routes: [:])

        await #expect(throws: PaperclipError.invalidServerURL) {
            try await store(server).connect(url: #require(URL(string: "file:///etc/passwd")), credential: nil)
        }
    }

    @Test func everySaveOrRemovalChangesTheRevision() async throws {
        let paperclip = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let store = FactoryStore(defaults: defaults, credentials: credentials, session: paperclip.session)
        let start = store.revision

        let factory = try await store.connect(url: paperclip.baseURL, credential: "old")
        let afterConnect = store.revision
        try await store.connect(url: paperclip.baseURL, credential: "new")
        let afterReconnect = store.revision
        store.remove(factory)

        #expect(afterConnect > start)
        #expect(afterReconnect > afterConnect)
        #expect(store.revision > afterReconnect)
    }

    @Test func reconnectingSameServerReplacesCredentialAndKeepsID() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let store = store(server)
        let first = try await store.connect(url: server.baseURL, credential: "old")

        let second = try await store.connect(url: server.baseURL, credential: "new", name: "Renamed")

        #expect(second.id == first.id)
        #expect(store.factories.map(\.name) == ["Renamed"])
        #expect(try credentials.credential(for: first.id) == "new")
    }

    @Test func removeForgetsFactoryAndCredential() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let store = store(server)
        let factory = try await store.connect(url: server.baseURL, credential: "k")

        store.remove(factory)

        #expect(store.factories.isEmpty)
        #expect(try credentials.credential(for: factory.id) == nil)
        #expect(self.store(server).factories.isEmpty)
    }

    @Test func serviceUsesStoredCredential() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [
            "GET /api/cli-auth/me": .json(PaperclipFixtures.me),
            "GET /api/companies": .json(PaperclipFixtures.companies),
        ], recorder: recorder)
        let store = store(server)
        let factory = try await store.connect(url: server.baseURL, credential: "pcp_board_secret")

        _ = try await store.service(for: factory).companies()

        #expect(recorder.last("GET", "/api/companies")?.value(forHTTPHeaderField: "Authorization") == "Bearer pcp_board_secret")
    }

    @Test func browserSignInPollsUntilApprovedThenConnects() async throws {
        let polls = Mutex(0)
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [
            "POST /api/cli-auth/challenges": .json(#"{"id":"ch-1","token":"pcp_cli_auth_abc","boardApiToken":"pcp_board_new","approvalPath":"/cli-auth/ch-1?token=pcp_cli_auth_abc","approvalUrl":null,"suggestedPollIntervalMs":1}"#, status: 201),
            "GET /api/cli-auth/me": .json(PaperclipFixtures.me),
        ], recorder: recorder, dynamicRoutes: ["GET /api/cli-auth/challenges/ch-1": { _ in
            let count = polls.withLock { $0 += 1; return $0 }
            return .json(#"{"id":"ch-1","status":"\#(count < 3 ? "pending" : "approved")"}"#)
        }])
        let store = store(server)

        let challenge = try await store.startSignIn(url: server.baseURL, clientName: "Fabrix")
        let factory = try await store.completeSignIn(challenge)

        #expect(polls.withLock { $0 } == 3)
        #expect(try credentials.credential(for: factory.id) == "pcp_board_new")
        #expect(store.factories == [factory])
    }

    @Test(arguments: [("expired", PaperclipError.signInExpired), ("cancelled", .signInCancelled)])
    func browserSignInStopsWhenChallengeEnds(status: String, expected: PaperclipError) async throws {
        let server = FakeServer(routes: [
            "GET /api/cli-auth/challenges/ch-1": .json(#"{"id":"ch-1","status":"\#(status)"}"#),
        ])
        let store = store(server)
        let challenge = SignInChallenge(serverURL: server.baseURL, id: "ch-1", token: "pcp_cli_auth_abc", boardAPIToken: "pcp_board_new", approvalURL: server.baseURL, pollInterval: .zero)

        await #expect(throws: expected) { try await store.completeSignIn(challenge) }
        #expect(store.factories.isEmpty)
    }

    // MARK: - Auth configurations

    private func identityProvider(recorder: RequestRecorder? = nil) -> FakeServer {
        FakeServer(routes: ["POST /token": .json(OIDCFixtures.tokens())], recorder: recorder, dynamicRoutes: [
            "GET /.well-known/openid-configuration": { request in
                .json(OIDCFixtures.discovery(issuer: URL(string: "https://\(request.url!.host()!)")!))
            },
        ])
    }

    @Test func connectsWithOIDCFrontDoorAndBoardKey() async throws {
        let recorder = RequestRecorder()
        let idp = identityProvider()
        let paperclip = FakeServer(routes: [
            "GET /api/cli-auth/me": .json(PaperclipFixtures.me),
            "GET /api/companies": .json(PaperclipFixtures.companies),
        ], recorder: recorder)
        let store = store(paperclip)
        let auth = FactoryAuthConfiguration(oidc: OIDCFixtures.settings(issuer: idp.baseURL, tokenHeader: "X-Forwarded-Access-Token"), usesBoardKey: true)

        let factory = try await store.connect(url: paperclip.baseURL, auth: auth, boardKey: "pcp_board_secret", webAuthenticator: FakeWebAuthenticator.approving())
        _ = try await store.service(for: factory).companies()

        for path in ["/api/cli-auth/me", "/api/companies"] {
            let request = try #require(recorder.last("GET", path))
            #expect(request.value(forHTTPHeaderField: "X-Forwarded-Access-Token") == "Bearer access-1")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer pcp_board_secret")
        }
        #expect(store.auth(for: factory) == auth)
    }

    @Test func oidcOnlyConnectionSendsNoBoardKey() async throws {
        let recorder = RequestRecorder()
        let idp = identityProvider()
        let paperclip = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)], recorder: recorder)
        let auth = FactoryAuthConfiguration(oidc: OIDCFixtures.settings(issuer: idp.baseURL))

        let factory = try await store(paperclip).connect(url: paperclip.baseURL, auth: auth, boardKey: "ignored", webAuthenticator: FakeWebAuthenticator.approving())

        #expect(recorder.requests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer access-1")
        #expect(try credentials.credential(for: factory.id) == nil)
    }

    @Test func rejectsConflictingAuthorizationHeaders() async throws {
        let recorder = RequestRecorder()
        let paperclip = FakeServer(routes: [:], recorder: recorder)
        let auth = FactoryAuthConfiguration(oidc: OIDCFixtures.settings(issuer: paperclip.baseURL), usesBoardKey: true)

        await #expect {
            try await store(paperclip).connect(url: paperclip.baseURL, auth: auth, boardKey: "k", webAuthenticator: FakeWebAuthenticator.approving())
        } throws: { error in
            if case .invalidAuthConfiguration = error as? PaperclipError { true } else { false }
        }
        #expect(recorder.requests.isEmpty)
    }

    @Test func boardKeyConfigurationNeedsAKey() async throws {
        let paperclip = FakeServer(routes: [:])

        await #expect {
            try await store(paperclip).connect(url: paperclip.baseURL, auth: .boardKey, boardKey: "  ", webAuthenticator: nil)
        } throws: { error in
            if case .invalidAuthConfiguration = error as? PaperclipError { true } else { false }
        }
    }

    @Test func failedValidationAfterOIDCSignInPersistsNothing() async throws {
        let idp = identityProvider()
        let paperclip = FakeServer(routes: ["GET /api/cli-auth/me": .json(#"{"error":"nope"}"#, status: 401)])
        let store = store(paperclip)

        await #expect(throws: PaperclipError.unauthorized("nope")) {
            try await store.connect(url: paperclip.baseURL, auth: FactoryAuthConfiguration(oidc: OIDCFixtures.settings(issuer: idp.baseURL)), boardKey: nil, webAuthenticator: FakeWebAuthenticator.approving())
        }
        #expect(store.factories.isEmpty)
        #expect(credentials.isEmpty)
    }

    @Test func authConfigurationSurvivesRelaunch() async throws {
        let idp = identityProvider()
        let paperclip = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let auth = FactoryAuthConfiguration(oidc: OIDCFixtures.settings(issuer: idp.baseURL, tokenHeader: "X-Auth"), usesBoardKey: true)
        let factory = try await store(paperclip).connect(url: paperclip.baseURL, auth: auth, boardKey: "k", webAuthenticator: FakeWebAuthenticator.approving())

        let relaunched = store(paperclip)

        #expect(relaunched.factories == [factory])
        #expect(relaunched.auth(for: factory) == auth)
    }

    @Test func removeDeletesOIDCTokens() async throws {
        let idp = identityProvider()
        let paperclip = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let store = store(paperclip)
        let factory = try await store.connect(url: paperclip.baseURL, auth: FactoryAuthConfiguration(oidc: OIDCFixtures.settings(issuer: idp.baseURL)), boardKey: nil, webAuthenticator: FakeWebAuthenticator.approving())
        #expect(!credentials.isEmpty)

        store.remove(factory)

        #expect(credentials.isEmpty)
        #expect(store.auth(for: factory) == FactoryAuthConfiguration.none)
    }

    @Test func refusesBoardKeyOverRemoteHTTP() async throws {
        let store = FactoryStore(defaults: defaults, credentials: credentials, session: StubURLProtocol.session)

        await #expect(throws: PaperclipError.insecureConnection) {
            try await store.connect(url: URL(string: "http://paperclip.example.com")!, credential: "pcp_board_secret")
        }
        #expect(store.factories.isEmpty)
        #expect(credentials.isEmpty)
    }

    @Test func removeDropsTheFactoryEvenIfASecretCannotBeDeleted() async throws {
        let flaky = FlakyCredentialStore()
        let paperclip = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let store = FactoryStore(defaults: defaults, credentials: flaky, session: paperclip.session)
        let factory = try await store.connect(url: paperclip.baseURL, credential: "key")
        flaky.failWrites { $0.hasSuffix(".oidc") }

        store.remove(factory)

        #expect(store.factories.isEmpty)
        #expect(FactoryStore(defaults: defaults, credentials: flaky, session: paperclip.session).factories.isEmpty)
    }

    @Test func failedSecondSecretWriteRollsBackTheFirst() async throws {
        let flaky = FlakyCredentialStore()
        let idp = identityProvider()
        let paperclip = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let store = FactoryStore(defaults: defaults, credentials: flaky, session: paperclip.session)
        let factory = try await store.connect(url: paperclip.baseURL, credential: "old")
        flaky.failWrites { $0.hasSuffix(".oidc") }

        let frontDoor = FactoryAuthConfiguration(oidc: OIDCFixtures.settings(issuer: idp.baseURL, tokenHeader: "X-Auth"), usesBoardKey: true)
        await #expect(throws: KeychainError.self) {
            try await store.connect(url: paperclip.baseURL, auth: frontDoor, boardKey: "new", webAuthenticator: FakeWebAuthenticator.approving())
        }

        #expect(try flaky.credential(for: factory.id) == "old")
        #expect(store.auth(for: factory) == .boardKey)
    }

    @Test func browserSignInWorksBehindOIDCFrontDoor() async throws {
        let recorder = RequestRecorder()
        let idp = identityProvider()
        let browser = FakeWebAuthenticator.approving()
        let paperclip = FakeServer(routes: [
            "POST /api/cli-auth/challenges": .json(#"{"id":"ch-1","token":"pcp_cli_auth_abc","boardApiToken":"pcp_board_new","approvalPath":"/cli-auth/ch-1?token=pcp_cli_auth_abc","approvalUrl":null,"suggestedPollIntervalMs":1}"#, status: 201),
            "GET /api/cli-auth/challenges/ch-1": .json(#"{"id":"ch-1","status":"approved"}"#),
            "GET /api/cli-auth/me": .json(PaperclipFixtures.me),
        ], recorder: recorder)
        let store = store(paperclip)
        let frontDoor = OIDCFixtures.settings(issuer: idp.baseURL, tokenHeader: "X-Forwarded-Access-Token")

        let challenge = try await store.startSignIn(url: paperclip.baseURL, clientName: "Fabrix", frontDoor: frontDoor, webAuthenticator: browser)
        let factory = try await store.completeSignIn(challenge)

        #expect(recorder.requests.allSatisfy { $0.value(forHTTPHeaderField: "X-Forwarded-Access-Token") == "Bearer access-1" })
        #expect(recorder.last("GET", "/api/cli-auth/me")?.value(forHTTPHeaderField: "Authorization") == "Bearer pcp_board_new")
        #expect(store.auth(for: factory) == FactoryAuthConfiguration(oidc: frontDoor, usesBoardKey: true))
        #expect(try credentials.credential(for: factory.id) == "pcp_board_new")
        #expect(try credentials.credential(for: "\(factory.id).oidc") != nil)
    }

    /// Runs `connect` against a remote plain-HTTP server and checks it fails before the identity provider is involved.
    private func expectInsecureBeforeOIDCLogin(
        _ connect: (FactoryStore, OIDCSettings, FakeWebAuthenticator) async throws -> Void
    ) async {
        let idpRequests = RequestRecorder()
        let idp = identityProvider(recorder: idpRequests)
        let browser = FakeWebAuthenticator.approving()
        let store = FactoryStore(defaults: defaults, credentials: credentials, session: idp.session)

        await #expect(throws: PaperclipError.insecureConnection) {
            try await connect(store, OIDCFixtures.settings(issuer: idp.baseURL, tokenHeader: "X-Forwarded-Access-Token"), browser)
        }
        #expect(browser.authorizeURL == nil)
        #expect(idpRequests.requests.isEmpty)
    }

    @Test func browserSignInChecksTransportBeforeOIDCSignIn() async {
        await expectInsecureBeforeOIDCLogin { store, frontDoor, browser in
            _ = try await store.startSignIn(url: URL(string: "http://paperclip.example.com")!, clientName: "Fabrix", frontDoor: frontDoor, webAuthenticator: browser)
        }
    }

    @Test func oidcConnectChecksTransportBeforeOIDCSignIn() async {
        await expectInsecureBeforeOIDCLogin { store, oidc, browser in
            let auth = FactoryAuthConfiguration(oidc: oidc, usesBoardKey: true)
            try await store.connect(url: URL(string: "http://paperclip.example.com")!, auth: auth, boardKey: "pcp_board_secret", webAuthenticator: browser)
        }
    }

    @Test func customHeadersAreSentAndStoredInTheKeychain() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)], recorder: recorder)
        let store = store(server)

        let factory = try await store.connect(url: server.baseURL, credential: "pcp_board_secret", headers: PaperclipFixtures.proxyHeader)

        #expect(recorder.last("GET", "/api/cli-auth/me")?.value(forHTTPHeaderField: "X-Proxy-Token") == "proxy-secret")
        #expect(try store.customHeaders(for: factory) == PaperclipFixtures.proxyHeader)
        #expect(try credentials.credential(for: "\(factory.id).headers")?.contains("proxy-secret") == true)
        let record = try #require(defaults.data(forKey: "fabrix.factories"))
        #expect(String(decoding: record, as: UTF8.self).contains("X-Proxy-Token"))
        #expect(!String(decoding: record, as: UTF8.self).contains("proxy-secret"))
    }

    @Test func customHeadersSurviveRelaunch() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me), "GET /api/companies": .json(PaperclipFixtures.companies)], recorder: recorder)
        let factory = try await store(server).connect(url: server.baseURL, credential: "pcp_board_secret", headers: PaperclipFixtures.proxyHeader)

        let relaunched = store(server)
        _ = try await relaunched.service(for: factory).companies()

        #expect(recorder.last("GET", "/api/companies")?.value(forHTTPHeaderField: "X-Proxy-Token") == "proxy-secret")
        #expect(try relaunched.customHeaders(for: factory) == PaperclipFixtures.proxyHeader)
    }

    @Test func oldRecordsDecodeWithoutHeaderNames() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let factory = try await store(server).connect(url: server.baseURL, credential: "pcp_board_secret")
        let data = try #require(defaults.data(forKey: "fabrix.factories"))
        var records = try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        for index in records.indices { records[index]["headerNames"] = nil }
        defaults.set(try JSONSerialization.data(withJSONObject: records), forKey: "fabrix.factories")

        let relaunched = store(server)

        #expect(relaunched.factories.map(\.id) == [factory.id])
        #expect(try relaunched.customHeaders(for: factory).isEmpty)
    }

    @Test func removeDeletesCustomHeaderValues() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let store = store(server)
        let factory = try await store.connect(url: server.baseURL, credential: "pcp_board_secret", headers: PaperclipFixtures.proxyHeader)

        store.remove(factory)

        #expect(credentials.isEmpty)
    }

    @Test func invalidCustomHeadersAreRefusedBeforeAnyRequest() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)], recorder: recorder)
        let store = store(server)

        await #expect(throws: PaperclipError.self) {
            try await store.connect(url: server.baseURL, credential: "pcp_board_secret", headers: [CustomHeader(name: "Authorization", value: "x")])
        }
        #expect(recorder.requests.isEmpty)
        #expect(store.factories.isEmpty)
    }

    @Test func customHeadersAreRefusedOverRemoteHTTP() async throws {
        let store = FactoryStore(defaults: defaults, credentials: credentials, session: StubURLProtocol.session)

        await #expect(throws: PaperclipError.insecureConnection) {
            try await store.connect(url: URL(string: "http://paperclip.example.com")!, credential: nil, headers: PaperclipFixtures.proxyHeader)
        }
        #expect(credentials.isEmpty)
    }

    @Test func customHeadersAreNotSentToTheIdentityProvider() async throws {
        let idpRequests = RequestRecorder()
        let idp = identityProvider(recorder: idpRequests)
        let paperclipRequests = RequestRecorder()
        let paperclip = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)], recorder: paperclipRequests)
        let store = store(paperclip)
        let auth = FactoryAuthConfiguration(oidc: OIDCFixtures.settings(issuer: idp.baseURL))

        try await store.connect(url: paperclip.baseURL, auth: auth, boardKey: nil, headers: PaperclipFixtures.proxyHeader, webAuthenticator: FakeWebAuthenticator.approving())

        #expect(!idpRequests.requests.isEmpty)
        #expect(idpRequests.requests.allSatisfy { $0.value(forHTTPHeaderField: "X-Proxy-Token") == nil })
        #expect(paperclipRequests.last("GET", "/api/cli-auth/me")?.value(forHTTPHeaderField: "X-Proxy-Token") == "proxy-secret")
    }

    @Test func browserSignInSendsCustomHeaders() async throws {
        let recorder = RequestRecorder()
        let paperclip = FakeServer(routes: [
            "POST /api/cli-auth/challenges": .json(#"{"id":"ch-1","token":"pcp_cli_auth_abc","boardApiToken":"pcp_board_new","approvalPath":"/cli-auth/ch-1?token=pcp_cli_auth_abc","approvalUrl":null,"suggestedPollIntervalMs":1}"#, status: 201),
            "GET /api/cli-auth/challenges/ch-1": .json(#"{"id":"ch-1","status":"approved"}"#),
            "GET /api/cli-auth/me": .json(PaperclipFixtures.me),
        ], recorder: recorder)
        let store = store(paperclip)

        let challenge = try await store.startSignIn(url: paperclip.baseURL, clientName: "Fabrix", headers: PaperclipFixtures.proxyHeader)
        let factory = try await store.completeSignIn(challenge)

        #expect(recorder.requests.count == 3)
        #expect(recorder.requests.allSatisfy { $0.value(forHTTPHeaderField: "X-Proxy-Token") == "proxy-secret" })
        #expect(try store.customHeaders(for: factory) == PaperclipFixtures.proxyHeader)
    }
}
