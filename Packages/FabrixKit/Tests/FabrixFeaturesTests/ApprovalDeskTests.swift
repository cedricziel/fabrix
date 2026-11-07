import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

struct ApprovalDeskTests {
    private let approvals = [
        Approval(id: "h1", kind: .hire, requestedBy: "CEO", title: "Hire", detail: "", createdAt: .distantPast),
        Approval(id: "s1", kind: .strategy, requestedBy: "CEO", title: "Plan", detail: "", createdAt: .distantPast),
        Approval(id: "old", kind: .budget, requestedBy: "CTO", title: "Cap", detail: "", createdAt: .distantPast, state: .rejected),
    ]

    @Test func waitingListsOnlyPendingUndecidedApprovals() {
        var desk = ApprovalDesk()
        desk.stage("h1", approve: true)
        #expect(desk.waiting(approvals).map(\.id) == ["s1"])
    }

    @Test func decidedListsStagedAndServerDecisions() {
        var desk = ApprovalDesk()
        desk.stage("h1", approve: true)
        let decided = desk.decided(approvals)
        #expect(decided.map(\.id) == ["h1", "old"])
        #expect(decided.map(\.approved) == [true, false])
        #expect(decided.map(\.canUndo) == [true, false])
    }

    @Test func undoReturnsTheApprovalToWaiting() {
        var desk = ApprovalDesk()
        desk.stage("s1", approve: false)
        let undone = desk.undo("s1")
        #expect(undone)
        #expect(desk.waiting(approvals).map(\.id) == ["h1", "s1"])
        #expect(desk.decided(approvals).map(\.id) == ["old"])
    }

    @Test func committingDecisionCannotBeUndone() {
        var desk = ApprovalDesk()
        desk.stage("h1", approve: true)
        #expect(desk.beginCommit("h1") == true)
        #expect(desk.beginCommit("h1") == nil)
        let undone = desk.undo("h1")
        #expect(!undone)
        #expect(desk.waiting(approvals).map(\.id) == ["s1"])
        #expect(desk.decided(approvals).first?.canUndo == false)
    }

    @Test func sentDecisionsSettleOnceTheFactoryShowsThem() {
        var desk = ApprovalDesk()
        desk.stage("h1", approve: true)
        desk.stage("s1", approve: false)
        _ = desk.beginCommit("h1")

        desk.settle(with: approvals)
        #expect(desk.decided(approvals).map(\.id) == ["h1", "s1", "old"])

        var decided = approvals
        decided[0].state = .approved
        desk.settle(with: decided)
        #expect(desk.decided(decided).map(\.canUndo) == [false, true, false])
        #expect(desk.stagedIDs == ["s1"])
    }

    @Test func finishingACommitDefersToServerState() {
        var desk = ApprovalDesk()
        desk.stage("h1", approve: true)
        _ = desk.beginCommit("h1")
        desk.finish("h1")
        #expect(desk.waiting(approvals).map(\.id) == ["h1", "s1"])
    }
}
