import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
struct RootViewTests {
    @Test func creatingTheViewDoesNotBuildTheModel() {
        var built = 0
        func countedModel() -> AppModel {
            built += 1
            return AppModel(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        }

        _ = RootView(model: countedModel())
        _ = RootView(model: countedModel())

        #expect(built == 0)
    }
}
