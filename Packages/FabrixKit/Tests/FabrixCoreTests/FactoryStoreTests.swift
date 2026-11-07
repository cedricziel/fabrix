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

        try store.remove(factory)

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

    @Test func refusesBoardKeyOverRemoteHTTP() async throws {
        let store = FactoryStore(defaults: defaults, credentials: credentials, session: StubURLProtocol.session)

        await #expect(throws: PaperclipError.insecureConnection) {
            try await store.connect(url: URL(string: "http://paperclip.example.com")!, credential: "pcp_board_secret")
        }
        #expect(store.factories.isEmpty)
        #expect(credentials.isEmpty)
    }
}
