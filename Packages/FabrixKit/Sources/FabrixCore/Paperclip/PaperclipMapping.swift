import Foundation

// Maps Paperclip wire shapes onto Fabrix domain models. Status tables live in docs/paperclip-api.md.

/// Paperclip stores "no budget" as 0 cents; Fabrix models it as nil.
func positiveCents(_ cents: Int?) -> Int? {
    cents.flatMap { $0 > 0 ? $0 : nil }
}

extension AgentStatus {
    init(paperclip raw: String) {
        switch raw {
        case "running": self = .running
        case "paused": self = .paused
        case "error": self = .error
        case "pending_approval": self = .needsYou
        default: self = .idle
        }
    }
}

extension TaskStatus {
    init(paperclip raw: String) {
        switch raw {
        case "todo": self = .todo
        case "in_progress": self = .inProgress
        case "in_review": self = .inReview
        case "blocked": self = .blocked
        case "done": self = .done
        case "cancelled": self = .cancelled
        default: self = .backlog
        }
    }
}

extension ApprovalKind {
    init(paperclip raw: String) {
        switch raw {
        case "hire_agent": self = .hire
        case "approve_ceo_strategy": self = .strategy
        case "budget_override_required": self = .budget
        default: self = .other
        }
    }
}

extension ApprovalState {
    init(paperclip raw: String) {
        switch raw {
        case "approved": self = .approved
        case "rejected", "cancelled": self = .rejected
        default: self = .pending
        }
    }
}

extension Company {
    init(paperclip dto: CompanyDTO) {
        self.init(id: dto.id, name: dto.name, mission: dto.description, isPaused: dto.status == "paused")
    }
}

extension Agent {
    init(paperclip dto: AgentDTO) {
        self.init(
            id: dto.id, name: dto.name, role: dto.title ?? dto.role, status: AgentStatus(paperclip: dto.status),
            reportsToID: dto.reportsTo, adapter: dto.adapterType,
            budgetMonthlyCents: positiveCents(dto.budgetMonthlyCents),
            spentMonthlyCents: dto.spentMonthlyCents ?? 0
        )
    }
}

extension WorkItem {
    init(paperclip dto: IssueDTO) {
        self.init(
            id: dto.id, identifier: dto.identifier ?? dto.id, title: dto.title, status: TaskStatus(paperclip: dto.status),
            assigneeID: dto.assigneeAgentId, updatedAt: dto.updatedAt ?? .now
        )
    }
}

extension Approval {
    /// Newest first, each approval once: one can change status between the per-status requests and show up
    /// in both, so the most recently updated copy wins.
    static func list(paperclip dtos: [ApprovalDTO], agents: [Agent.ID: Agent]) -> [Approval] {
        let latest = Dictionary(dtos.map { ($0.id, $0) }) { first, second in
            (second.updatedAt ?? second.createdAt) > (first.updatedAt ?? first.createdAt) ? second : first
        }
        return latest.values
            .sorted { ($0.createdAt, $1.id) > ($1.createdAt, $0.id) }
            .map { Approval(paperclip: $0, agents: agents) }
    }

    init(paperclip dto: ApprovalDTO, agents: [Agent.ID: Agent]) {
        let payload = dto.payload ?? [:]
        func text(_ keys: String...) -> String? {
            keys.lazy.compactMap { payload[$0]?.text }.first
        }

        let kind = ApprovalKind(paperclip: dto.type)
        let title: String
        let detail: String
        switch kind {
        case .hire:
            title = "Hire \(text("name") ?? "an agent")"
            detail = [text("title", "role"), text("adapterType"), text("capabilities")].compactMap(\.self).joined(separator: " · ")
        case .strategy:
            title = text("title") ?? "CEO strategy"
            detail = text("plan", "description", "strategy", "text") ?? ""
        case .budget:
            title = text("scopeName", "scopeType").map { "Budget override for \($0)" } ?? "Budget override"
            detail = text("guidance") ?? ""
        case .other:
            title = text("title") ?? "Board approval"
            detail = text("summary", "recommendedAction") ?? ""
        }

        self.init(
            id: dto.id, kind: kind, requestedBy: dto.requestedByAgentId.flatMap { agents[$0]?.name } ?? "Board",
            title: title, detail: detail, createdAt: dto.createdAt, state: ApprovalState(paperclip: dto.status)
        )
    }
}

extension Run {
    private static let liveStatuses: Set = ["queued", "scheduled_retry", "running"]

    init(paperclip dto: HeartbeatRunDTO, issues: [WorkItem.ID: WorkItem], agents: [Agent.ID: Agent]) {
        let issue = dto.issueId.flatMap { issues[$0] }
        let isLive = Self.liveStatuses.contains(dto.status)
        let startedAt = dto.startedAt ?? dto.createdAt
        self.init(
            id: dto.id, agentID: dto.agentId, taskIdentifier: issue?.identifier,
            title: issue?.title ?? Self.title(invocationSource: dto.invocationSource),
            adapter: agents[dto.agentId]?.adapter, startedAt: startedAt,
            finishedAt: isLive ? nil : dto.finishedAt ?? dto.updatedAt ?? startedAt,
            costCents: (dto.costUsd?.number ?? dto.usageJson?["costUsd"]?.number).flatMap { Int(exactly: ($0 * 100).rounded()) },
            summary: dto.resultJson?["summary"]?.text ?? dto.error
        )
    }

    private static func title(invocationSource: String?) -> String {
        switch invocationSource {
        case "timer": "Scheduled heartbeat"
        case "assignment": "Assignment"
        case "on_demand": "Manual wake"
        case "automation": "Automation"
        default: "Heartbeat"
        }
    }
}

extension ActivityEvent {
    /// Turns `issue.updated` on ATL-142 into "updated issue ATL-142".
    init(paperclip dto: ActivityDTO, issues: [WorkItem.ID: WorkItem], agents: [Agent.ID: Agent]) {
        let actor = switch dto.actorType {
        case "agent": agents[dto.actorId]?.name ?? "Agent"
        case "user": "Board"
        case "plugin": "Plugin"
        default: "System"
        }

        let parts = dto.action.split(separator: ".", maxSplits: 1).map { String($0).replacing("_", with: " ") }
        let verb = parts.last ?? dto.action
        let entity = dto.entityType.replacing("_", with: " ")
        let label = dto.details?["identifier"]?.text
            ?? issues[dto.entityId]?.identifier
            ?? agents[dto.entityId]?.name
        let summary = [verb, entity, label].compactMap(\.self).joined(separator: " ")

        self.init(id: dto.id, at: dto.createdAt, actor: actor, summary: summary)
    }
}
