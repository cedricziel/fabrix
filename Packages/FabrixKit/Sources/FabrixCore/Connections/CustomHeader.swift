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
            let message: String? = if name.isEmpty {
                "Enter a name for each custom header."
            } else if !name.unicodeScalars.allSatisfy(tokenCharacters.contains) {
                "\(name) isn't a valid header name."
            } else if value.contains(where: \.isNewline) {
                "The value of \(name) can't contain line breaks."
            } else if value.unicodeScalars.contains(where: { $0 != "\t" && ($0.value < 0x20 || $0.value == 0x7F) }) {
                "The value of \(name) can't contain control characters."
            } else if reservedNames.contains(key) {
                "\(name) is set by the system and can't be a custom header."
            } else if let credential = auth.credential(carriedIn: name) {
                "\(name) carries \(credential). Use another header name."
            } else if !seen.insert(key).inserted {
                "\(name) is listed twice."
            } else {
                nil
            }
            if let message { throw PaperclipError.invalidAuthConfiguration(message) }
            return CustomHeader(name: name, value: value)
        }
    }
}
