@testable import FabrixCore
import Foundation
import Testing

struct PaperclipFactoryServiceTests {
    private let companyID = PaperclipFixtures.companyID

    private var snapshotRoutes: [String: StubURLProtocol.Response] {
        [
            "GET /api/companies/\(companyID)": .json(PaperclipFixtures.company),
            "GET /api/companies/\(companyID)/agents": .json(PaperclipFixtures.agents),
            "GET /api/companies/\(companyID)/issues": .json(PaperclipFixtures.issues),
            "GET /api/companies/\(companyID)/approvals": .json(PaperclipFixtures.approvals),
            "GET /api/companies/\(companyID)/heartbeat-runs": .json(PaperclipFixtures.heartbeatRuns),
            "GET /api/companies/\(companyID)/activity": .json(PaperclipFixtures.activity),
        ]
    }

    private func service(_ routes: [String: StubURLProtocol.Response], recorder: RequestRecorder? = nil) -> PaperclipFactoryService {
        let server = FakeServer(routes: routes, recorder: recorder)
        return PaperclipFactoryService(client: PaperclipClient(baseURL: server.baseURL, credential: "k", session: server.session))
    }

    private func snapshot() async throws -> CompanySnapshot {
        try await service(snapshotRoutes).snapshot(companyID: companyID)
    }

    private func date(_ text: String) -> Date {
        try! Date(text, strategy: .iso8601)
    }

