import FabrixFeatures
import SwiftUI

@main
struct FabrixApp: App {
    @State private var model = AppModel(connector: StoreConnector())

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 820)
        #endif
    }
}
