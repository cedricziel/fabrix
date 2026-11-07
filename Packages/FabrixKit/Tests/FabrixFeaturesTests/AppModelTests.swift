import FabrixCore
@testable import FabrixFeatures
import Testing

@MainActor
struct AppModelTests {
    @Test func refreshLoadsTheFirstCompany() async {
        let model = AppModel(service: DemoFactoryService())
        await model.refresh()
        #expect(model.snapshot?.company.name == "Atlas")
    }

    @Test func decidingAnApprovalRefreshesTheSnapshot() async throws {
        let model = AppModel(service: DemoFactoryService())
        await model.refresh()
        let approval = try #require(model.snapshot?.pendingApprovals.first)

        await model.decide(approval, approve: false)

        #expect(model.snapshot?.pendingApprovals.contains { $0.id == approval.id } == false)
    }
}
