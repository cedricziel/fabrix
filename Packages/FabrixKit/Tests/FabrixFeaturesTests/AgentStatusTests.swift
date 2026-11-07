import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

/// The demo company with the idle DevOps agent in the middle of a run.
private struct BusyOpsFactory: FactoryService {
    let base = DemoFactoryService()

    func companies() async throws -> [Company] { try await base.companies() }

    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot {
        var snapshot = try await base.snapshot(companyID: companyID)
        snapshot.runs.append(Run(id: "ops-run", agentID: "ops", title: "Rotate certificates", startedAt: .now - 10))
        return snapshot
    }

    func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
}

@MainActor
struct AgentStatusTests {
    @Test(arguments: AgentStatus.allCases)
    func liveRunShowsAsRunning(reported: AgentStatus) {
        #expect(AgentStatus.shown(reported: reported, hasLiveRun: true) == .running)
        #expect(AgentStatus.shown(reported: reported, hasLiveRun: false) == reported)
    }

    @Test func idleAgentWithALiveRunShowsAsRunning() async throws {
        let model = AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: BusyOpsFactory()),
            defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        await model.refresh()
        let ops = try #require(model.agent("ops"))

        #expect(ops.status == .idle)
        #expect(model.status(of: ops) == .running)
        #expect(model.status(of: try #require(model.agent("writer"))) == .paused)
    }

    @Test func overviewCountsAgentsWithALiveRunAsWorking() async throws {
        let snapshot = try await BusyOpsFactory().snapshot(companyID: "atlas")
        let metrics = OverviewMetrics(snapshot: snapshot, waiting: [])

        #expect(metrics.agentsWorking == 5)
        #expect(metrics.agentsIdle == 0)
    }
}
