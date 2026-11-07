import Foundation

/// `FactoryService` backed by a live Paperclip server.
public struct PaperclipFactoryService: FactoryService {
    private let client: PaperclipClient

    public init(client: PaperclipClient) {
        self.client = client
    }

    public func companies() async throws -> [Company] {
        let companies: [CompanyDTO] = try await client.get("companies", query: ["scope": "accessible"])
        return companies.map(Company.init(paperclip:))
    }

    public func snapshot(companyID: Company.ID) async throws -> CompanySnapshot {
        let base = "companies/\(companyID)"
        async let companyDTO: CompanyDTO = client.get(base)
        async let agentDTOs: [AgentDTO] = client.get("\(base)/agents")
        async let issueDTOs: [IssueDTO] = client.get("\(base)/issues", query: ["limit": "500"])
        // Paperclip filters on one exact status; both of these still wait for the board.
        async let pendingDTOs: [ApprovalDTO] = client.get("\(base)/approvals", query: ["status": "pending"])
        async let revisionDTOs: [ApprovalDTO] = client.get("\(base)/approvals", query: ["status": "revision_requested"])
        async let runDTOs = runs(base: base)
        async let activityDTOs: [ActivityDTO] = client.get("\(base)/activity", query: ["limit": "50"])

        let company = try await companyDTO
        let agents = try await agentDTOs.filter { $0.status != "terminated" }.map(Agent.init(paperclip:))
        let tasks = try await issueDTOs.map(WorkItem.init(paperclip:))
        let agentsByID = Dictionary(agents.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let tasksByID = Dictionary(tasks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return try await CompanySnapshot(
            company: Company(paperclip: company),
            agents: agents,
            tasks: tasks,
            approvals: Approval.list(paperclip: pendingDTOs + revisionDTOs, agents: agentsByID),
            runs: runDTOs.map { Run(paperclip: $0, issues: tasksByID, agents: agentsByID) },
            activity: activityDTOs.map { ActivityEvent(paperclip: $0, issues: tasksByID, agents: agentsByID) },
            spentMonthlyCents: company.spentMonthlyCents ?? 0,
            budgetMonthlyCents: positiveCents(company.budgetMonthlyCents)
        )
    }

    /// Run telemetry can be hidden from some board users; that shouldn't hide the rest of the snapshot.
    private func runs(base: String) async throws -> [HeartbeatRunDTO] {
        do {
            return try await client.get("\(base)/heartbeat-runs", query: ["limit": "50"])
        } catch PaperclipError.forbidden {
            return []
        }
    }

    public func credentialExpiry() async throws -> Date? {
        try await client.boardKeyExpiry()
    }

    public func decide(approvalID: Approval.ID, approve: Bool) async throws {
        try await client.send("POST", "approvals/\(approvalID)/\(approve ? "approve" : "reject")")
    }

    /// Resumes a paused agent, then asks it to run a heartbeat now.
    public func wake(agentID: Agent.ID) async throws {
        let agent: AgentDTO = try await client.get("agents/\(agentID)")
        if agent.status == "paused" {
            try await client.send("POST", "agents/\(agentID)/resume")
        }
        try await client.send("POST", "agents/\(agentID)/wakeup", body: ["source": "on_demand", "triggerDetail": "manual"])
    }

    public func pause(agentID: Agent.ID) async throws {
        try await client.send("POST", "agents/\(agentID)/pause")
    }

    public func setCompanyPaused(_ paused: Bool, companyID: Company.ID) async throws {
        try await client.send("PATCH", "companies/\(companyID)", body: ["status": paused ? "paused" : "active"])
    }
}
