import Foundation

/// In-memory factory with the design's sample company. Used for previews,
/// tests, screenshots, and the "Try the demo" path before a server is connected.
public actor DemoFactoryService: FactoryService {
    private var company: Company
    private var agents: [Agent]
    private var tasks: [WorkItem]
    private var approvals: [Approval]
    private var runs: [Run]
    private var activity: [ActivityEvent]

    public init(now: Date = .now) {
        let minute: TimeInterval = 60
        company = Company(id: "atlas", name: "Atlas", mission: "Ship the calmest task app on the App Store", heartbeatMinutes: 5)
        agents = [
            Agent(id: "ceo", name: "CEO", role: "Chief Executive", status: .needsYou, adapter: "claude-code", budgetMonthlyCents: 15000, spentMonthlyCents: 6210),
            Agent(id: "cto", name: "CTO", role: "Chief Technology Officer", status: .running, reportsToID: "ceo", adapter: "claude-code", budgetMonthlyCents: 25000, spentMonthlyCents: 9840),
            Agent(id: "cmo", name: "CMO", role: "Chief Marketing Officer", status: .running, reportsToID: "ceo", adapter: "claude-code", budgetMonthlyCents: 12000, spentMonthlyCents: 2100),
            Agent(id: "fe", name: "Founding Engineer", role: "Engineer", status: .running, reportsToID: "cto", adapter: "claude-code", budgetMonthlyCents: 20000, spentMonthlyCents: 18800),
            Agent(id: "qa", name: "QA Engineer", role: "Quality", status: .running, reportsToID: "cto", adapter: "codex", budgetMonthlyCents: 8000, spentMonthlyCents: 3020),
            Agent(id: "ops", name: "DevOps", role: "Infrastructure", status: .idle, reportsToID: "cto", adapter: "claude-code", budgetMonthlyCents: 6000, spentMonthlyCents: 1230),
            Agent(id: "writer", name: "Content Writer", role: "Content", status: .paused, reportsToID: "cmo", adapter: "claude-code", budgetMonthlyCents: 4000, spentMonthlyCents: 0),
        ]
        tasks = [
            WorkItem(id: "t142", identifier: "ATL-142", title: "Split sync worker into queue consumers", status: .inProgress, assigneeID: "cto"),
            WorkItem(id: "t151", identifier: "ATL-151", title: "Offline cache for task list", status: .inProgress, assigneeID: "fe"),
            WorkItem(id: "t139", identifier: "ATL-139", title: "Regression pass on onboarding", status: .inProgress, assigneeID: "qa"),
            WorkItem(id: "t120", identifier: "ATL-120", title: "Draft launch announcement", status: .inProgress, assigneeID: "cmo"),
            WorkItem(id: "t147", identifier: "ATL-147", title: "Connect crash reporting", status: .blocked, assigneeID: "fe"),
            WorkItem(id: "t152", identifier: "ATL-152", title: "Rate-limit public API", status: .todo, assigneeID: "fe"),
            WorkItem(id: "t148", identifier: "ATL-148", title: "Pricing page copy", status: .inReview, assigneeID: "cmo"),
            WorkItem(id: "t133", identifier: "ATL-133", title: "Fix flaky login test", status: .done, assigneeID: "qa"),
            WorkItem(id: "t160", identifier: "ATL-160", title: "Evaluate push provider", status: .backlog),
        ]
        approvals = [
            Approval(id: "h1", kind: .hire, requestedBy: "CEO", title: "Hire a Designer agent", detail: "Reports to CMO. claude-code adapter, $120 monthly cap, heartbeat every 15 min.", createdAt: now - 12 * minute),
            Approval(id: "s1", kind: .strategy, requestedBy: "CEO", title: "Q4 plan: retention over new features", detail: "Moves 6 open tasks to backlog and adds a retention goal for the mobile app.", createdAt: now - 60 * minute),
            Approval(id: "b1", kind: .budget, requestedBy: "CTO", title: "Raise Founding Engineer cap to $250", detail: "Agent is at 94% of its $200 cap with ATL-151 still in progress.", createdAt: now - 120 * minute),
        ]
        runs = [
            Run(id: "r1", agentID: "cto", taskIdentifier: "ATL-142", title: "Split sync worker into queue consumers", adapter: "claude-code", startedAt: now - 12 * minute - 4),
            Run(id: "r2", agentID: "fe", taskIdentifier: "ATL-151", title: "Offline cache for task list", adapter: "claude-code", startedAt: now - 7 * minute - 41, summary: "SQLite cache in place, wiring invalidation now."),
            Run(id: "r3", agentID: "qa", taskIdentifier: "ATL-139", title: "Regression pass on onboarding", adapter: "codex", startedAt: now - 3 * minute - 18),
            Run(id: "r4", agentID: "cmo", taskIdentifier: "ATL-120", title: "Draft launch announcement", adapter: "claude-code", startedAt: now - 62),
            Run(id: "r5", agentID: "fe", taskIdentifier: "ATL-151", title: "Offline cache for task list", adapter: "claude-code", startedAt: now - 40 * minute, finishedAt: now - 35 * minute, costCents: 192, summary: "opened PR #84"),
            Run(id: "r6", agentID: "fe", taskIdentifier: "ATL-147", title: "Connect crash reporting", adapter: "claude-code", startedAt: now - 50 * minute, finishedAt: now - 47 * minute, costCents: 110, summary: "blocked, needs key"),
        ]
        activity = [
            ActivityEvent(id: "e1", at: now - 2 * minute, actor: "QA Engineer", summary: "moved ATL-133 to Done"),
            ActivityEvent(id: "e2", at: now - 14 * minute, actor: "CTO", summary: "opened ATL-152 and assigned it to Founding Engineer"),
            ActivityEvent(id: "e3", at: now - 29 * minute, actor: "CEO", summary: "requested approval to hire a Designer"),
            ActivityEvent(id: "e4", at: now - 46 * minute, actor: "Founding Engineer", summary: "blocked ATL-147: needs API key from board"),
        ]
    }

    public func companies() async throws -> [Company] {
        [company]
    }

    public func snapshot(companyID _: Company.ID) async throws -> CompanySnapshot {
        CompanySnapshot(
            company: company, agents: agents, tasks: tasks, approvals: approvals, runs: runs, activity: activity,
            spentMonthlyCents: agents.reduce(0) { $0 + $1.spentMonthlyCents }, budgetMonthlyCents: 100_000
        )
    }

    public func decide(approvalID: Approval.ID, approve: Bool) async throws {
        guard let index = approvals.firstIndex(where: { $0.id == approvalID }) else { return }
        approvals[index].state = approve ? .approved : .rejected
    }

    public func wake(agentID: Agent.ID) async throws {
        setStatus(.running, agentID: agentID)
    }

    public func pause(agentID: Agent.ID) async throws {
        setStatus(.paused, agentID: agentID)
    }

    public func setCompanyPaused(_ paused: Bool, companyID _: Company.ID) async throws {
        company.isPaused = paused
    }

    private func setStatus(_ status: AgentStatus, agentID: Agent.ID) {
        guard let index = agents.firstIndex(where: { $0.id == agentID }) else { return }
        agents[index].status = status
    }
}
