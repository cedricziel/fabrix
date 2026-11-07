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

@MainActor
@Suite struct AppModelLoadStateTests {
    struct EmptyService: FactoryService {
        func companies() async throws -> [Company] { [] }
        func snapshot(companyID: Company.ID) async throws -> CompanySnapshot { fatalError("unused") }
        func decide(approvalID: Approval.ID, approve: Bool) async throws {}
        func wake(agentID: Agent.ID) async throws {}
        func pause(agentID: Agent.ID) async throws {}
        func setCompanyPaused(_ paused: Bool, companyID: Company.ID) async throws {}
    }

    struct FailingService: FactoryService {
        struct Boom: Error {}
        func companies() async throws -> [Company] { throw Boom() }
        func snapshot(companyID: Company.ID) async throws -> CompanySnapshot { throw Boom() }
        func decide(approvalID: Approval.ID, approve: Bool) async throws {}
        func wake(agentID: Agent.ID) async throws {}
        func pause(agentID: Agent.ID) async throws {}
        func setCompanyPaused(_ paused: Bool, companyID: Company.ID) async throws {}
    }

    @Test func noCompaniesIsAnEmptyState() async {
        let model = AppModel(service: EmptyService())
        await model.refresh()
        #expect(model.loadState == .empty)
        #expect(model.snapshot == nil)
    }

    @Test func failureIsAnErrorState() async {
        let model = AppModel(service: FailingService())
        await model.refresh()
        guard case .failed = model.loadState else {
            Issue.record("expected failed, got \(model.loadState)")
            return
        }
    }

    @Test func successIsLoaded() async {
        let model = AppModel(service: DemoFactoryService())
        await model.refresh()
        #expect(model.loadState == .loaded)
    }
}
