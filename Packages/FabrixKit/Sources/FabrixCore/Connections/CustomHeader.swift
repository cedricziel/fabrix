import Foundation

/// An extra request header sent to one factory, for example a reverse proxy's access token.
/// The name is saved with the factory; the value is a secret and lives in the Keychain.
public struct CustomHeader: Codable, Hashable, Sendable {
    public var name: String
    public var value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    private static let reservedNames: Set = ["host", "content-length", "transfer-encoding", "connection"]
    private static let tokenCharacters = CharacterSet(charactersIn: "!#$%&'*+-.^_`|~0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

    /// Trims `headers` and checks them against the headers `auth` already uses.
    ///
    /// - Throws: `PaperclipError.invalidAuthConfiguration` naming the first header that can't be sent.
    public static func validated(_ headers: [CustomHeader], for auth: FactoryAuthConfiguration) throws -> [CustomHeader] {
        var seen = Set<String>()
        return try headers.map { header in
            let name = header.name.trimmingCharacters(in: .whitespaces)
            let value = header.value.trimmingCharacters(in: .whitespaces)
            let key = name.lowercased()
            func refuse(_ message: String) -> PaperclipError {
                .invalidAuthConfiguration(message)
            }
            guard !name.isEmpty else { throw refuse("Enter a name for each custom header.") }
            guard name.unicodeScalars.allSatisfy(tokenCharacters.contains) else { throw refuse("\(name) isn't a valid header name.") }
            guard !value.contains(where: \.isNewline) else { throw refuse("The value of \(name) can't contain line breaks.") }
            guard !reservedNames.contains(key) else { throw refuse("\(name) is set by the system and can't be a custom header.") }
            if auth.usesBoardKey, key == "authorization" {
                throw refuse("\(name) carries the board key. Use another header name.")
            }
            if let oidc = auth.oidc, key == oidc.tokenHeader.lowercased() {
                throw refuse("\(name) carries the OIDC token. Use another header name.")
            }
            guard seen.insert(key).inserted else { throw refuse("\(name) is listed twice.") }
            return CustomHeader(name: name, value: value)
        }
    }
}
