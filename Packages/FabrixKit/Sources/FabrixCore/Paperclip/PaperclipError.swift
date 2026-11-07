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

extension PaperclipError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidRequest(message): message ?? "The server rejected the request."
        case let .unauthorized(message): message ?? "Sign in again to continue."
        case let .forbidden(message): message ?? "You don't have access to this."
        case let .notFound(message): message ?? "Not found."
        case let .conflict(message): message ?? "Someone else changed this first."
        case let .server(status, message): message ?? "The server failed with status \(status)."
        case let .transport(code): URLError(code).localizedDescription
        case .decoding: "The server sent a response Fabrix doesn't understand."
        case .invalidServerURL: "Enter a server address like https://paperclip.example.com."
        case .insecureConnection: "Use https:// to sign in to a server outside your local network."
        case let .invalidAuthConfiguration(message): message
        case .signInCancelled: "Sign-in was cancelled."
        case .signInExpired: "Sign-in timed out. Try again."
        }
    }
}
