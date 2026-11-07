import FabrixCore
import Foundation

/// Why the open factory can't be refreshed. Unlike an action error, this describes the
/// connection as a whole: it stays until a refresh succeeds and changes only when its kind does.
enum ConnectionIssue: Hashable, Sendable {
    /// The server didn't answer: offline, wrong address, DNS, TLS or a timeout.
    case unreachable
    /// The credentials stopped working: an expired or revoked board key, or a rejected OIDC refresh.
    case signedOut
    /// The server answered but this board user may not see the factory or company.
    case noAccess
    /// The server answered with an error of its own; `status` is the HTTP status when known.
    case serverProblem(status: Int?)
    /// The server's responses don't match what Fabrix understands.
    case unsupported

    /// Nil for cancellations, which are not problems.
    init?(classifying error: any Error) {
        switch error {
        case is CancellationError:
            return nil
        case let error as URLError:
            guard error.code != .cancelled else { return nil }
            self = .unreachable
        case let error as PaperclipError:
            switch error {
            case .transport(.cancelled): return nil
            case .transport, .invalidServerURL, .insecureConnection: self = .unreachable
            case .unauthorized, .signInCancelled, .signInExpired, .signInRequired, .missingHeaderValues:
                self = .signedOut
            case .forbidden: self = .noAccess
            case .decoding: self = .unsupported
            case .invalidRequest: self = .serverProblem(status: 400)
            case .notFound: self = .serverProblem(status: 404)
            case .conflict: self = .serverProblem(status: 409)
            case let .server(status, _): self = .serverProblem(status: status)
            case .invalidAuthConfiguration: self = .signedOut
            }
        default:
            self = .serverProblem(status: nil)
        }
    }
}

/// A connection issue and the text the server or system gave for it.
struct ConnectionProblem: Hashable, Sendable {
    var issue: ConnectionIssue
    var detail: String
}
