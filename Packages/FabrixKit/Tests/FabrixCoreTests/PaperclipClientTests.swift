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
}
