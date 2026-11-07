import CryptoKit
import Foundation

/// Proof Key for Code Exchange (RFC 7636) with the S256 method.
struct PKCE {
    var verifier: String
    var challenge: String

    static func generate() -> PKCE {
        let verifier = randomURLSafeString(byteCount: 32)
        return PKCE(verifier: verifier, challenge: challenge(for: verifier))
    }

    static func challenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded()
    }

    static func randomURLSafeString(byteCount: Int) -> String {
        var generator = SystemRandomNumberGenerator()
        return Data((0 ..< byteCount).map { _ in UInt8.random(in: .min ... .max, using: &generator) }).base64URLEncoded()
    }
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
    }
}
