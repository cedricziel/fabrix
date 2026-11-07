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
}
