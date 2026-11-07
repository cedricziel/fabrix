import Foundation

/// A failed call to a Paperclip server. Messages come from the server's `{ "error": "…" }` body.
public enum PaperclipError: Error, Equatable, Sendable {
    /// 400 or 422: the request was malformed or not allowed in the current state.
    case invalidRequest(String?)
    /// 401: the credential is missing, invalid, or expired.
    case unauthorized(String?)
    /// 403: the board user lacks access to this company or action.
    case forbidden(String?)
    case notFound(String?)
    /// 409: another actor holds the resource, or the entity is in a conflicting state.
    case conflict(String?)
    case server(status: Int, message: String?)
    case transport(URLError.Code)
    case decoding(String)
    /// The server URL could not be turned into an http(s) URL.
    case invalidServerURL
    /// Credentials would travel over plain HTTP to a host outside this machine or a private network.
    case insecureConnection
    /// The chosen auth configuration can't work, e.g. two layers both need `Authorization`.
    case invalidAuthConfiguration(String)
    /// The browser sign-in was cancelled in Paperclip.
    case signInCancelled
    /// The browser sign-in was not approved in time.
    case signInExpired
    /// The identity provider in front of the factory needs a new login: its refresh token was
    /// rejected, or the saved tokens are missing or unreadable. A Paperclip `401` stays `.unauthorized`.
    case signInRequired(String?)
    /// Custom header names are saved but their values are gone, e.g. after moving to a new device.
    case missingHeaderValues([String])

    init(status: Int, message: String?) {
        switch status {
        case 400, 422: self = .invalidRequest(message)
        case 401: self = .unauthorized(message)
        case 403: self = .forbidden(message)
        case 404: self = .notFound(message)
        case 409: self = .conflict(message)
        default: self = .server(status: status, message: message)
        }
    }
}

/// Human text first: Paperclip always sends an `error` string, but it is written for agents
/// ("Agent token did not verify…"). The server's own words stay available as `failureReason`.
extension PaperclipError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            "Your sign-in expired or was revoked. Sign in again to continue."
        case .signInRequired:
            "Your single sign-on session ended. Sign in again to continue."
        case .forbidden:
            "You don't have access to this on the Paperclip board."
        case .notFound:
            "This was removed or moved on the board."
        case let .conflict(message):
            switch message {
            case "Company is not active": "The company is paused. Resume it to wake agents."
            case "Agent is not invokable in its current state": "This agent can't be woken right now."
            default: "This changed on the board. Refresh and try again."
            }
        case let .invalidRequest(message):
            if message?.hasPrefix("Only pending") == true {
                "This was already decided on the board."
            } else {
                "The board didn't accept this request."
            }
        case let .server(status, _): "The factory had a problem (\(status)). Fabrix keeps trying."
        case let .transport(code): Self.transportMessage(code)
        case .decoding: "The server sent a response Fabrix doesn't understand."
        case .invalidServerURL: "Enter a server address like https://paperclip.example.com."
        case .insecureConnection: "Use https:// to sign in to a server outside your local network."
        case let .invalidAuthConfiguration(message): message
        case .signInCancelled: "Sign-in was cancelled."
        case .signInExpired: "Sign-in timed out. Try again."
        case let .missingHeaderValues(names):
            "This device no longer has the values for \(names.formatted(.list(type: .and))). Enter them again to connect."
        }
    }

    /// A bare `URLError(code)` has no readable text, only "NSURLErrorDomain error -1004".
    static func transportMessage(_ code: URLError.Code) -> String {
        switch code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            "You're offline. Fabrix retries when the connection is back."
        case .cannotConnectToHost:
            "The server didn't answer. Check that it's running and the address is right."
        case .cannotFindHost, .dnsLookupFailed:
            "No server was found at this address."
        case .timedOut:
            "The server took too long to answer."
        case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate,
             .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot, .clientCertificateRejected:
            "A secure connection to the server couldn't be made."
        default:
            "The server couldn't be reached."
        }
    }

    /// What the server said, when it said something.
    public var failureReason: String? {
        switch self {
        case let .invalidRequest(message), let .unauthorized(message), let .signInRequired(message), let .forbidden(message),
             let .notFound(message), let .conflict(message), let .server(_, message):
            message
        default:
            nil
        }
    }
}
