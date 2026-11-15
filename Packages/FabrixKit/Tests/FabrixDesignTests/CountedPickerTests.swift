import Testing
@testable import FabrixDesign

struct CountedPickerTests {
    @Test func countedPickerStyle() {
        #expect(CountedPicker<UUID>.countedPickerStyle(forAccessibilitySize: false) == false)
        #expect(CountedPicker<UUID>.countedPickerStyle(forAccessibilitySize: true) == true)
    }

    @Test func hidesZeroCount() {
        #expect(CountedPicker<UUID>.hidesZeroCount(0) == false)
        #expect(CountedPicker<UUID>.hidesZeroCount(2) == true)
    }
}
import Foundation