    @Test func listsAccessibleCompanies() async throws {
        let recorder = RequestRecorder()
        let companies = try await service(["GET /api/companies": .json(PaperclipFixtures.companies)], recorder: recorder).companies()

        #expect(companies == [
            Company(id: companyID, name: "Atlas", mission: "Ship the calmest task app on the App Store"),
            Company(id: "c2", name: "Beacon", isPaused: true),
        ])
        #expect(recorder.requests.first?.url?.query() == "scope=accessible")
    }

    @Test func snapshotMapsCompanyAndBudget() async throws {
        let snapshot = try await snapshot()

        #expect(snapshot.company.name == "Atlas")
        #expect(snapshot.spentMonthlyCents == 40200)
        #expect(snapshot.budgetMonthlyCents == 100_000)
    }

    @Test func snapshotMapsAgentsAndDropsTerminated() async throws {
        let agents = try await snapshot().agents

        #expect(agents == [
            Agent(id: "a-ceo", name: "CEO", role: "Chief Executive", status: .needsYou, adapter: "claude_local", budgetMonthlyCents: 15000, spentMonthlyCents: 6210),
            Agent(id: "a-cto", name: "CTO", role: "cto", status: .running, reportsToID: "a-ceo", adapter: "codex_local", budgetMonthlyCents: nil, spentMonthlyCents: 9840),
            Agent(id: "a-ops", name: "DevOps", role: "Infrastructure", status: .paused, reportsToID: "a-cto", adapter: "claude_local", budgetMonthlyCents: 6000, spentMonthlyCents: 1230),
        ])
    }

    @Test(arguments: [
        ("running", AgentStatus.running), ("active", .idle), ("idle", .idle), ("paused", .paused),
        ("error", .error), ("pending_approval", .needsYou), ("hibernating", .idle),
    ])
    func mapsAgentStatus(raw: String, expected: AgentStatus) {
        #expect(AgentStatus(paperclip: raw) == expected)
    }

    @Test(arguments: [
        ("backlog", TaskStatus.backlog), ("todo", .todo), ("in_progress", .inProgress), ("in_review", .inReview),
        ("blocked", .blocked), ("done", .done), ("cancelled", .cancelled), ("archived", .backlog),
    ])
    func mapsTaskStatus(raw: String, expected: TaskStatus) {
        #expect(TaskStatus(paperclip: raw) == expected)
    }

    @Test(arguments: [
        ("hire_agent", ApprovalKind.hire), ("approve_ceo_strategy", .strategy),
        ("budget_override_required", .budget), ("request_board_approval", .other), ("new_kind", .other),
    ])
    func mapsApprovalKind(raw: String, expected: ApprovalKind) {
        #expect(ApprovalKind(paperclip: raw) == expected)
    }

    @Test(arguments: [
        ("pending", ApprovalState.pending), ("revision_requested", .pending), ("approved", .approved),
        ("rejected", .rejected), ("cancelled", .rejected),
    ])
    func mapsApprovalState(raw: String, expected: ApprovalState) {
        #expect(ApprovalState(paperclip: raw) == expected)
    }

    @Test func snapshotMapsTasks() async throws {
        let tasks = try await snapshot().tasks

        #expect(tasks == [
            WorkItem(id: "i-142", identifier: "ATL-142", title: "Split sync worker into queue consumers", status: .inProgress, assigneeID: "a-cto", updatedAt: date("2026-11-07T09:50:00Z")),
            WorkItem(id: "i-160", identifier: "ATL-160", title: "Evaluate push provider", status: .backlog, updatedAt: date("2026-11-06T08:00:00Z")),
        ])
    }

    @Test func snapshotRequestsPendingApprovalsAndBoundedLists() async throws {
        let recorder = RequestRecorder()
        _ = try await service(snapshotRoutes, recorder: recorder).snapshot(companyID: companyID)

        #expect(recorder.last("GET", "/api/companies/\(companyID)/approvals")?.url?.query() == "status=pending")
        #expect(recorder.last("GET", "/api/companies/\(companyID)/issues")?.url?.query() == "limit=500")
        #expect(recorder.last("GET", "/api/companies/\(companyID)/heartbeat-runs")?.url?.query() == "limit=50")
        #expect(recorder.last("GET", "/api/companies/\(companyID)/activity")?.url?.query() == "limit=50")
    }

    @Test func snapshotMapsApprovals() async throws {
        let approvals = try await snapshot().approvals

        #expect(approvals == [
            Approval(id: "ap-hire", kind: .hire, requestedBy: "CEO", title: "Hire Designer", detail: "Product Designer · claude_local · UI and brand", createdAt: date("2026-11-07T09:48:00Z")),
            Approval(id: "ap-plan", kind: .strategy, requestedBy: "CEO", title: "Q4 plan", detail: "Retention over new features.", createdAt: date("2026-11-07T09:00:00Z")),
            Approval(id: "ap-budget", kind: .budget, requestedBy: "Board", title: "Budget override for CTO", detail: "Raise the cap or pause the agent.", createdAt: date("2026-11-07T08:00:00Z")),
            Approval(id: "ap-other", kind: .other, requestedBy: "Board", title: "Board approval", detail: "", createdAt: date("2026-11-07T07:00:00Z"), state: .rejected),
        ])
    }

    @Test func snapshotMapsHeartbeatRuns() async throws {
        let runs = try await snapshot().runs

        #expect(runs == [
            Run(id: "r-1", agentID: "a-cto", taskIdentifier: "ATL-142", title: "Split sync worker into queue consumers", adapter: "codex_local", startedAt: date("2026-11-07T09:48:00Z")),
            Run(id: "r-0", agentID: "a-cto", title: "Scheduled heartbeat", adapter: "codex_local", startedAt: date("2026-11-07T09:00:00Z"), finishedAt: date("2026-11-07T09:04:00Z"), costCents: 192, summary: "opened PR #84"),
            Run(id: "r-q", agentID: "a-ceo", title: "Manual wake", adapter: "claude_local", startedAt: date("2026-11-07T09:59:00Z")),
        ])
    }

    @Test func finishedRunWithoutFinishTimeIsNotLive() {
        let dto = HeartbeatRunDTO(id: "r", agentId: "a", status: "failed", startedAt: nil, finishedAt: nil, createdAt: date("2026-11-07T09:00:00Z"), updatedAt: date("2026-11-07T09:05:00Z"), error: "boom")

        let run = Run(paperclip: dto, issues: [:], agents: [:])

        #expect(!run.isLive)
        #expect(run.finishedAt == date("2026-11-07T09:05:00Z"))
        #expect(run.summary == "boom")
    }

    @Test(arguments: [
        (#""costUsd": 0.5, "usageJson": { "costUsd": 9 }"#, 50),
        (#""costUsd": null, "usageJson": { "costUsd": 1.25 }"#, 125),
        (#""usageJson": { "inputTokens": 10 }"#, nil),
    ])
    func readsRunCostFromRowThenUsage(fields: String, expectedCents: Int?) throws {
        let json = #"{"id":"r","agentId":"a","status":"succeeded","createdAt":"2026-11-07T09:00:00Z",\#(fields)}"#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(HeartbeatRunDTO.self, from: Data(json.utf8))

        #expect(Run(paperclip: dto, issues: [:], agents: [:]).costCents == expectedCents)
    }

    @Test func snapshotToleratesHiddenRunTelemetry() async throws {
        var routes = snapshotRoutes
        routes["GET /api/companies/\(companyID)/heartbeat-runs"] = .json(#"{"error":"Run telemetry is restricted"}"#, status: 403)

        let snapshot = try await service(routes).snapshot(companyID: companyID)

        #expect(snapshot.runs.isEmpty)
        #expect(snapshot.agents.count == 3)
    }

    @Test func snapshotSurfacesOtherFailures() async throws {
        var routes = snapshotRoutes
        routes["GET /api/companies/\(companyID)/agents"] = .json(#"{"error":"Board authentication required"}"#, status: 401)

        await #expect(throws: PaperclipError.unauthorized("Board authentication required")) {
            try await service(routes).snapshot(companyID: companyID)
        }
    }

    @Test func snapshotMapsActivity() async throws {
        let activity = try await snapshot().activity

        #expect(activity == [
            ActivityEvent(id: "e-1", at: date("2026-11-07T09:50:00Z"), actor: "CTO", summary: "updated issue ATL-142"),
            ActivityEvent(id: "e-2", at: date("2026-11-05T12:00:00Z"), actor: "Board", summary: "paused agent DevOps"),
        ])
    }

    @Test(arguments: [(true, "/api/approvals/ap-1/approve"), (false, "/api/approvals/ap-1/reject")])
    func decidesApprovals(approve: Bool, path: String) async throws {
        let recorder = RequestRecorder()
        let service = service(["POST \(path)": .json(#"{"id":"ap-1"}"#)], recorder: recorder)

        try await service.decide(approvalID: "ap-1", approve: approve)

        #expect(recorder.last("POST", path) != nil)
    }

    @Test func pausesAgent() async throws {
        let recorder = RequestRecorder()
        try await service(["POST /api/agents/a-cto/pause": .json(PaperclipFixtures.agentPaused)], recorder: recorder).pause(agentID: "a-cto")

        #expect(recorder.last("POST", "/api/agents/a-cto/pause") != nil)
    }

    @Test func wakesIdleAgentWithManualWakeup() async throws {
        let recorder = RequestRecorder()
        let service = service([
            "GET /api/agents/a-cto": .json(PaperclipFixtures.agentIdle),
            "POST /api/agents/a-cto/wakeup": .json(#"{"id":"run-1","status":"queued"}"#, status: 202),
        ], recorder: recorder)

        try await service.wake(agentID: "a-cto")

        #expect(recorder.last("POST", "/api/agents/a-cto/resume") == nil)
        let body = try #require(recorder.last("POST", "/api/agents/a-cto/wakeup")?.httpBody)
        #expect(try JSONSerialization.jsonObject(with: body) as? [String: String] == ["source": "on_demand", "triggerDetail": "manual"])
    }

    @Test func wakesPausedAgentByResumingFirst() async throws {
        let recorder = RequestRecorder()
        let service = service([
            "GET /api/agents/a-ops": .json(PaperclipFixtures.agentPaused),
            "POST /api/agents/a-ops/resume": .json(PaperclipFixtures.agentIdle),
            "POST /api/agents/a-ops/wakeup": .json(#"{"id":"run-1","status":"queued"}"#, status: 202),
        ], recorder: recorder)

        try await service.wake(agentID: "a-ops")

        #expect(recorder.requests.map { "\($0.httpMethod!) \($0.url!.path())" } == [
            "GET /api/agents/a-ops", "POST /api/agents/a-ops/resume", "POST /api/agents/a-ops/wakeup",
        ])
    }

    @Test(arguments: [(true, "paused"), (false, "active")])
    func setsCompanyPaused(paused: Bool, status: String) async throws {
        let recorder = RequestRecorder()
        let service = service(["PATCH /api/companies/\(companyID)": .json(PaperclipFixtures.company)], recorder: recorder)

        try await service.setCompanyPaused(paused, companyID: companyID)

        let body = try #require(recorder.last("PATCH", "/api/companies/\(companyID)")?.httpBody)
        #expect(try JSONSerialization.jsonObject(with: body) as? [String: String] == ["status": status])
    }
}
