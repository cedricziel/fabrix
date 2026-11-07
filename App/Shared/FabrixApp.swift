import FabrixCore
import FabrixFeatures
import SwiftUI

@main
struct FabrixApp: App {
    private let factoryStore = FactoryStore()
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            RootView(factoryStore: factoryStore)
            #if DEBUG
                .preferredColorScheme(Self.debugColorScheme)
            #endif
        }
        .commands { FactoryCommands() }
        #if os(macOS)
        .defaultSize(width: 1280, height: 820)
        #endif
    }

    #if DEBUG
    /// `-FabrixColorScheme dark` (or `light`) as a launch argument, for screenshots and checks.
    private static var debugColorScheme: ColorScheme? {
        switch UserDefaults.standard.string(forKey: "FabrixColorScheme") {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }
    #endif
}
