import Foundation

/// Adds credentials to outgoing requests and renews them when the server rejects them.
public protocol AuthProvider: Sendable {
    func authorize(_ request: URLRequest) async throws -> URLRequest
    /// Called after a `401`. Returns true when credentials changed and the request is worth retrying once.
    func refreshAfterUnauthorized(_ failure: UnauthorizedResponse) async throws -> Bool
}

/// A request the server rejected with `401`, as it was sent.
public struct UnauthorizedResponse: Sendable {
    public var request: URLRequest
    public var body: Data

    public init(request: URLRequest, body: Data) {
        self.request = request
        self.body = body
    }

    /// Paperclip answers its own `401`s with `{"error": "…"}` JSON. A reverse proxy in front answers
    /// with a page or redirect instead, so a Paperclip `401` says nothing about the proxy's token.
    public var isFromPaperclip: Bool {
        (try? JSONDecoder().decode(ErrorBodyDTO.self, from: body)) != nil
    }
}

/// No credentials, for Paperclip servers in `local_trusted` mode.
public struct NoAuth: AuthProvider {
    public init() {}

    public func authorize(_ request: URLRequest) async throws -> URLRequest {
        request
    }

    public func refreshAfterUnauthorized(_: UnauthorizedResponse) async throws -> Bool {
        false
    }
}

/// A fixed bearer token, such as a Paperclip board API key.
public struct BearerTokenAuth: AuthProvider {
    public var token: String

    public init(token: String) {
        self.token = token
    }

    public func authorize(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    public func refreshAfterUnauthorized(_: UnauthorizedResponse) async throws -> Bool {
        false
    }
}

/// Applies several providers in order, for example an OIDC token for a reverse proxy
/// followed by a Paperclip board key.
public struct ChainedAuth: AuthProvider {
    public var providers: [any AuthProvider]

    public init(_ providers: [any AuthProvider]) {
        self.providers = providers
    }

    public func authorize(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        for provider in providers {
            request = try await provider.authorize(request)
        }
        return request
    }

    public func refreshAfterUnauthorized(_ failure: UnauthorizedResponse) async throws -> Bool {
        var refreshed = false
        for provider in providers where try await provider.refreshAfterUnauthorized(failure) {
            refreshed = true
        }
        return refreshed
    }
}
