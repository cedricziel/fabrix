@testable import FabrixCore
import Foundation
import Synchronization
import Testing

/// Plays the browser: records the authorize URL and answers with a callback built from it.
final class FakeWebAuthenticator: WebAuthenticator {
    private let opened = Mutex<[URL]>([])
    private let respond: @Sendable (URLComponents) throws -> URL

    init(respond: @escaping @Sendable (URLComponents) throws -> URL) {
        self.respond = respond
    }

    /// Approves the login and echoes `state`, like a well-behaved provider.
    static func approving(code: String = "auth-code") -> FakeWebAuthenticator {
        FakeWebAuthenticator { authorize in
            let state = authorize.queryItems?.first { $0.name == "state" }?.value ?? ""
            return URL(string: "com.cedricziel.fabrix:/oauth/callback?code=\(code)&state=\(state)")!
        }
    }

    var authorizeURL: URLComponents? {
        opened.withLock { $0.last }.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
    }

    func authenticate(url: URL, callbackScheme _: String) async throws -> URL {
        opened.withLock { $0.append(url) }
        return try respond(URLComponents(url: url, resolvingAgainstBaseURL: false)!)
    }
}

enum OIDCFixtures {
    static func discovery(issuer: URL) -> String {
        """
        {
          "issuer": "\(issuer.absoluteString)",
          "authorization_endpoint": "\(issuer.absoluteString)/authorize",
          "token_endpoint": "\(issuer.absoluteString)/token",
          "jwks_uri": "\(issuer.absoluteString)/jwks",
          "response_types_supported": ["code"],
          "code_challenge_methods_supported": ["S256"]
        }
        """
    }

    static func tokens(access: String = "access-1", refresh: String? = "refresh-1", expiresIn: Int = 300) -> String {
        let refreshField = refresh.map { #","refresh_token":"\#($0)""# } ?? ""
        return #"{"access_token":"\#(access)","token_type":"Bearer","expires_in":\#(expiresIn)\#(refreshField),"id_token":"x.y.z"}"#
    }

    static func settings(issuer: URL, tokenHeader: String = "Authorization") -> OIDCSettings {
        OIDCSettings(issuer: issuer, clientID: "fabrix", redirectURI: URL(string: "com.cedricziel.fabrix:/oauth/callback")!, tokenHeader: tokenHeader)
    }
}

func formFields(_ request: URLRequest?) -> [String: String] {
    guard let body = request?.httpBody, let components = URLComponents(string: "?" + String(decoding: body, as: UTF8.self)) else { return [:] }
    return Dictionary((components.queryItems ?? []).map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last })
}

struct OIDCFlowTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func pkceChallengeIsS256OfVerifier() {
        // RFC 7636, appendix B.
        #expect(PKCE.challenge(for: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk") == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test func generatedVerifiersAreLongUniqueAndURLSafe() {
        let first = PKCE.generate().verifier
        let second = PKCE.generate().verifier

