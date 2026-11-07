import Foundation
import Synchronization
@testable import FabrixCore

/// An in-memory credential store whose writes can be made to fail.
final class FlakyCredentialStore: CredentialStore {
    private let inner = InMemoryCredentialStore()
    private let failing = Mutex<(Factory.ID) -> Bool>({ _ in false })

    func failWrites(where predicate: @escaping @Sendable (Factory.ID) -> Bool) {
        failing.withLock { $0 = predicate }
    }

    func credential(for factoryID: Factory.ID) throws -> String? {
        try inner.credential(for: factoryID)
    }

    func setCredential(_ credential: String?, for factoryID: Factory.ID) throws {
        if failing.withLock({ $0(factoryID) }) { throw KeychainError(status: errSecInteractionNotAllowed) }
        try inner.setCredential(credential, for: factoryID)
    }

    var isEmpty: Bool {
        inner.isEmpty
    }
}

extension UnauthorizedResponse {
    private static func make(header: String, value: String?, body: String, responseHeaders: [String: String]) -> UnauthorizedResponse {
        let url = URL(string: "https://paperclip.test/api/companies")!
        var request = URLRequest(url: url)
        request.setValue(value, forHTTPHeaderField: header)
        let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: responseHeaders)
        return UnauthorizedResponse(request: request, response: response, body: Data(body.utf8))
    }

    /// A 401 from a reverse proxy that answers with a page.
    static func fromProxy(sentWith header: String = "Authorization", value: String? = nil) -> UnauthorizedResponse {
        make(header: header, value: value, body: "<html>401 Unauthorized</html>", responseHeaders: ["Content-Type": "text/html"])
    }

    /// A 401 from JWT middleware in a proxy: Paperclip-like JSON, but with `WWW-Authenticate`.
    static func fromJWTProxy(sentWith header: String = "Authorization", value: String? = nil) -> UnauthorizedResponse {
        make(header: header, value: value, body: #"{"error":"invalid_token"}"#, responseHeaders: [
            "Content-Type": "application/json", "WWW-Authenticate": #"Bearer error="invalid_token""#,
        ])
    }

    /// A 401 from Paperclip itself, e.g. a revoked board key.
    static func fromPaperclip(sentWith header: String = "Authorization", value: String? = nil) -> UnauthorizedResponse {
        make(header: header, value: value, body: #"{"error":"Board authentication required"}"#, responseHeaders: ["Content-Type": "application/json"])
    }
}
