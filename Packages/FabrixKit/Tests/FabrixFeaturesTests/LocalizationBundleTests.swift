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
}
