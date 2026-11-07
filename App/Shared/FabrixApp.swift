import FabrixCore
import FabrixFeatures
import SwiftUI

@main
struct FabrixApp: App {
    private let factoryStore = FactoryStore()

    var body: some Scene {
        WindowGroup {
            RootView(factoryStore: factoryStore)
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 820)
        #endif
    }
}
