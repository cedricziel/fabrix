import FabrixCore
import Testing

struct InboxServiceDefaultsTests {
    private struct MinimalFactory: FactoryService {
        func companies() async throws -> [Company] { [] }
        func snapshot(companyID _: Company.ID) async throws -> CompanySnapshot { fatalError("unused") }
        func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
        func wake(agentID _: Agent.ID) async throws {}
        func pause(agentID _: Agent.ID) async throws {}
        func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
    }

    @Test func defaultAttentionIsUnsupported() async {
        await #expect(throws: FactoryServiceError.unsupported) {
            try await MinimalFactory().attention(companyID: "c", view: .mine, cursor: nil)
        }
    }

    @Test func defaultPeopleIsUnsupported() async {
        await #expect(throws: FactoryServiceError.unsupported) {
            try await MinimalFactory().people(companyID: "c")
        }
    }
}
