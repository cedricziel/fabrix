@testable import FabrixCore
import Foundation
import Synchronization
import Testing

/// Sets a header to the current token; `refreshAfterUnauthorized` swaps to the next one.
final class RotatingTokenAuth: AuthProvider {
    private let state: Mutex<(tokens: [String], refreshes: Int)>
    let header: String

    init(header: String = "Authorization", tokens: [String]) {
        self.header = header
        state = Mutex((tokens, 0))
    }

    var refreshes: Int {
        state.withLock { $0.refreshes }
    }

    func authorize(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue(state.withLock { $0.tokens.first }, forHTTPHeaderField: header)
        return request
    }

    func refreshAfterUnauthorized() async throws -> Bool {
        state.withLock {
            $0.refreshes += 1
            guard $0.tokens.count > 1 else { return false }
            $0.tokens.removeFirst()
            return true
        }
    }
}

struct AuthProviderTests {
    private let request = URLRequest(url: URL(string: "https://paperclip.test/api/companies")!)

    @Test func noAuthLeavesRequestUntouched() async throws {
        let authorized = try await NoAuth().authorize(request)

        #expect(authorized.allHTTPHeaderFields?.isEmpty ?? true)
        #expect(try await NoAuth().refreshAfterUnauthorized() == false)
    }

    @Test func bearerTokenSetsAuthorization() async throws {
        let authorized = try await BearerTokenAuth(token: "pcp_board_abc").authorize(request)

        #expect(authorized.value(forHTTPHeaderField: "Authorization") == "Bearer pcp_board_abc")
        #expect(try await BearerTokenAuth(token: "x").refreshAfterUnauthorized() == false)
    }

    @Test func chainAppliesProvidersInOrder() async throws {
        let chain = ChainedAuth([
            RotatingTokenAuth(header: "X-Forwarded-Access-Token", tokens: ["Bearer oidc"]),
            BearerTokenAuth(token: "pcp_board_abc"),
        ])

        let authorized = try await chain.authorize(request)

        #expect(authorized.value(forHTTPHeaderField: "X-Forwarded-Access-Token") == "Bearer oidc")
        #expect(authorized.value(forHTTPHeaderField: "Authorization") == "Bearer pcp_board_abc")
    }

    @Test func chainRetriesWhenAnyProviderRefreshed() async throws {
        let refreshing = RotatingTokenAuth(tokens: ["a", "b"])
        let chain = ChainedAuth([BearerTokenAuth(token: "k"), refreshing])

        #expect(try await chain.refreshAfterUnauthorized())
        #expect(refreshing.refreshes == 1)
    }

    @Test func chainDoesNotRetryWhenNothingRefreshed() async throws {
        let chain = ChainedAuth([NoAuth(), BearerTokenAuth(token: "k")])

        #expect(try await chain.refreshAfterUnauthorized() == false)
    }
}
