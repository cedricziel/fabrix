@testable import FabrixFeatures
import Foundation
import Testing

struct LocalizationBundleTests {
    @Test func featureStringsLookUpTheFeaturesBundle() throws {
        let title = AppSection.approvals.title
        guard case let .atURL(url) = title.bundle else {
            Issue.record("expected the Features bundle, got \(title.bundle)")
            return
        }
        #expect(url == Bundle.module.bundleURL)
        #expect(String(localized: title) == "Approvals")
    }
}
