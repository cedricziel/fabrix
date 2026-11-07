import Foundation
#if os(iOS)
import UIKit
#endif

/// Work that has to finish before the app is suspended or quits, such as sending decisions
/// still inside their undo window. Each window registers its own; the app runs them all.
@MainActor
public enum ShutdownTasks {
    private static var handlers: [UUID: @MainActor @Sendable () async -> Void] = [:]

    static func register(_ handler: @escaping @MainActor @Sendable () async -> Void) -> UUID {
        let id = UUID()
        handlers[id] = handler
        return id
    }

    static func unregister(_ id: UUID) {
        handlers[id] = nil
    }

    /// Runs every registered task, giving up after `timeout` so quitting never hangs on the network.
    public static func run(timeout: Duration = .seconds(5)) async {
        let pending = Array(handlers.values)
        guard !pending.isEmpty else { return }
        let work = Task { @MainActor in
            for handler in pending { await handler() }
        }
        let deadline = Task {
            try await Task.sleep(for: timeout)
            work.cancel()
        }
        await work.value
        deadline.cancel()
    }

    /// Runs the tasks while iOS keeps the app alive in the background a little longer.
    static func runInBackground() {
        #if os(iOS)
        var taskID = UIBackgroundTaskIdentifier.invalid
        taskID = UIApplication.shared.beginBackgroundTask(withName: "Send decisions") {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }
        Task {
            await run()
            if taskID != .invalid { UIApplication.shared.endBackgroundTask(taskID) }
        }
        #else
        Task { await run() }
        #endif
    }
}
