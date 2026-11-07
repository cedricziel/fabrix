@testable import FabrixDesign
import Foundation
import Testing

struct LocalizationBundleTests {
    @Test func designStringsLookUpTheDesignBundle() throws {
        let title = DecisionKind.hire.title
        guard case let .atURL(url) = title.bundle else {
            Issue.record("expected the Design bundle, got \(title.bundle)")
            return
        }
        #expect(url == Bundle.module.bundleURL)
        #expect(String(localized: title) == "Hire")
    }
}
