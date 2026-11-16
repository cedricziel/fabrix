import Foundation
import Testing
@testable import FabrixCore

@Test func answerPerCardType() {
    let sourceID = "approval-1"

    #expect(AttentionAnswer.answerPerCardType(.boardApproval, sourceID: sourceID) == .approval(sourceID: sourceID))

    for type in [AttentionCardType.confirm, .reviewPlan, .reviewDeliverable] {
        #expect(AttentionAnswer.answerPerCardType(type, sourceID: sourceID) == .confirmation)
    }

    #expect(AttentionAnswer.answerPerCardType(.answerQuestions, sourceID: sourceID) == .questions)
    #expect(AttentionAnswer.answerPerCardType(.reviewItems, sourceID: sourceID) == .verdicts)

    let mappedTypes: Set<AttentionCardType> = [
        .boardApproval, .confirm, .reviewPlan, .reviewDeliverable, .answerQuestions, .reviewItems,
    ]
    for type in AttentionCardType.allCases where !mappedTypes.contains(type) {
        #expect(AttentionAnswer.answerPerCardType(type, sourceID: sourceID) == .openInPaperclip)
    }
    #expect(AttentionAnswer.answerPerCardType(.unknown("future_kind"), sourceID: sourceID) == .openInPaperclip)
    #expect(AttentionCardType(rawValue: "future_kind") == .unknown("future_kind"))
}

@Test func capabilityOverridesOpenInPaperclip() {
    let sourceID = "approval-1"

    #expect(AttentionAnswer.answerPerCardType(.boardApproval, sourceID: sourceID, isCheckboxConfirmation: true) == .openInPaperclip)
    #expect(AttentionAnswer.answerPerCardType(.boardApproval, sourceID: sourceID, isTextOnlyQuestion: true) == .openInPaperclip)
    #expect(AttentionAnswer.answerPerCardType(.boardApproval, sourceID: sourceID, isWorkflowRequest: true) == .openInPaperclip)
    #expect(AttentionAnswer.answerPerCardType(.boardApproval, sourceID: sourceID, hasUnknownSourceOrStatus: true) == .openInPaperclip)
}

@Test func attentionFeedRoutingCountsAreOptionalAndPreserved() {
    let absent = AttentionFeed(items: [], deskBadgeCount: 7, nextCursor: "next", receipts: [AttentionReceipt(id: "r1", title: "Receipt", dismissalKey: "dismiss-r1", source: AttentionSource(kind: "task", id: "task-r1"), outcome: "completed", actorUserID: "user-r1", createdAt: Date(), expiresAt: Date())])
    #expect(absent.viewCounts == nil)
    #expect(!absent.supportsRouting)
    #expect(absent.deskBadgeCount == 7)
    #expect(absent.nextCursor == "next")
    #expect(absent.receipts.count == 1)

    let empty = AttentionFeed(items: [], deskBadgeCount: 0, viewCounts: [:])
    #expect(empty.viewCounts == [:])
    #expect(empty.supportsRouting)

    let populated = AttentionFeed(items: [], deskBadgeCount: 3, viewCounts: [.mine: 2, .company: 5])
    #expect(populated.viewCounts == [.mine: 2, .company: 5])
    #expect(populated.supportsRouting)
}

@Test func personOptionalFieldsAndRequesterKind() {
    let sparsePerson = Person(id: "principal-1")
    #expect(sparsePerson.id == "principal-1")
    #expect(sparsePerson.name == nil)
    #expect(sparsePerson.email == nil)

    let person = Person(id: "principal-2", name: "Ada", email: "ada@example.com")
    #expect(person.name == "Ada")
    #expect(person.email == "ada@example.com")

    let requester = RequesterRef(id: "principal-3", name: "Lin", kind: "future_requester")
    #expect(requester.id == "principal-3")
    #expect(requester.name == "Lin")
    #expect(requester.kind == "future_requester")
}

@Test func attentionReceiptPreservesAllFields() {
    let created = Date(timeIntervalSince1970: 1_700_000_000)
    let expires = Date(timeIntervalSince1970: 1_700_100_000)
    let task = AttentionTaskRef(id: "task-1", identifier: "FAB-1", title: "Ship", status: "future_status")
    let receipt = AttentionReceipt(
        id: "receipt-1", title: "Resolved", dismissalKey: "dismiss-1",
        source: AttentionSource(kind: "task", id: "task-1"), outcome: "transferred",
        actorUserID: "user-1", transferredToUserID: "user-2", reason: "delegated",
        task: task, webPath: "/tasks/task-1", createdAt: created, expiresAt: expires
    )

    #expect(receipt.id == "receipt-1")
    #expect(receipt.title == "Resolved")
    #expect(receipt.dismissalKey == "dismiss-1")
    #expect(receipt.source == AttentionSource(kind: "task", id: "task-1"))
    #expect(receipt.outcome == "transferred")
    #expect(receipt.actorUserID == "user-1")
    #expect(receipt.transferredToUserID == "user-2")
    #expect(receipt.reason == "delegated")
    #expect(receipt.task == task)
    #expect(receipt.webPath == "/tasks/task-1")
    #expect(receipt.createdAt == created)
    #expect(receipt.expiresAt == expires)
}

@Test func attentionItemPreservesUnknownAndContextFields() {
    let created = Date(timeIntervalSince1970: 1_700_000_000)
    let activity = Date(timeIntervalSince1970: 1_700_000_100)
    let evidence = AttentionItem(
        id: "evidence-1", source: AttentionSource(kind: "approval", id: "approval-1"),
        cardType: .unknown("future_card"), title: "Evidence", createdAt: created, activityAt: activity
    )
    let item = AttentionItem(
        id: "item-1", source: AttentionSource(kind: "task", id: "task-1"),
        cardType: .answerQuestions, title: "Question", summary: "Needs input",
        requester: RequesterRef(id: "user-1", name: "Ada"),
        task: AttentionTaskRef(id: "task-1", identifier: "FAB-1", title: "Ship", status: "future_status"),
        projectName: "Project", staleReason: "future_stale_reason", createdAt: created, activityAt: activity,
        closeModes: ["answer", "dismiss"], canClaim: true, canTransfer: true,
        fingerprint: "fingerprint-1", evidence: [evidence]
    )

    #expect(item.task?.status == "future_status")
    #expect(item.staleReason == "future_stale_reason")
    #expect(item.summary == "Needs input")
    #expect(item.requester == RequesterRef(id: "user-1", name: "Ada"))
    #expect(item.projectName == "Project")
    #expect(item.closeModes == ["answer", "dismiss"])
    #expect(item.canClaim && item.canTransfer)
    #expect(item.fingerprint == "fingerprint-1")
    #expect(item.evidence == [evidence])
}

@Test func minimallyInitializedAttentionItemDefaultsToSafeCapabilities() {
    let item = AttentionItem(
        id: "item-1", source: AttentionSource(kind: "task", id: "task-1"),
        cardType: .unknown("future_card"), title: "Question", createdAt: Date(), activityAt: Date()
    )
    #expect(item.answer == .openInPaperclip)
    #expect(!item.canClaim)
    #expect(!item.canTransfer)
}
