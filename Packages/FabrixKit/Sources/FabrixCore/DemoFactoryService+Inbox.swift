import Foundation

struct DemoInbox: Sendable {
    var now: Date
    var items: [AttentionItem]
    var receipts: [AttentionReceipt]
    var people: [Person]

    init(now: Date) {
        self.now = now
        func item(_ id: String, _ type: AttentionCardType, _ title: String, _ source: String, _ sourceID: String, _ answer: AttentionAnswer, _ audience: AttentionAudience, _ summary: String, taskID: String? = nil, identifier: String? = nil, requester: RequesterRef? = nil, path: String? = nil, critical: Bool = false, problem: Bool = false, stale: String? = nil, close: [String] = [], claim: Bool = false, transfer: Bool = false) -> AttentionItem {
            AttentionItem(id: id, source: AttentionSource(kind: source, id: sourceID), cardType: type, answer: answer, title: title, summary: summary, requester: requester, task: taskID.map { AttentionTaskRef(id: $0, identifier: identifier, title: title) }, isCritical: critical, isProblem: problem, staleReason: stale, createdAt: now.addingTimeInterval(-3600), activityAt: now.addingTimeInterval(-300), webPath: path, audience: audience, closeModes: close, canClaim: claim, canTransfer: transfer)
        }
        let me = AttentionAudience(kind: "user", userID: "me")
        let thread = RequesterRef(id: "cto", name: "Chief Technology Officer", kind: "agent")
        items = [
            item("hire-designer", .boardApproval, "Hire a Designer agent", "approval", "h1", .approval(sourceID: "h1"), me, "Approve the proposed design hire.", path: "/approvals/h1"),
            item("q4-plan", .reviewPlan, "Review the Q4 plan", "issue_thread_interaction", "ATL-148", .confirmation, me, "Review the proposed Q4 plan.", taskID: "task-ATL-148", identifier: "ATL-148", requester: thread, path: "/tasks/ATL-148", close: ["withdraw", "archive", "snooze"], transfer: true),
            item("push-provider", .answerQuestions, "Which push provider?", "issue_thread_interaction", "ATL-160", .questions, me, "Demo question: choose the push notification provider.", taskID: "task-ATL-160", identifier: "ATL-160", requester: thread, path: "/tasks/ATL-160", close: ["withdraw", "archive", "snooze"], transfer: true),
            item("release-notes", .reviewItems, "Review release notes", "issue_thread_interaction", "ATL-120", .verdicts, me, "Review the release notes before publication.", taskID: "task-ATL-120", identifier: "ATL-120", requester: thread, path: "/tasks/ATL-120", close: ["withdraw", "archive", "snooze"], transfer: true),
            item("confirm-rollout", .confirm, "Confirm rollout", "issue_thread_interaction", "rollout", .confirmation, me, "Confirm the production rollout.", requester: thread, path: "/tasks/rollout", close: ["withdraw", "archive", "snooze"], transfer: true),
            item("stale-rollout", .confirm, "Revisit rollout plan", "issue_thread_interaction", "stale-rollout", .confirmation, me, "This confirmation has been waiting for a while.", requester: thread, path: "/tasks/stale-rollout", stale: "aged", close: ["withdraw", "archive", "snooze"], transfer: true),
            item("transferred-plan", .confirm, "Review transfer plan", "issue_thread_interaction", "transfer-plan", .confirmation, AttentionAudience(kind: "user", userID: "me", reason: "transferred", transferredByUserID: "priya"), "Transferred to you by Priya.", requester: thread, path: "/tasks/transfer-plan", close: ["withdraw", "archive", "snooze"], transfer: true),
            item("budget-cap", .budgetStop, "Raise Founding Engineer cap", "budget_alert", "founding-engineer-cap", .openInPaperclip, me, "The agent reached its spending limit.", path: "/agents/founding-engineer", critical: true, problem: true),
            item("pool-confirm", .confirm, "Confirm infrastructure choice", "issue_thread_interaction", "pool-confirm", .confirmation, AttentionAudience(kind: "pool"), "Choose the infrastructure option.", requester: RequesterRef(id: "ceo", name: "Chief Executive Officer"), path: "/tasks/pool-confirm", claim: true, transfer: true),
            item("failed-run", .failedRun, "Agent run failed", "failed_run", "run-failed", .openInPaperclip, AttentionAudience(kind: "company"), "The deployment agent run failed.", path: "/runs/run-failed", problem: true),
            item("join-request", .joinRequest, "Join request", "join_request", "join-1", .openInPaperclip, AttentionAudience(kind: "company"), "A teammate requested access.", path: "/settings/members")
        ]
        receipts = [AttentionReceipt(id: "receipt-budget-cap", title: "Raise Founding Engineer cap", dismissalKey: "attention:receipt:receipt-budget-cap", source: AttentionSource(kind: "approval", id: "a-budget-cap"), outcome: "approved", actorUserID: "priya", createdAt: now.addingTimeInterval(-300), expiresAt: now.addingTimeInterval(6 * 24 * 60 * 60))]
        people = [Person(id: "me", name: "You"), Person(id: "priya", name: "Priya"), Person(id: "sam", name: "Sam")]
    }
}

extension DemoFactoryService {
    public func attention(companyID: Company.ID, view: AttentionView, cursor: String?) async throws -> AttentionFeed {
        guard companyID == "atlas" else { throw PaperclipError.notFound("Company not found") }

        let mine = inbox.items.filter {
            $0.audience?.kind == "user" && $0.audience?.userID == "me"
        }
        let unassigned = inbox.items.filter { $0.audience?.kind == "pool" }
        let companyItems = inbox.items.filter { $0.audience?.kind == "company" }
        let selected: [AttentionItem]
        switch view {
        case .mine: selected = mine
        case .unassigned: selected = unassigned
        case .company: selected = companyItems
        }

        return AttentionFeed(
            items: cursor == nil ? selected : [],
            deskBadgeCount: mine.count,
            viewCounts: [.mine: mine.count, .unassigned: unassigned.count, .company: companyItems.count],
            nextCursor: nil,
            receipts: view == .mine && cursor == nil ? inbox.receipts : []
        )
    }

    public func people(companyID: Company.ID) async throws -> [Person] {
        guard companyID == "atlas" else { throw PaperclipError.notFound("Company not found") }
        return inbox.people
    }
}
