@testable import FabrixFeatures
import Foundation
import Testing

struct LocalizationBundleTests {
    @Test func sectionTitlesLookUpTheFeaturesBundle() {
        guard case let .atURL(url) = AppSection.approvals.title.bundle else {
            Issue.record("expected the Features bundle, got \(AppSection.approvals.title.bundle)")
            return
        }
        #expect(url == Bundle.module.bundleURL)
    }

    @Test func aBareLiteralMissesTheFeaturesBundle() {
        guard case let .atURL(url) = LocalizedStringResource("Approvals").bundle else { return }
        #expect(url != Bundle.module.bundleURL)
    }

    @Test func signInFailureMessagesAreInTheFeaturesCatalog() throws {
        let catalog = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/FabrixFeatures/Resources/Localizable.xcstrings")
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: catalog)) as? [String: Any]
        let keys = Set((json?["strings"] as? [String: Any] ?? [:]).keys)
        for message in [
            "The sign-in request expired before it was approved.",
            "The sign-in request was cancelled in the browser.",
        ] {
            #expect(keys.contains(message), "\(message) is missing from Localizable.xcstrings")
        }
    }
}
