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

    /// Runs every registered task when the app quits. Returns by `timeout` even if a task
    /// ignores cancellation, so quitting never hangs on the network.
    public static func run(timeout: Duration = .seconds(5)) async {
        let pending = Array(handlers.values)
        guard !pending.isEmpty else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let finish = ResumeOnce(continuation)
            let work = Task { @MainActor in
                for handler in pending { await handler() }
                finish.resume()
            }
            Task { @MainActor in
                try? await Task.sleep(for: timeout)
                work.cancel()
                finish.resume()
            }
        }
    }

    /// Runs one window's work while iOS keeps the app alive in the background a little longer.
    @discardableResult
    static func runInBackground(_ work: @escaping @MainActor @Sendable () async -> Void) -> Task<Void, Never> {
        #if os(iOS)
        var taskID = UIBackgroundTaskIdentifier.invalid
        taskID = UIApplication.shared.beginBackgroundTask(withName: "Send decisions") {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }
        return Task {
            await work()
            if taskID != .invalid { UIApplication.shared.endBackgroundTask(taskID) }
        }
        #else
        return Task { await work() }
        #endif
    }
}

/// Resumes a continuation on the first call and ignores later ones.
@MainActor
private final class ResumeOnce {
    private var continuation: CheckedContinuation<Void, Never>?

    init(_ continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}
