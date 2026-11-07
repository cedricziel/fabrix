import Foundation

public struct Factory: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var name: String
    public var baseURL: URL
    public var isOnline: Bool

    public init(id: String, name: String, baseURL: URL, isOnline: Bool) {
        self.id = id
        self.name = name
        self.baseURL = baseURL
        self.isOnline = isOnline
    }
}

public struct Company: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var name: String
    public var mission: String?
    public var isPaused: Bool
    public var heartbeatMinutes: Int?

    public init(id: String, name: String, mission: String? = nil, isPaused: Bool = false, heartbeatMinutes: Int? = nil) {
        self.id = id
        self.name = name
        self.mission = mission
        self.isPaused = isPaused
        self.heartbeatMinutes = heartbeatMinutes
    }
}

public enum AgentStatus: String, Sendable, Codable, CaseIterable {
    case running, idle, paused, needsYou, blocked, error
}

public struct Agent: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var name: String
    public var role: String?
    public var status: AgentStatus
    public var reportsToID: String?
    public var adapter: String?
    public var budgetMonthlyCents: Int?
    public var spentMonthlyCents: Int

    public init(
        id: String, name: String, role: String? = nil, status: AgentStatus,
        reportsToID: String? = nil, adapter: String? = nil,
        budgetMonthlyCents: Int? = nil, spentMonthlyCents: Int = 0
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.status = status
        self.reportsToID = reportsToID
        self.adapter = adapter
        self.budgetMonthlyCents = budgetMonthlyCents
        self.spentMonthlyCents = spentMonthlyCents
    }

    public var initials: String {
        let words = name.split(separator: " ")
        let letters = words.count > 1 ? words.prefix(2).compactMap(\.first) : Array(name.prefix(2))
        return String(letters).uppercased()
    }
}

public enum TaskStatus: String, Sendable, Codable, CaseIterable {
    case backlog, todo, inProgress, inReview, blocked, done, cancelled
}

public struct WorkItem: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var identifier: String
    public var title: String
    public var status: TaskStatus
    public var assigneeID: String?
    public var updatedAt: Date

    public init(id: String, identifier: String, title: String, status: TaskStatus, assigneeID: String? = nil, updatedAt: Date = .now) {
        self.id = id
        self.identifier = identifier
        self.title = title
        self.status = status
        self.assigneeID = assigneeID
        self.updatedAt = updatedAt
    }
}

public enum ApprovalKind: String, Sendable, Codable, CaseIterable {
    case hire, strategy, budget, other
}

public enum ApprovalState: String, Sendable, Codable {
    case pending, approved, rejected
}

public struct Approval: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var kind: ApprovalKind
    public var requestedBy: String
    public var title: String
    public var detail: String
    public var createdAt: Date
    public var state: ApprovalState

    public init(id: String, kind: ApprovalKind, requestedBy: String, title: String, detail: String, createdAt: Date, state: ApprovalState = .pending) {
        self.id = id
        self.kind = kind
        self.requestedBy = requestedBy
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.state = state
    }
}

public struct Run: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var agentID: String
    public var taskIdentifier: String?
    public var title: String
    public var adapter: String?
    public var startedAt: Date
    public var finishedAt: Date?
    public var costCents: Int?
    public var summary: String?

    public init(
        id: String, agentID: String, taskIdentifier: String? = nil, title: String, adapter: String? = nil,
        startedAt: Date, finishedAt: Date? = nil, costCents: Int? = nil, summary: String? = nil
    ) {
        self.id = id
        self.agentID = agentID
        self.taskIdentifier = taskIdentifier
        self.title = title
        self.adapter = adapter
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.costCents = costCents
        self.summary = summary
    }

    public var isLive: Bool {
        finishedAt == nil
    }
}

public struct ActivityEvent: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var at: Date
    public var actor: String
    public var summary: String

    public init(id: String, at: Date, actor: String, summary: String) {
        self.id = id
        self.at = at
        self.actor = actor
        self.summary = summary
    }
}

public struct CompanySnapshot: Hashable, Sendable {
    public var company: Company
    public var agents: [Agent]
    public var tasks: [WorkItem]
    public var approvals: [Approval]
    public var runs: [Run]
    public var activity: [ActivityEvent]
    public var spentMonthlyCents: Int
    public var budgetMonthlyCents: Int?

    public init(
        company: Company, agents: [Agent], tasks: [WorkItem], approvals: [Approval],
        runs: [Run], activity: [ActivityEvent], spentMonthlyCents: Int, budgetMonthlyCents: Int?
    ) {
        self.company = company
        self.agents = agents
        self.tasks = tasks
        self.approvals = approvals
        self.runs = runs
        self.activity = activity
        self.spentMonthlyCents = spentMonthlyCents
        self.budgetMonthlyCents = budgetMonthlyCents
    }

    public var pendingApprovals: [Approval] {
        approvals.filter { $0.state == .pending }
    }

    public var liveRuns: [Run] {
        runs.filter(\.isLive)
    }
}
