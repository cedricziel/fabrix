import Foundation

/// The board user a credential belongs to.
public struct BoardSession: Hashable, Sendable {
    public var userID: String
    public var userName: String?
    public var companyIDs: [String]
    public var isInstanceAdmin: Bool

    public init(userID: String, userName: String?, companyIDs: [String], isInstanceAdmin: Bool) {
        self.userID = userID
        self.userName = userName
        self.companyIDs = companyIDs
        self.isInstanceAdmin = isInstanceAdmin
    }
}

/// A pending browser sign-in. Open `approvalURL` in a browser; once the user approves,
/// `boardAPIToken` becomes a valid credential.
public struct SignInChallenge: Hashable, Sendable {
    public enum Status: String, Sendable {
        case pending, approved, cancelled, expired
    }

    /// Server root the challenge belongs to.
    public var serverURL: URL
    public var id: String
    public var token: String
    public var boardAPIToken: String
    public var approvalURL: URL
    public var pollInterval: Duration
    /// When the server stops accepting approval for this request.
    public var expiresAt: Date?
    /// The OIDC front door the challenge was started behind, if any.
    public var frontDoor: OIDCSettings?
    var oidcTokens: OIDCTokens?
    var customHeaders: [CustomHeader] = []

    public init(
        serverURL: URL, id: String, token: String, boardAPIToken: String, approvalURL: URL, pollInterval: Duration, expiresAt: Date? = nil
    ) {
        self.serverURL = serverURL
        self.id = id
        self.token = token
        self.boardAPIToken = boardAPIToken
        self.approvalURL = approvalURL
        self.pollInterval = pollInterval
        self.expiresAt = expiresAt
    }
}

/// HTTP client for one Paperclip server, acting as a board user.
public struct PaperclipClient: Sendable {
    /// Server root, without the `/api` suffix.
    public let baseURL: URL
    private let auth: any AuthProvider
    private let session: URLSession

    public init(baseURL: URL, auth: any AuthProvider = NoAuth(), session: URLSession = .shared) {
        self.baseURL = baseURL
        self.auth = auth
        self.session = session
    }

    /// A client that sends `credential` as a bearer token, or nothing when it is nil.
    public init(baseURL: URL, credential: String?, session: URLSession = .shared) {
        self.init(baseURL: baseURL, auth: credential.map { BearerTokenAuth(token: $0) } ?? NoAuth(), session: session)
    }

