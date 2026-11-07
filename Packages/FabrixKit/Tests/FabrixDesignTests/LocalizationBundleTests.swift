@testable import FabrixDesign
import Foundation
import Testing

struct LocalizationBundleTests {
    @Test func designStringsResolveFromTheDesignCatalog() {
        #expect(String(localized: "fabrix.catalog.probe", bundle: .module) == "FabrixDesign catalog")
    }

    @Test func decisionKindsLookUpTheDesignBundle() {
        guard case let .atURL(url) = DecisionKind.hire.title.bundle else {
            Issue.record("expected the Design bundle, got \(DecisionKind.hire.title.bundle)")
            return
        }
        #expect(url == Bundle.module.bundleURL)
    }
}
