import FabrixCore
import Testing

struct ProjectModelTests {
    private struct MinimalFactory: FactoryService {
        func companies() async throws -> [Company] { [] }
        func snapshot(companyID _: Company.ID) async throws -> CompanySnapshot { fatalError("unused") }
        func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
        func wake(agentID _: Agent.ID) async throws {}
        func pause(agentID _: Agent.ID) async throws {}
        func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
    }

    @Test func activeStatuses() {
        #expect(ProjectStatus.allCases.filter(\.isActive) == [.backlog, .planned, .inProgress])
    }

    @Test func defaultProjectsIsUnsupported() async {
        await #expect(throws: FactoryServiceError.unsupported) {
            try await MinimalFactory().projects(companyID: "c")
        }
    }
}