    /// Turns user input like `paperclip.example.com` or `http://host:3100/api/` into a server root URL.
    public static func normalizedServerURL(_ input: String) -> URL? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if !text.contains("://") {
            text = "https://" + text
        }
        guard var components = URLComponents(string: text),
              let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = components.host, !host.isEmpty
        else { return nil }
        var path = components.path
        while path.hasSuffix("/") {
            path.removeLast()
        }
        if path.hasSuffix("/api") {
            path.removeLast(4)
        }
        components.path = path
        components.query = nil
        components.fragment = nil
        return components.url
    }

    /// `normalizedServerURL`, throwing `PaperclipError.invalidServerURL` for unusable input.
    public static func serverURL(_ url: URL) throws -> URL {
        guard let serverURL = normalizedServerURL(url.absoluteString) else { throw PaperclipError.invalidServerURL }
        return serverURL
    }

    public func boardSession() async throws -> BoardSession {
        let me: BoardMeDTO = try await get("cli-auth/me")
        return BoardSession(userID: me.userId, userName: me.user?.name, companyIDs: me.companyIds ?? [], isInstanceAdmin: me.isInstanceAdmin ?? false)
    }

    /// Whether credentials may be sent to `url`: always over HTTPS, and over plain HTTP only to this
    /// machine or a private network (loopback, `.local`, `.localhost`, RFC 1918, Tailscale's
    /// 100.64.0.0/10, link-local and IPv6 unique-local addresses).
    public static func allowsCredentials(to url: URL) -> Bool {
        if url.scheme?.lowercased() == "https" { return true }
        guard let host = url.normalizedHost else { return false }
        if host == "localhost" || host.hasSuffix(".localhost") || host.hasSuffix(".local") { return true }
        if host == "::1" || host.hasPrefix("fe80:") || host.hasPrefix("fc") || host.hasPrefix("fd") { return host.contains(":") }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        // Resolvers read a leading zero as octal (010 is 8), so only plain decimal octets count.
        let octets = labels.compactMap { label -> UInt8? in
            guard label.allSatisfy(\.isASCII), label.allSatisfy(\.isNumber), label == "0" || !label.hasPrefix("0") else { return nil }
            return UInt8(label)
        }
        guard labels.count == 4, octets.count == 4 else { return false }
        switch (octets[0], octets[1]) {
        case (127, _), (10, _), (192, 168), (169, 254): return true
        case (172, 16 ... 31): return true
        case (100, 64 ... 127): return true
        default: return false
        }
    }

    /// The approval response carries a new board key, so it must not cross an untrusted network in clear text.
    public func startSignIn(clientName: String) async throws -> SignInChallenge {
        guard Self.allowsCredentials(to: baseURL) else { throw PaperclipError.insecureConnection }
        let created: SignInChallengeCreatedDTO = try await send("POST", "cli-auth/challenges", body: ["command": "fabrix connect", "clientName": clientName])
        // Behind a proxy the server may report its internal address; the user's browser needs the factory's own.
        let reported = created.approvalUrl.flatMap(URL.init(string:))
            .flatMap { SameOriginRedirects.Origin($0) == SameOriginRedirects.Origin(baseURL) ? $0 : nil }
        guard let approvalURL = reported ?? URL(string: baseURL.absoluteString + created.approvalPath) else {
            throw PaperclipError.decoding("The server sent an unusable approval link.")
        }
        return SignInChallenge(
            serverURL: baseURL, id: created.id, token: created.token, boardAPIToken: created.boardApiToken,
            approvalURL: approvalURL, pollInterval: .milliseconds(created.suggestedPollIntervalMs ?? 1000), expiresAt: created.expiresAt
        )
    }

    /// The poll sends the challenge token, so it follows the same transport rule as sign-in.
    public func signInStatus(_ challenge: SignInChallenge) async throws -> SignInChallenge.Status {
        guard Self.allowsCredentials(to: baseURL) else { throw PaperclipError.insecureConnection }
        let status: SignInChallengeStatusDTO = try await get("cli-auth/challenges/\(challenge.id)", query: ["token": challenge.token])
        return SignInChallenge.Status(rawValue: status.status) ?? .pending
    }

    /// When the board key in use expires, or nil when the request used no key or the server doesn't say.
    public func boardKeyExpiry() async throws -> Date? {
        let me: BoardMeDTO = try await get("cli-auth/me")
        guard let keyID = me.keyId else { return nil }
        do {
            let keys: [BoardAPIKeyDTO] = try await get("board-api-keys")
            return keys.first { $0.id == keyID }?.expiresAt
        } catch PaperclipError.forbidden, PaperclipError.notFound {
            return nil
        }
    }

    // MARK: - Requests

    func get<Response: Decodable>(_ path: String, query: KeyValuePairs<String, String> = [:]) async throws -> Response {
        try await decode(perform("GET", path, query: query, body: nil))
    }

    func send<Response: Decodable>(_ method: String, _ path: String, body: some Encodable) async throws -> Response {
        try await decode(perform(method, path, query: [:], body: Self.encoder.encode(body)))
    }

    /// Sends a request whose response body Fabrix doesn't need.
    func send(_ method: String, _ path: String, body: some Encodable = [String: String]()) async throws {
        _ = try await perform(method, path, query: [:], body: Self.encoder.encode(body))
    }

    private func perform(_ method: String, _ path: String, query: KeyValuePairs<String, String>, body: Data?) async throws -> Data {
        var url = baseURL.appending(path: "api").appending(path: path)
        if !query.isEmpty {
            url.append(queryItems: query.map { URLQueryItem(name: $0.key, value: $0.value) })
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let authorized = try await auth.authorize(request)
        // Any header the provider added is a credential; keep it off untrusted plain-HTTP hops.
        if authorized.allHTTPHeaderFields != request.allHTTPHeaderFields, !Self.allowsCredentials(to: baseURL) {
            throw PaperclipError.insecureConnection
        }
        var (data, response) = try await load(authorized)
        if response?.statusCode == 401,
           try await auth.refreshAfterUnauthorized(UnauthorizedResponse(request: authorized, response: response, body: data)) {
            (data, response) = try await load(auth.authorize(request))
        }
        let status = response?.statusCode ?? 0
        if let origin = SameOriginRedirects.refusedOrigin(response) {
            throw PaperclipError.server(status: status, message: "The server redirected to \(origin). Connect to that address instead.")
        }
        guard (200 ..< 300).contains(status) else {
            let message = try? JSONDecoder().decode(ErrorBodyDTO.self, from: data).error
            throw PaperclipError(status: status, message: message)
        }
        return data
    }

    private func load(_ request: URLRequest) async throws -> (Data, HTTPURLResponse?) {
        try await SameOriginRedirects.load(request, session: session)
    }

    private func decode<Response: Decodable>(_ data: Data) throws -> Response {
        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            throw PaperclipError.decoding(String(describing: error))
        }
    }

    private static let encoder = JSONEncoder()
    private static let fractionalDates = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let wholeSecondDates = Date.ISO8601FormatStyle()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = (try? Date(text, strategy: fractionalDates)) ?? (try? Date(text, strategy: wholeSecondDates)) {
                return date
            }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not an ISO 8601 date: \(text)"))
        }
        return decoder
    }()
}

