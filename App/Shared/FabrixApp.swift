import FabrixCore
import FabrixFeatures
import FabrixTelemetry
import SwiftUI

@main
struct FabrixApp: App {
    private let factoryStore = FactoryStore()
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Telemetry.start(sensitiveValues: FactorySensitiveValues(store: factoryStore))
    }

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
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                Telemetry.flush()
            }
        }
        #if os(macOS)
        Settings { SettingsView() }
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
