import Foundation

/// How to sign in to an OIDC provider, saved per factory.
public struct OIDCSettings: Codable, Hashable, Sendable {
    public var issuer: URL
    public var clientID: String
    /// Must use a custom scheme the app handles, e.g. `com.cedricziel.fabrix:/oauth/callback`.
    public var redirectURI: URL
    public var scopes: [String]
    /// Header that carries `Bearer <access token>`. Use another header when a Paperclip board key
    /// needs `Authorization`, for example `X-Forwarded-Access-Token`.
    public var tokenHeader: String

    public init(
        issuer: URL, clientID: String, redirectURI: URL,
        scopes: [String] = ["openid", "profile", "offline_access"], tokenHeader: String = "Authorization"
    ) {
        self.issuer = issuer
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.tokenHeader = tokenHeader
    }
}

/// Shows a login page and returns the URL the provider redirected to.
/// In the app, wrap SwiftUI's `@Environment(\.webAuthenticationSession)`.
public protocol WebAuthenticator: Sendable {
    func authenticate(url: URL, callbackScheme: String) async throws -> URL
}

public struct OIDCTokens: Codable, Hashable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresAt: Date?
    public var tokenEndpoint: URL
}

public enum OIDCError: Error, Equatable, Sendable {
    case discoveryFailed
    case stateMismatch
    case missingCode
    /// An OAuth error from the authorize redirect or the token endpoint, e.g. `invalid_grant`.
    case provider(code: String, description: String?)
    case invalidResponse
}

extension OIDCError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .discoveryFailed: "Couldn't read the sign-in provider's configuration. Check the issuer address."
        case .stateMismatch: "The sign-in response didn't match the request. Try again."
        case .missingCode: "The sign-in provider didn't return an authorization code."
        case let .provider(code, description): description ?? "The sign-in provider refused the request (\(code))."
        case .invalidResponse: "The sign-in provider sent a response Fabrix doesn't understand."
        }
    }
}

struct OIDCEndpoints: Equatable {
    var authorization: URL
    var token: URL
}

/// Authorization Code + PKCE against an OIDC provider, plus token refresh.
struct OIDCFlow: Sendable {
    let settings: OIDCSettings
    let session: URLSession
    var now: @Sendable () -> Date = { .now }

    func discover() async throws -> OIDCEndpoints {
        struct Discovery: Decodable {
            var authorization_endpoint: URL
            var token_endpoint: URL
        }
        let url = settings.issuer.appending(path: ".well-known/openid-configuration")
        guard let (data, response) = try? await session.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let discovery = try? JSONDecoder().decode(Discovery.self, from: data)
        else { throw OIDCError.discoveryFailed }
        return OIDCEndpoints(authorization: discovery.authorization_endpoint, token: discovery.token_endpoint)
    }

    func signIn(using authenticator: any WebAuthenticator) async throws -> OIDCTokens {
        let endpoints = try await discover()
        let pkce = PKCE.generate()
        let state = PKCE.randomURLSafeString(byteCount: 16)

        var authorize = URLComponents(url: endpoints.authorization, resolvingAgainstBaseURL: false)!
        authorize.queryItems = (authorize.queryItems ?? []) + [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: settings.clientID),
            URLQueryItem(name: "redirect_uri", value: settings.redirectURI.absoluteString),
            URLQueryItem(name: "scope", value: settings.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        guard let authorizeURL = authorize.url else { throw OIDCError.discoveryFailed }

        let callback = try await authenticator.authenticate(url: authorizeURL, callbackScheme: settings.redirectURI.scheme ?? "")
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        if let error = value("error") {
            throw OIDCError.provider(code: error, description: value("error_description"))
        }
        guard value("state") == state else { throw OIDCError.stateMismatch }
        guard let code = value("code") else { throw OIDCError.missingCode }

        return try await requestTokens(endpoint: endpoints.token, previousRefreshToken: nil, form: [
            ("grant_type", "authorization_code"),
            ("code", code),
            ("redirect_uri", settings.redirectURI.absoluteString),
            ("client_id", settings.clientID),
            ("code_verifier", pkce.verifier),
        ])
    }

    /// Uses the refresh token; keeps it when the provider doesn't rotate it.
    func refresh(_ tokens: OIDCTokens) async throws -> OIDCTokens {
        guard let refreshToken = tokens.refreshToken else {
            throw OIDCError.provider(code: "invalid_grant", description: "No refresh token. Sign in again.")
        }
        return try await requestTokens(endpoint: tokens.tokenEndpoint, previousRefreshToken: refreshToken, form: [
            ("grant_type", "refresh_token"),
            ("refresh_token", refreshToken),
            ("client_id", settings.clientID),
        ])
    }

    private func requestTokens(endpoint: URL, previousRefreshToken: String?, form: [(String, String)]) async throws -> OIDCTokens {
        struct TokenResponse: Decodable {
            var access_token: String
            var refresh_token: String?
            var expires_in: Double?
        }
        struct ErrorResponse: Decodable {
            var error: String
            var error_description: String?
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(form.map { "\($0)=\(Self.formEncode($1))" }.joined(separator: "&").utf8)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw PaperclipError.transport(error.code)
        }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let error = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OIDCError.provider(code: error?.error ?? "server_error", description: error?.error_description)
        }
        guard let tokens = try? JSONDecoder().decode(TokenResponse.self, from: data) else { throw OIDCError.invalidResponse }
        return OIDCTokens(
            accessToken: tokens.access_token,
            refreshToken: tokens.refresh_token ?? previousRefreshToken,
            expiresAt: tokens.expires_in.map { now() + $0 },
            tokenEndpoint: endpoint
        )
    }

    private static let formAllowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))

    private static func formEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? value
    }
}
