import SwiftUI
import Testing
@testable import FabrixDesign

@Test func keyValueListStacksAtAccessibilitySizes() {
    #expect(!KeyValueList.stacksAtAccessibilitySize(.large))
    #expect(KeyValueList.stacksAtAccessibilitySize(.accessibility1))
    #expect(KeyValueList.stacksAtAccessibilitySize(.accessibility3))
}
