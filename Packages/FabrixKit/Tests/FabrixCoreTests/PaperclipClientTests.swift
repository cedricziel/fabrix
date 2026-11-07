@testable import FabrixCore
import Foundation
import Testing

struct PaperclipClientTests {
    @Test func sendsBearerCredentialOnEveryRequest() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)], recorder: recorder)
        let client = PaperclipClient(baseURL: server.baseURL, credential: "pcp_board_secret", session: server.session)

        _ = try await client.boardSession()

        let request = try #require(recorder.last("GET", "/api/cli-auth/me"))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer pcp_board_secret")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func omitsAuthorizationWithoutCredential() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)], recorder: recorder)
        let client = PaperclipClient(baseURL: server.baseURL, session: server.session)

        _ = try await client.boardSession()

        #expect(recorder.requests.first?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func decodesBoardSession() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)])
        let client = PaperclipClient(baseURL: server.baseURL, credential: "k", session: server.session)

        let session = try await client.boardSession()

        #expect(session == BoardSession(userID: "u-1", userName: "Ada Board", companyIDs: [PaperclipFixtures.companyID], isInstanceAdmin: false))
    }

    @Test(arguments: [
        (400, PaperclipError.invalidRequest("nope")),
        (401, .unauthorized("nope")),
        (403, .forbidden("nope")),
        (404, .notFound("nope")),
        (409, .conflict("nope")),
        (422, .invalidRequest("nope")),
        (500, .server(status: 500, message: "nope")),
    ])
    func mapsHTTPErrors(status: Int, expected: PaperclipError) async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(#"{"error":"nope"}"#, status: status)])
        let client = PaperclipClient(baseURL: server.baseURL, session: server.session)

        await #expect(throws: expected) { try await client.boardSession() }
    }

    @Test func keepsMessageEmptyForNonJSONErrorBodies() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .init(status: 502, body: Data("<html>Bad gateway</html>".utf8))])
        let client = PaperclipClient(baseURL: server.baseURL, session: server.session)

        await #expect(throws: PaperclipError.server(status: 502, message: nil)) { try await client.boardSession() }
    }

    @Test func mapsUndecodableBodiesToDecodingError() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(#"{"unexpected":true}"#)])
        let client = PaperclipClient(baseURL: server.baseURL, session: server.session)

        await #expect {
            try await client.boardSession()
        } throws: { error in
            if case .decoding = error as? PaperclipError {
                true
            } else {
                false
            }
        }
    }

    @Test func mapsNetworkFailuresToTransportError() async throws {
        let client = try PaperclipClient(baseURL: #require(URL(string: "https://unregistered.paperclip.test")), session: StubURLProtocol.session)

        await #expect(throws: PaperclipError.transport(.cannotFindHost)) { try await client.boardSession() }
    }

    @Test(arguments: [
        ("paperclip.example.com", "https://paperclip.example.com"),
        ("http://localhost:3100", "http://localhost:3100"),
        ("http://localhost:3100/", "http://localhost:3100"),
        ("https://pc.example.com/api", "https://pc.example.com"),
        ("https://pc.example.com/api/", "https://pc.example.com"),
        ("  https://pc.example.com/base  ", "https://pc.example.com/base"),
    ])
    func normalizesServerURLs(input: String, expected: String) {
        #expect(PaperclipClient.normalizedServerURL(input)?.absoluteString == expected)
    }

    @Test(arguments: ["", "   ", "ftp://example.com", "https://"])
    func rejectsInvalidServerURLs(input: String) {
        #expect(PaperclipClient.normalizedServerURL(input) == nil)
    }

    @Test func startsBrowserSignIn() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [
            "POST /api/cli-auth/challenges": .json("""
            {
              "id": "6c0f6f3e-0a3c-4d1c-9a43-2c5d3f3b9e11", "token": "pcp_cli_auth_abc", "boardApiToken": "pcp_board_new",
              "approvalPath": "/cli-auth/6c0f6f3e-0a3c-4d1c-9a43-2c5d3f3b9e11?token=pcp_cli_auth_abc", "approvalUrl": null,
              "pollPath": "/cli-auth/challenges/6c0f6f3e-0a3c-4d1c-9a43-2c5d3f3b9e11",
              "expiresAt": "2026-11-07T10:10:00.000Z", "suggestedPollIntervalMs": 1000
            }
            """, status: 201),
        ], recorder: recorder)
        let client = PaperclipClient(baseURL: server.baseURL, session: server.session)

        let challenge = try await client.startSignIn(clientName: "Fabrix on iPhone")

        #expect(challenge.serverURL == server.baseURL)
        #expect(challenge.id == "6c0f6f3e-0a3c-4d1c-9a43-2c5d3f3b9e11")
        #expect(challenge.boardAPIToken == "pcp_board_new")
        #expect(challenge.approvalURL.absoluteString == "\(server.baseURL.absoluteString)/cli-auth/6c0f6f3e-0a3c-4d1c-9a43-2c5d3f3b9e11?token=pcp_cli_auth_abc")
        #expect(challenge.pollInterval == .seconds(1))
        let body = try #require(recorder.last("POST", "/api/cli-auth/challenges")?.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json == ["command": "fabrix connect", "clientName": "Fabrix on iPhone"])
    }

    @Test(arguments: [
        ("pending", SignInChallenge.Status.pending),
        ("approved", .approved),
        ("cancelled", .cancelled),
        ("expired", .expired),
    ])
    func pollsBrowserSignIn(raw: String, expected: SignInChallenge.Status) async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [
            "GET /api/cli-auth/challenges/ch-1": .json(#"{"id":"ch-1","status":"\#(raw)","requiresSignIn":true,"canApprove":false}"#),
        ], recorder: recorder)
        let client = PaperclipClient(baseURL: server.baseURL, session: server.session)
        let challenge = SignInChallenge(serverURL: server.baseURL, id: "ch-1", token: "pcp_cli_auth_abc", boardAPIToken: "pcp_board_new", approvalURL: server.baseURL, pollInterval: .seconds(1))

        #expect(try await client.signInStatus(challenge) == expected)
        #expect(recorder.requests.first?.url?.query() == "token=pcp_cli_auth_abc")
    }

    @Test(arguments: [
        (#"1e19"#, "1e+19"), (#"42"#, "42"), (#"-3"#, "-3"), (#"1.5"#, "1.5"), (#""Designer""#, "Designer"),
    ])
    func rendersJSONValuesAsText(json: String, expected: String) throws {
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))

        #expect(value.text == expected)
    }

    @Test(arguments: [
        ("https://paperclip.example.com", true),
        ("http://localhost:3100", true),
        ("http://127.0.0.1:3100", true),
        ("http://[::1]:3100", true),
        ("http://factory.local", true),
        ("http://paperclip.localhost", true),
        ("http://192.168.1.20:3100", true),
        ("http://10.0.0.5", true),
        ("http://172.16.4.2", true),
        ("http://100.101.102.103", true),
        ("http://[fd12:3456::1]", true),
        ("http://paperclip.example.com", false),
        ("http://8.8.8.8", false),
        ("http://172.32.0.1", false),
        ("http://100.128.0.1", false),
        ("http://192.168.attacker.1.1.example.com", false),
        ("http://10.0.0.5.example.com", false),
        ("http://192.168.1", false),
        ("http://010.8.8.8", false),
        ("http://10.0.0.010", false),
        ("http://192.168.01.1", false),
    ])
    func allowsCredentialsOnlyOverHTTPSOrLocalNetworks(url: String, allowed: Bool) throws {
        #expect(PaperclipClient.allowsCredentials(to: try #require(URL(string: url))) == allowed)
    }

    @Test func refusesToSendCredentialOverRemoteHTTP() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [:], recorder: recorder)
        let client = try PaperclipClient(baseURL: #require(URL(string: "http://paperclip.example.com")), credential: "pcp_board_secret", session: server.session)

        await #expect(throws: PaperclipError.insecureConnection) { try await client.boardSession() }
        #expect(recorder.requests.isEmpty)
    }

    @Test func doesNotFollowRedirectsToAnotherOrigin() async throws {
        let attacker = RequestRecorder()
        let evil = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)], recorder: attacker)
        let downgraded = try #require(URL(string: evil.baseURL.absoluteString.replacingOccurrences(of: "https://", with: "http://")))
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .redirect(to: downgraded.appending(path: "api/cli-auth/me"))])
        let client = PaperclipClient(baseURL: server.baseURL, credential: "pcp_board_secret", session: server.session)

        await #expect {
            try await client.boardSession()
        } throws: { error in
            if case .server(302, _) = error as? PaperclipError { true } else { false }
        }
        #expect(attacker.requests.isEmpty)
    }

    @Test func signInPollingDoesNotFollowRedirectsToAnotherOrigin() async throws {
        let attacker = RequestRecorder()
        let evil = FakeServer(routes: ["GET /api/cli-auth/challenges/ch-1": .json(#"{"id":"ch-1","status":"approved"}"#)], recorder: attacker)
        let downgraded = try #require(URL(string: evil.baseURL.absoluteString.replacingOccurrences(of: "https://", with: "http://")))
        let server = FakeServer(routes: ["GET /api/cli-auth/challenges/ch-1": .redirect(to: downgraded.appending(path: "api/cli-auth/challenges/ch-1"))])
        let client = PaperclipClient(baseURL: server.baseURL, session: server.session)
        let challenge = SignInChallenge(serverURL: server.baseURL, id: "ch-1", token: "pcp_cli_auth_abc", boardAPIToken: "pcp_board_new", approvalURL: server.baseURL, pollInterval: .zero)

        await #expect {
            try await client.signInStatus(challenge)
        } throws: { error in
            if case .server(302, _) = error as? PaperclipError { true } else { false }
        }
        #expect(attacker.requests.isEmpty)
    }

    @Test func redirectErrorNamesOnlyTheNewOrigin() async throws {
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .redirect(to: URL(string: "https://elsewhere.paperclip.test:8443/api/cli-auth/me?token=pcp_cli_auth_secret")!)])
        let client = PaperclipClient(baseURL: server.baseURL, credential: "pcp_board_secret", session: server.session)

        await #expect(throws: PaperclipError.server(status: 302, message: "The server redirected to https://elsewhere.paperclip.test:8443. Connect to that address instead.")) {
            try await client.boardSession()
        }
    }

    @Test func doesNotFollowADowngradeToHTTPOnTheSameHost() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [:], recorder: recorder, dynamicRoutes: [
            "GET /api/cli-auth/me": { request in
                request.url?.scheme == "https" ? .redirect(to: URL(string: "http://\(request.url!.host()!)/api/cli-auth/me")!) : .json(PaperclipFixtures.me)
            },
        ])
        let client = PaperclipClient(baseURL: server.baseURL, credential: "pcp_board_secret", session: server.session)

        await #expect {
            try await client.boardSession()
        } throws: { error in
            if case .server(302, _) = error as? PaperclipError { true } else { false }
        }
        #expect(recorder.requests.map { $0.url?.scheme } == ["https"])
    }

    @Test(arguments: [
        ("https://paperclip.test/a", "https://paperclip.test/b", true),
        ("https://paperclip.test/a", "https://PaperClip.TEST/b", true),
        ("https://paperclip.test/a", "https://paperclip.test:443/b", true),
        ("http://paperclip.test:80/a", "http://paperclip.test/b", true),
        ("HTTPS://paperclip.test/a", "https://paperclip.test/b", true),
        ("https://paperclip.test/a", "http://paperclip.test/b", false),
        ("https://paperclip.test/a", "https://paperclip.test:8443/b", false),
        ("https://paperclip.test/a", "https://evil.test/b", false),
        ("https://paperclip.test/a", "https://evil.paperclip.test/b", false),
    ])
    func comparesRedirectOrigins(from: String, to: String, sameOrigin: Bool) throws {
        let from = try #require(URL(string: from))
        let to = try #require(URL(string: to))
        #expect((SameOriginRedirects.Origin(from) == SameOriginRedirects.Origin(to)) == sameOrigin)
    }

    @Test(arguments: [
        ("https://paperclip.test/api/x?token=1", "https://paperclip.test"),
        ("https://paperclip.test:443/x", "https://paperclip.test"),
        ("https://Paperclip.test:8443/x", "https://paperclip.test:8443"),
        ("http://[fd00::1]:3100/x", "http://[fd00::1]:3100"),
    ])
    func describesOriginWithoutPathOrDefaultPort(url: String, expected: String) throws {
        #expect(try SameOriginRedirects.Origin(#require(URL(string: url))).description == expected)
    }

    @Test func followsRedirectsWithinTheSameOrigin() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(PaperclipFixtures.me)], recorder: recorder, dynamicRoutes: [
            "GET /api/old/me": { request in .redirect(to: URL(string: "https://\(request.url!.host()!)/api/cli-auth/me")!) },
        ])
        let client = PaperclipClient(baseURL: server.baseURL, credential: "pcp_board_secret", session: server.session)

        let me: BoardMeDTO = try await client.get("old/me")

        #expect(me.userId == "u-1")
        #expect(recorder.last("GET", "/api/cli-auth/me")?.value(forHTTPHeaderField: "Authorization") == "Bearer pcp_board_secret")
    }

    @Test func refusesSignInPollingOverRemoteHTTP() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [:], recorder: recorder)
        let remote = try #require(URL(string: "http://paperclip.example.com"))
        let client = PaperclipClient(baseURL: remote, session: server.session)
        let challenge = SignInChallenge(serverURL: remote, id: "ch-1", token: "pcp_cli_auth_abc", boardAPIToken: "pcp_board_new", approvalURL: remote, pollInterval: .zero)

        await #expect(throws: PaperclipError.insecureConnection) { try await client.signInStatus(challenge) }
        #expect(recorder.requests.isEmpty)
    }

    @Test func refusesBrowserSignInOverRemoteHTTP() async throws {
        let client = try PaperclipClient(baseURL: #require(URL(string: "http://paperclip.example.com")), session: StubURLProtocol.session)

        await #expect(throws: PaperclipError.insecureConnection) { try await client.startSignIn(clientName: "Fabrix") }
    }

    @Test func retriesOnceAfterRefreshOn401() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [:], recorder: recorder, dynamicRoutes: ["GET /api/cli-auth/me": { request in
            request.value(forHTTPHeaderField: "Authorization") == "fresh"
                ? .json(PaperclipFixtures.me)
                : .json(#"{"error":"expired"}"#, status: 401)
        }])
        let auth = RotatingTokenAuth(tokens: ["stale", "fresh"])
        let client = PaperclipClient(baseURL: server.baseURL, auth: auth, session: server.session)

        _ = try await client.boardSession()

        #expect(recorder.requests.map { $0.value(forHTTPHeaderField: "Authorization") } == ["stale", "fresh"])
        #expect(auth.refreshes == 1)
    }

    @Test func doesNotRetryWhenNothingRefreshed() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(#"{"error":"expired"}"#, status: 401)], recorder: recorder)
        let auth = RotatingTokenAuth(tokens: ["stale"])
        let client = PaperclipClient(baseURL: server.baseURL, auth: auth, session: server.session)

        await #expect(throws: PaperclipError.unauthorized("expired")) { try await client.boardSession() }
        #expect(recorder.requests.count == 1)
    }

    @Test func retriesAtMostOnce() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["GET /api/cli-auth/me": .json(#"{"error":"expired"}"#, status: 401)], recorder: recorder)
        let auth = RotatingTokenAuth(tokens: ["a", "b", "c"])
        let client = PaperclipClient(baseURL: server.baseURL, auth: auth, session: server.session)

        await #expect(throws: PaperclipError.unauthorized("expired")) { try await client.boardSession() }
        #expect(recorder.requests.count == 2)
    }

    @Test func refusesAnyProviderCredentialOverRemoteHTTP() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [:], recorder: recorder)
        let auth = RotatingTokenAuth(header: "X-Forwarded-Access-Token", tokens: ["Bearer oidc"])
        let client = try PaperclipClient(baseURL: #require(URL(string: "http://paperclip.example.com")), auth: auth, session: server.session)

        await #expect(throws: PaperclipError.insecureConnection) { try await client.boardSession() }
        #expect(recorder.requests.isEmpty)
    }

    @Test func allowsUnauthenticatedRequestsOverRemoteHTTP() async throws {
        let client = try PaperclipClient(baseURL: #require(URL(string: "http://unregistered.paperclip.test")), auth: ChainedAuth([]), session: StubURLProtocol.session)

        await #expect(throws: PaperclipError.transport(.cannotFindHost)) { try await client.boardSession() }
    }
}
