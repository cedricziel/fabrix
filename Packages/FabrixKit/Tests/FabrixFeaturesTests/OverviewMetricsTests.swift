import FabrixCore
@testable import FabrixFeatures
import Testing

struct OverviewMetricsTests {
    @Test func countsTheDemoCompany() async throws {
        let snapshot = try await DemoFactoryService().snapshot(companyID: "atlas")
        let metrics = OverviewMetrics(snapshot: snapshot, waiting: snapshot.pendingApprovals)

        #expect(metrics.agentsWorking == 4)
        #expect(metrics.agentsTotal == 7)
        #expect(metrics.agentsIdle == 1)
        #expect(metrics.agentsPaused == 1)
        #expect(metrics.openTasks == 8)
        #expect(metrics.tasksBlocked == 1)
        #expect(metrics.tasksInReview == 1)
        #expect(metrics.waitingByKind == [.hire: 1, .strategy: 1, .budget: 1])
        #expect(metrics.waitingCount == 3)
        #expect(metrics.spend.fraction == 0.412)
    }

    @Test func spendHasNoFractionWithoutACompanyCap() {
        let snapshot = CompanySnapshot(
            company: Company(id: "c", name: "C"), agents: [], tasks: [], approvals: [], runs: [], activity: [],
            spentMonthlyCents: 10, budgetMonthlyCents: nil
        )
        #expect(OverviewMetrics(snapshot: snapshot, waiting: []).spend.fraction == nil)
    }
}
