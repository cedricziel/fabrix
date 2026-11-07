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
    /// A 401 from a reverse proxy: not Paperclip's JSON error shape.
    static func fromProxy(sentWith header: String = "Authorization", value: String? = nil) -> UnauthorizedResponse {
        var request = URLRequest(url: URL(string: "https://paperclip.test/api/companies")!)
        request.setValue(value, forHTTPHeaderField: header)
        return UnauthorizedResponse(request: request, body: Data("<html>401 Unauthorized</html>".utf8))
    }

    /// A 401 from Paperclip itself, e.g. a revoked board key.
    static func fromPaperclip(sentWith header: String = "Authorization", value: String? = nil) -> UnauthorizedResponse {
        var request = URLRequest(url: URL(string: "https://paperclip.test/api/companies")!)
        request.setValue(value, forHTTPHeaderField: header)
        return UnauthorizedResponse(request: request, body: Data(#"{"error":"Board authentication required"}"#.utf8))
    }
}
