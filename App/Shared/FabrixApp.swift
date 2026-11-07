import FabrixFeatures
import SwiftUI

@main
struct FabrixApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 820)
        #endif
    }
}
