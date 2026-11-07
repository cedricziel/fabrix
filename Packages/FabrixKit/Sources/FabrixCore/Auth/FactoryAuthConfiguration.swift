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

    /// What this configuration sends in `header`, for messages; nil when the header is free.
    func credential(carriedIn header: String) -> String? {
        if usesBoardKey, header.caseInsensitiveCompare("Authorization") == .orderedSame { return "the board key" }
        if let oidc, header.caseInsensitiveCompare(oidc.tokenHeader) == .orderedSame { return "the OIDC token" }
        return nil
    }

    /// Throws `PaperclipError.invalidAuthConfiguration` when the OIDC token and the board key
    /// would both need the `Authorization` header.
    public func validate() throws {
        if let oidc, FactoryAuthConfiguration(usesBoardKey: usesBoardKey).credential(carriedIn: oidc.tokenHeader) != nil {
            throw PaperclipError.invalidAuthConfiguration(
                "The board key needs the Authorization header. Send the OIDC token in another header, such as X-Forwarded-Access-Token."
            )
        }
    }
}
