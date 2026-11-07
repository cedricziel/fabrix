@testable import FabrixTelemetry
import Foundation
import Testing

struct AnonymizerTests {
    private let anonymizer = Anonymizer(salt: Data(repeating: 1, count: 32))

    @Test func hashIsStableForTheSameSalt() {
        #expect(anonymizer.hash("paperclip.local") == anonymizer.hash("paperclip.local"))
    }

    @Test func hashIgnoresCaseAndSurroundingWhitespace() {
        #expect(anonymizer.hash(" Paperclip.LOCAL ") == anonymizer.hash("paperclip.local"))
    }

    @Test func hashDiffersPerSalt() {
        let other = Anonymizer(salt: Data(repeating: 2, count: 32))
        #expect(anonymizer.hash("paperclip.local") != other.hash("paperclip.local"))
    }

    @Test func hashIsAShortHexTokenWithoutTheInput() {
        let hashed = anonymizer.hash("paperclip.local")
        #expect(hashed.count == 16)
        #expect(hashed.allSatisfy { $0.isHexDigit })
        #expect(!hashed.contains("paperclip"))
    }

    @Test func installSaltIsCreatedOnceAndReused() throws {
        let defaults = try #require(UserDefaults(suiteName: "AnonymizerTests-\(UUID())"))
        let first = Anonymizer.installSalt(in: defaults)
        let second = Anonymizer.installSalt(in: defaults)
        #expect(first.count == 32)
        #expect(first == second)
    }
}
