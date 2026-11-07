import CryptoKit
import Foundation

/// Salted SHA-256 so the same factory maps to the same token within one install,
/// but tokens can't be reversed or joined across installs.
public struct Anonymizer: Sendable {
    private let salt: Data

    public init(salt: Data) {
        self.salt = salt
    }

    public func hash(_ value: String) -> String {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let digest = SHA256.hash(data: salt + Data(normalized.utf8))
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    static func installSalt(in defaults: UserDefaults) -> Data {
        let key = "fabrix.telemetry.salt"
        if let salt = defaults.data(forKey: key), salt.count == 32 {
            return salt
        }
        let salt = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        defaults.set(salt, forKey: key)
        return salt
    }
}
