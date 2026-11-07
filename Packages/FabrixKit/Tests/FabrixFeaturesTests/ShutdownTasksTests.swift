import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
@Suite(.serialized)
struct ShutdownTasksTests {
    @Test func runsEveryRegisteredTask() async {
        var ran: [String] = []
        let first = ShutdownTasks.register { ran.append("first") }
        let second = ShutdownTasks.register { ran.append("second") }
        defer { [first, second].forEach(ShutdownTasks.unregister) }

        await ShutdownTasks.run()

        #expect(ran.sorted() == ["first", "second"])
    }

    @Test func unregisteredTasksDoNotRun() async {
        var ran = false
        let id = ShutdownTasks.register { ran = true }
        ShutdownTasks.unregister(id)

        await ShutdownTasks.run()

        #expect(!ran)
    }

    @Test func givesUpAfterTheTimeout() async {
        let id = ShutdownTasks.register { try? await Task.sleep(for: .seconds(30)) }
        defer { ShutdownTasks.unregister(id) }
        let start = ContinuousClock.now

        await ShutdownTasks.run(timeout: .milliseconds(50))

        #expect(ContinuousClock.now - start < .seconds(5))
    }

    @Test func pendingDecisionsAreSentWhenTheAppQuits() async throws {
        let model = AppModel(defaults: UserDefaults(suiteName: UUID().uuidString)!, undoWindow: .seconds(60))
        await model.exploreDemo()
        let approval = try #require(model.waitingApprovals.first)
        model.decide(approval, approve: true)
        let id = ShutdownTasks.register { await model.commitStagedDecisions() }
        defer { ShutdownTasks.unregister(id) }

        await ShutdownTasks.run()

        #expect(model.snapshot?.approvals.first { $0.id == approval.id }?.state == .approved)
    }

    @Test func returnsByTheDeadlineEvenIfATaskIgnoresCancellation() async {
        let id = ShutdownTasks.register {
            let end = ContinuousClock.now + .seconds(2)
            while ContinuousClock.now < end { await Task.yield() }
        }
        defer { ShutdownTasks.unregister(id) }
        let start = ContinuousClock.now

        await ShutdownTasks.run(timeout: .milliseconds(50))

        #expect(ContinuousClock.now - start < .seconds(1))
    }

    @Test func backgroundingOneWindowLeavesTheOtherWindowsDecisionsStaged() async throws {
        let windowA = AppModel(defaults: UserDefaults(suiteName: UUID().uuidString)!, undoWindow: .seconds(60))
        let windowB = AppModel(defaults: UserDefaults(suiteName: UUID().uuidString)!, undoWindow: .seconds(60))
        await windowA.exploreDemo()
        await windowB.exploreDemo()
        let first = try #require(windowA.waitingApprovals.first)
        windowA.decide(first, approve: true)
        windowB.decide(try #require(windowB.waitingApprovals.first), approve: false)
        let ids = [windowA, windowB].map { model in ShutdownTasks.register { await model.commitStagedDecisions() } }
        defer { ids.forEach(ShutdownTasks.unregister) }

        await ShutdownTasks.runInBackground { await windowA.commitStagedDecisions() }.value

        #expect(windowA.snapshot?.approvals.first { $0.id == first.id }?.state == .approved)
        #expect(windowB.decidedApprovals.first?.canUndo == true)
    }
}