/// Follows redirects only within the server's origin (scheme, host and port). A redirect elsewhere
/// could carry the board key or a sign-in token to another host, or downgrade HTTPS to HTTP.
final class SameOriginRedirects: NSObject, URLSessionTaskDelegate, Sendable {
    static let shared = SameOriginRedirects()

    func urlSession(
        _: URLSession, task _: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        guard let from = response.url, let to = request.url else { return nil }
        return Origin(from) == Origin(to) ? request : nil
    }

    /// Loads `request` under this redirect rule, reporting network failures as `PaperclipError.transport`.
    static func load(_ request: URLRequest, session: URLSession) async throws -> (Data, HTTPURLResponse?) {
        do {
            let (data, response) = try await session.data(for: request, delegate: shared)
            return (data, response as? HTTPURLResponse)
        } catch let error as URLError {
            throw PaperclipError.transport(error.code)
        }
    }

    /// Where a refused redirect pointed. Error messages show only this, since the full URL can carry tokens.
    static func refusedOrigin(_ response: HTTPURLResponse?) -> Origin? {
        guard let response, (300 ..< 400).contains(response.statusCode),
              let location = response.value(forHTTPHeaderField: "Location"),
              let target = URL(string: location, relativeTo: response.url)
        else { return nil }
        return Origin(target.absoluteURL)
    }

    struct Origin: Equatable, CustomStringConvertible {
        let scheme: String
        let host: String
        let port: Int

        init(_ url: URL) {
            scheme = url.scheme?.lowercased() ?? ""
            host = url.normalizedHost ?? ""
            port = url.port ?? Self.defaultPort(scheme)
        }

        var description: String {
            let host = host.contains(":") ? "[\(host)]" : host
            return port == Self.defaultPort(scheme) ? "\(scheme)://\(host)" : "\(scheme)://\(host):\(port)"
        }

        private static func defaultPort(_ scheme: String) -> Int {
            scheme == "https" ? 443 : 80
        }
    }
}

extension URL {
    /// Lowercased host without IPv6 brackets.
    var normalizedHost: String? {
        host()?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    }
}