        #expect(first != second)
        #expect(first.count >= 43)
        #expect(first.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
    }

    @Test func discoversEndpoints() async throws {
        let server = FakeServer(routes: [:], dynamicRoutes: ["GET /.well-known/openid-configuration": { request in
            .json(OIDCFixtures.discovery(issuer: URL(string: "https://\(request.url!.host()!)")!))
        }])
        let flow = OIDCFlow(settings: OIDCFixtures.settings(issuer: server.baseURL), session: server.session)

        let endpoints = try await flow.discover()

        #expect(endpoints.authorization == server.baseURL.appending(path: "authorize"))
        #expect(endpoints.token == server.baseURL.appending(path: "token"))
    }

    @Test func discoveryKeepsIssuerPath() async {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: [:], recorder: recorder)
        let issuer = server.baseURL.appending(path: "realms/home")
        let flow = OIDCFlow(settings: OIDCFixtures.settings(issuer: issuer), session: server.session)

        _ = try? await flow.discover()

        #expect(recorder.requests.first?.url?.path() == "/realms/home/.well-known/openid-configuration")
    }

    private func idp(recorder: RequestRecorder, token: StubURLProtocol.Response = .json(OIDCFixtures.tokens())) -> FakeServer {
        FakeServer(routes: ["POST /token": token], recorder: recorder, dynamicRoutes: ["GET /.well-known/openid-configuration": { request in
            .json(OIDCFixtures.discovery(issuer: URL(string: "https://\(request.url!.host()!)")!))
        }])
    }

    @Test func signInExchangesCodeWithVerifier() async throws {
        let recorder = RequestRecorder()
        let server = idp(recorder: recorder)
        let browser = FakeWebAuthenticator.approving(code: "the-code")
        let flow = OIDCFlow(settings: OIDCFixtures.settings(issuer: server.baseURL), session: server.session, now: { now })

        let tokens = try await flow.signIn(using: browser)

        let authorize = try #require(browser.authorizeURL)
        let query = Dictionary(uniqueKeysWithValues: (authorize.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(authorize.path == "/authorize")
        #expect(query["response_type"] == "code")
        #expect(query["client_id"] == "fabrix")
        #expect(query["redirect_uri"] == "com.cedricziel.fabrix:/oauth/callback")
        #expect(query["scope"] == "openid profile offline_access")
        #expect(query["code_challenge_method"] == "S256")

        let form = formFields(recorder.last("POST", "/token"))
        #expect(form["grant_type"] == "authorization_code")
        #expect(form["code"] == "the-code")
        #expect(form["client_id"] == "fabrix")
        #expect(form["redirect_uri"] == "com.cedricziel.fabrix:/oauth/callback")
        #expect(try PKCE.challenge(for: #require(form["code_verifier"])) == query["code_challenge"])

        #expect(tokens == OIDCTokens(accessToken: "access-1", refreshToken: "refresh-1", expiresAt: now + 300, tokenEndpoint: server.baseURL.appending(path: "token")))
    }

    @Test func rejectsMismatchedState() async throws {
        let recorder = RequestRecorder()
        let server = idp(recorder: recorder)
        let browser = FakeWebAuthenticator { _ in URL(string: "com.cedricziel.fabrix:/oauth/callback?code=c&state=forged")! }
        let flow = OIDCFlow(settings: OIDCFixtures.settings(issuer: server.baseURL), session: server.session)

        await #expect(throws: OIDCError.stateMismatch) { try await flow.signIn(using: browser) }
        #expect(recorder.last("POST", "/token") == nil)
    }

    @Test func surfacesProviderError() async throws {
        let recorder = RequestRecorder()
        let server = idp(recorder: recorder)
        let browser = FakeWebAuthenticator { _ in URL(string: "com.cedricziel.fabrix:/oauth/callback?error=access_denied&error_description=User%20said%20no")! }
        let flow = OIDCFlow(settings: OIDCFixtures.settings(issuer: server.baseURL), session: server.session)

        await #expect(throws: OIDCError.provider(code: "access_denied", description: "User said no")) { try await flow.signIn(using: browser) }
        #expect(recorder.last("POST", "/token") == nil)
    }

    @Test func surfacesTokenEndpointError() async throws {
        let server = idp(recorder: RequestRecorder(), token: .json(#"{"error":"invalid_client","error_description":"Unknown client"}"#, status: 401))
        let flow = OIDCFlow(settings: OIDCFixtures.settings(issuer: server.baseURL), session: server.session)

        await #expect(throws: OIDCError.provider(code: "invalid_client", description: "Unknown client")) {
            try await flow.signIn(using: FakeWebAuthenticator.approving())
        }
    }

    @Test func refreshSendsRefreshTokenAndKeepsItWhenNotRotated() async throws {
        let recorder = RequestRecorder()
        let server = FakeServer(routes: ["POST /token": .json(OIDCFixtures.tokens(access: "access-2", refresh: nil, expiresIn: 600))], recorder: recorder)
        let flow = OIDCFlow(settings: OIDCFixtures.settings(issuer: server.baseURL), session: server.session, now: { now })
        let current = OIDCTokens(accessToken: "access-1", refreshToken: "refresh-1", expiresAt: now, tokenEndpoint: server.baseURL.appending(path: "token"))

        let refreshed = try await flow.refresh(current)

        #expect(formFields(recorder.last("POST", "/token")) == ["grant_type": "refresh_token", "refresh_token": "refresh-1", "client_id": "fabrix"])
        #expect(refreshed == OIDCTokens(accessToken: "access-2", refreshToken: "refresh-1", expiresAt: now + 600, tokenEndpoint: current.tokenEndpoint))
    }

    @Test func discoveryNetworkFailureIsTransportError() async throws {
        let flow = OIDCFlow(settings: OIDCFixtures.settings(issuer: URL(string: "https://unregistered-idp.paperclip.test")!), session: StubURLProtocol.session)

        await #expect(throws: PaperclipError.transport(.cannotFindHost)) { try await flow.discover() }
    }

    @Test func refreshDoesNotFollowRedirectsToAnotherOrigin() async throws {
        let attacker = RequestRecorder()
        let evil = FakeServer(routes: ["POST /token": .json(OIDCFixtures.tokens())], recorder: attacker)
        let server = FakeServer(routes: ["POST /token": .redirect(to: evil.baseURL.appending(path: "token"))])
        let flow = OIDCFlow(settings: OIDCFixtures.settings(issuer: server.baseURL), session: server.session)
        let current = OIDCTokens(accessToken: "a", refreshToken: "refresh-1", expiresAt: nil, tokenEndpoint: server.baseURL.appending(path: "token"))

        await #expect(throws: OIDCError.self) { try await flow.refresh(current) }
        #expect(attacker.requests.isEmpty)
    }
}
