@testable import FabrixFeatures
import Foundation
import Testing

struct LocalizationBundleTests {
    @Test func featureStringsResolveFromTheFeaturesCatalog() {
        #expect(String(localized: .features("fabrix.catalog.probe")) == "FabrixFeatures catalog")
    }

    @Test func aBareLiteralWouldMissTheCatalog() {
        #expect(String(localized: LocalizedStringResource("fabrix.catalog.probe")) == "fabrix.catalog.probe")
    }

    @Test func sectionTitlesLookUpTheFeaturesBundle() {
        guard case let .atURL(url) = AppSection.approvals.title.bundle else {
            Issue.record("expected the Features bundle, got \(AppSection.approvals.title.bundle)")
            return
        }
        #expect(url == Bundle.module.bundleURL)
    }
}
