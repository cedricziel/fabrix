import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
struct ApprovalFlowTests {
    private func demoModel(undoWindow: Duration = .seconds(60)) async -> AppModel {
        let model = AppModel(defaults: UserDefaults(suiteName: UUID().uuidString)!, undoWindow: undoWindow)
        await model.exploreDemo()
        return model
    }

    @Test func decidingHidesTheApprovalUntilUndone() async throws {
        let model = await demoModel()
        let approval = try #require(model.waitingApprovals.first)

        model.decide(approval, approve: true)
        #expect(!model.waitingApprovals.contains { $0.id == approval.id })
        #expect(model.decidedApprovals.first { $0.id == approval.id }?.canUndo == true)

        model.undo(approval.id)
        #expect(model.waitingApprovals.contains { $0.id == approval.id })
    }

    @Test func committingSendsTheDecisionToTheFactory() async throws {
        let model = await demoModel()
        let approval = try #require(model.waitingApprovals.first)

        model.decide(approval, approve: false)
        await model.commitStagedDecisions()

        let decided = try #require(model.decidedApprovals.first { $0.id == approval.id })
        #expect(decided.approved == false)
        #expect(decided.canUndo == false)
        #expect(model.snapshot?.approvals.first { $0.id == approval.id }?.state == .rejected)
    }

    @Test func decisionsCommitAfterTheUndoWindow() async throws {
        let model = await demoModel(undoWindow: .milliseconds(10))
        let approval = try #require(model.waitingApprovals.first)

        model.decide(approval, approve: true)
        try await Task.sleep(for: .milliseconds(300))

        #expect(model.snapshot?.approvals.first { $0.id == approval.id }?.state == .approved)
    }

    @Test func decidingSeveralApprovalsCommitsThemTogether() async throws {
        let model = await demoModel()
        let approvals = model.waitingApprovals
        approvals.forEach { model.decide($0, approve: true) }

        await model.commitStagedDecisions()

        #expect(model.snapshot?.pendingApprovals.isEmpty == true)
        #expect(model.decidedApprovals.allSatisfy { !$0.canUndo })
    }

    @Test func slowPollCannotBringBackADecidedApproval() async throws {
        let service = GatedService()
        let model = AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service),
            defaults: UserDefaults(suiteName: UUID().uuidString)!, undoWindow: .seconds(60)
        )
        await model.refresh()
        let approval = try #require(model.waitingApprovals.first)

        await service.holdNextSnapshot()
        let poll = Task { await model.refresh() }
        await service.waitUntilHolding()
        model.decide(approval, approve: true)
        await model.commitStagedDecisions()
        await service.release()
        await poll.value

        #expect(!model.waitingApprovals.contains { $0.id == approval.id })
        #expect(model.snapshot?.approvals.first { $0.id == approval.id }?.state == .approved)
    }

    @Test func oneFailedDecisionDoesNotStopTheOthers() async throws {
        let service = GatedService(failingDecisions: ["h1"])
        let model = AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service),
            defaults: UserDefaults(suiteName: UUID().uuidString)!, undoWindow: .seconds(60)
        )
        await model.refresh()
        model.waitingApprovals.forEach { model.decide($0, approve: true) }

        await model.commitStagedDecisions()

        #expect(model.waitingApprovals.map(\.id) == ["h1"])
        #expect(model.snapshot?.approvals.filter { $0.state == .approved }.map(\.id).sorted() == ["b1", "s1"])
        #expect(model.lastError != nil)
        #expect(model.decisionErrors.keys.sorted() == ["h1"])

        let failed = try #require(model.waitingApprovals.first)
        model.decide(failed, approve: false)
        #expect(model.decisionErrors.isEmpty)
    }

    @Test func timerCommitIsNotCancelledByItsOwnTimer() async throws {
        let service = GatedService()
        let model = AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service),
            defaults: UserDefaults(suiteName: UUID().uuidString)!, undoWindow: .milliseconds(10)
        )
        await model.refresh()
        let approval = try #require(model.waitingApprovals.first)

        model.decide(approval, approve: true)
        for _ in 0 ..< 100 where model.snapshot?.approvals.first(where: { $0.id == approval.id })?.state != .approved {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(model.snapshot?.approvals.first { $0.id == approval.id }?.state == .approved)
        #expect(model.lastError == nil)
        #expect(model.decisionErrors.isEmpty)
    }

    @Test func commitFinishingAfterAFactorySwitchLeavesTheNewSessionAlone() async throws {
        let service = GatedService(failingDecisions: ["h1"])
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let model = AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service),
            defaults: defaults, undoWindow: .seconds(60)
        )
        await model.refresh()
        let approval = try #require(model.waitingApprovals.first { $0.id == "h1" })
        model.decide(approval, approve: true)

        await service.holdNextSnapshot()
        let committing = Task { await model.commitStagedDecisions() }
        await service.waitUntilHolding()
        model.disconnect()
        await model.exploreDemo()
        await service.release()
        await committing.value

        #expect(model.lastError == nil)
        #expect(model.decisionErrors.isEmpty)
        #expect(model.waitingApprovals.contains { $0.id == "h1" })
    }
}
