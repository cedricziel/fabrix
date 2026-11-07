import Foundation
import Synchronization

/// Serves canned responses per host, so parallel tests each get their own
/// fake server by using a unique host.
final class StubURLProtocol: URLProtocol {
    struct Response {
        var status: Int
        var body: Data

        static func json(_ string: String, status: Int = 200) -> Response {
            Response(status: status, body: Data(string.utf8))
        }
    }

    typealias Handler = @Sendable (URLRequest) throws -> Response

    private static let handlers = Mutex<[String: Handler]>([:])

    /// A session whose requests all go through this stub.
    static var session: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func register(host: String, handler: @escaping Handler) {
        handlers.withLock { $0[host] = handler }
    }

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let host = request.url?.host, let handler = Self.handlers.withLock({ $0[host] }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
            return
        }
        do {
            var request = request
            if request.httpBody == nil, let stream = request.httpBodyStream {
                request.httpBody = Data(reading: stream)
            }
            let response = try handler(request)
            let http = HTTPURLResponse(url: request.url!, statusCode: response.status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: response.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension Data {
    init(reading stream: InputStream) {
        self.init()
        stream.open()
        defer { stream.close() }
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            append(buffer, count: count)
        }
    }
}

/// A fake Paperclip server on its own host. Routes are "METHOD /path" without the query.
struct FakeServer {
    let baseURL: URL
    let session: URLSession

    init(routes: [String: StubURLProtocol.Response], recorder: RequestRecorder? = nil, dynamicRoutes: [String: StubURLProtocol.Handler] = [:]) {
        let host = "\(UUID().uuidString.lowercased()).paperclip.test"
        baseURL = URL(string: "https://\(host)")!
        session = StubURLProtocol.session
        StubURLProtocol.register(host: host) { request in
            recorder?.record(request)
            let key = "\(request.httpMethod ?? "GET") \(request.url!.path())"
            if let handler = dynamicRoutes[key] { return try handler(request) }
            return routes[key] ?? .json(#"{"error":"No route for \#(key)"}"#, status: 404)
        }
    }
}

final class RequestRecorder: Sendable {
    private let storage = Mutex<[URLRequest]>([])

    func record(_ request: URLRequest) {
        storage.withLock { $0.append(request) }
    }

    var requests: [URLRequest] {
        storage.withLock { $0 }
    }

    func last(_ method: String, _ path: String) -> URLRequest? {
        requests.last { $0.httpMethod == method && $0.url?.path() == path }
    }
}
