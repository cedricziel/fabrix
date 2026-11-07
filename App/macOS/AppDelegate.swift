import AppKit
import FabrixFeatures

/// Holds Cmd-Q until decisions still in their undo window have been sent.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task { @MainActor in
            await ShutdownTasks.run()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
