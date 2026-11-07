import Foundation

/// How Fabrix authenticates to one factory.
///
/// | `oidc` | `usesBoardKey` | Meaning |
/// |---|---|---|
/// | nil | false | `local_trusted` server, no credentials |
/// | nil | true | Paperclip board API key |
/// | set | false | OIDC only, e.g. a proxy in front of a `local_trusted` server |
/// | set | true | OIDC for the proxy plus a board key for Paperclip |
public struct FactoryAuthConfiguration: Codable, Hashable, Sendable {
    public var oidc: OIDCSettings?
    public var usesBoardKey: Bool

    public init(oidc: OIDCSettings? = nil, usesBoardKey: Bool = false) {
        self.oidc = oidc
        self.usesBoardKey = usesBoardKey
    }

    public static let none = FactoryAuthConfiguration()
    public static let boardKey = FactoryAuthConfiguration(usesBoardKey: true)

    /// Throws `PaperclipError.invalidAuthConfiguration` when the OIDC token and the board key
    /// would both need the `Authorization` header.
    public func validate() throws {
        if usesBoardKey, let oidc, oidc.tokenHeader.caseInsensitiveCompare("Authorization") == .orderedSame {
            throw PaperclipError.invalidAuthConfiguration(
                "The board key needs the Authorization header. Send the OIDC token in another header, such as X-Forwarded-Access-Token."
            )
        }
    }
}
