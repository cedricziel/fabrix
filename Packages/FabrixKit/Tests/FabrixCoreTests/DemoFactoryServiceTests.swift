@testable import FabrixCore
import Testing

struct DemoFactoryServiceTests {
    @Test func approvingRemovesItFromPending() async throws {
        let service = DemoFactoryService()
        let company = try #require(try await service.companies().first)
        let before = try await service.snapshot(companyID: company.id)
        let approval = try #require(before.pendingApprovals.first)

        try await service.decide(approvalID: approval.id, approve: true)

        let after = try await service.snapshot(companyID: company.id)
        #expect(after.pendingApprovals.count == before.pendingApprovals.count - 1)
        #expect(after.approvals.first { $0.id == approval.id }?.state == .approved)
    }

    @Test func pausingAnAgentMarksItPaused() async throws {
        let service = DemoFactoryService()
        let company = try #require(try await service.companies().first)
        let agent = try #require(try await service.snapshot(companyID: company.id).agents.first { $0.status == .running })

        try await service.pause(agentID: agent.id)

        let after = try await service.snapshot(companyID: company.id)
        #expect(after.agents.first { $0.id == agent.id }?.status == .paused)
    }

    @Test func demoHasProjects() async throws {
        let service = DemoFactoryService()
        let company = try #require(try await service.companies().first)
        let projects = try await service.projects(companyID: company.id)
        let snapshot = try await service.snapshot(companyID: company.id)
        let agentIDs = Set(snapshot.agents.map(\.id))

        #expect(projects.contains { $0.status.isActive })
        #expect(projects.contains { !$0.status.isActive })
        #expect(projects.contains { $0.leadAgentID.map(agentIDs.contains) == true })
        #expect(projects.contains { $0.leadAgentID == nil })
        #expect(projects.contains { $0.repositories.isEmpty })
        let projectIDs = Set(projects.map(\.id))
        #expect(snapshot.tasks.contains { $0.status == .blocked && $0.projectID.map(projectIDs.contains) == true })
    }

    @Test func initialsUseFirstLettersOfTwoWords() {
        #expect(Agent(id: "1", name: "Founding Engineer", status: .idle).initials == "FE")
        #expect(Agent(id: "2", name: "CTO", status: .idle).initials == "CT")
    }
}
