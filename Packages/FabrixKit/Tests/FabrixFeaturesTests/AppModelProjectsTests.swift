import FabrixCore
@testable import FabrixFeatures
import Foundation
import Testing

/// The demo factory with a second company and scriptable project answers.
actor ProjectsFactory: FactoryService {
    enum Answer {
        case demo
        case fail
        case unsupported
    }

    private let demo = DemoFactoryService()
    private var answer = Answer.demo
    private var failingOrbit = false
    private(set) var projectCalls = 0

    func answer(_ answer: Answer) {
        self.answer = answer
    }

    func failOrbitSnapshots() {
        failingOrbit = true
    }

    func companies() async throws -> [Company] {
        try await demo.companies() + [Company(id: "orbit", name: "Orbit")]
    }

    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot {
        if companyID == "orbit", failingOrbit { throw URLError(.timedOut) }
        var snapshot = try await demo.snapshot(companyID: "atlas")
        if companyID == "orbit" {
            snapshot.company = Company(id: "orbit", name: "Orbit")
        }
        return snapshot
    }

    func projects(companyID: Company.ID) async throws -> [Project] {
        projectCalls += 1
        return switch answer {
        case .demo:
            companyID == "orbit" ? [Project(id: "orbit-site", name: "Orbit site", status: .planned)] : try await demo.projects(companyID: companyID)
        case .fail: throw URLError(.notConnectedToInternet)
        case .unsupported: throw FactoryServiceError.unsupported
        }
    }

    func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
}

@MainActor
struct AppModelProjectsTests {
    private func model(_ service: ProjectsFactory) -> AppModel {
        let name = "AppModelProjectsTests.\(UUID().uuidString)"
        let connection = FactoryConnection(factory: FactoryConnection.demo().factory, service: service)
        return AppModel(connection: connection, defaults: UserDefaults(suiteName: name)!)
    }

    @Test func loadsBesideSnapshot() async {
        let model = model(ProjectsFactory())
        #expect(model.projectsState == .loading)
        await model.refresh()
        #expect(model.projects.map(\.name).contains("Mobile app"))
    }

    @Test func failureKeepsCompanyUsable() async {
        let service = ProjectsFactory()
        await service.answer(.fail)
        let model = model(service)
        await model.refresh()
        #expect(model.loadState == .loaded)
        #expect(model.lastError == nil)
        guard case let .failed(_, last) = model.projectsState else {
            Issue.record("expected failed, got \(model.projectsState)")
            return
        }
        #expect(last.isEmpty)
    }

    @Test func refreshFailureKeepsLastList() async {
        let service = ProjectsFactory()
        let model = model(service)
        await model.refresh()
        let loaded = model.projects
        await service.answer(.fail)
        await model.refresh()
        #expect(model.projects == loaded)
        #expect(model.projectsFailure != nil)
    }

    @Test func retryAfterFailure() async {
        let service = ProjectsFactory()
        await service.answer(.fail)
        let model = model(service)
        await model.refresh()
        await service.answer(.demo)
        await model.retryProjects()
        #expect(model.projectsFailure == nil)
        #expect(!model.projects.isEmpty)
    }

    @Test func unsupportedHidesProjects() async {
        let service = ProjectsFactory()
        await service.answer(.unsupported)
        let model = model(service)
        await model.refresh()
        #expect(model.projectsState == .unsupported)
        #expect(!model.supportsProjects)
        #expect(model.lastError == nil)
    }

    @Test func unsupportedIsNotAskedAgain() async {
        let service = ProjectsFactory()
        await service.answer(.unsupported)
        let model = model(service)
        await model.refresh()
        await model.refresh()
        await model.refresh()
        #expect(await service.projectCalls == 1)
        #expect(model.projectsState == .unsupported)
    }

    @Test func failedSwitchReloadsTheShownCompanysProjects() async throws {
        let service = ProjectsFactory()
        let model = model(service)
        await model.refresh()
        await service.failOrbitSnapshots()
        try await model.select(#require(model.companies.first { $0.id == "orbit" }))
        #expect(model.snapshot?.company.id == "atlas")
        #expect(model.projects.map(\.name).contains("Mobile app"))
    }

    @Test func switchCompanySwapsProjects() async throws {
        let model = model(ProjectsFactory())
        await model.refresh()
        let orbit = try #require(model.companies.first { $0.id == "orbit" })
        await model.select(orbit)
        #expect(model.projects.map(\.id) == ["orbit-site"])
    }
}

@MainActor
struct TaskProjectFilterTests {
    private func model() async -> AppModel {
        let name = "TaskProjectFilterTests.\(UUID().uuidString)"
        let connection = FactoryConnection(factory: FactoryConnection.demo().factory, service: ProjectsFactory())
        let model = AppModel(connection: connection, defaults: UserDefaults(suiteName: name)!)
        await model.refresh()
        return model
    }

    @Test func filterByProject() async {
        let model = await model()
        model.taskProjectFilter = .project("mobile")
        #expect(!model.visibleTasks.isEmpty)
        #expect(model.visibleTasks.allSatisfy { $0.projectID == "mobile" })
    }

    @Test func filterNoProject() async {
        let model = await model()
        model.taskProjectFilter = .none
        #expect(!model.visibleTasks.isEmpty)
        #expect(model.visibleTasks.allSatisfy { $0.projectID == nil })
    }

    @Test func filterCombinesWithSearch() async {
        let model = await model()
        model.taskProjectFilter = .project("mobile")
        model.searchText = "offline"
        #expect(model.visibleTasks.map(\.identifier) == ["ATL-151"])
    }

    @Test func filterResetsOnCompanySwitch() async throws {
        let model = await model()
        model.taskProjectFilter = .project("mobile")
        try await model.select(#require(model.companies.first { $0.id == "orbit" }))
        #expect(model.taskProjectFilter == .all)
    }

    @Test func chipOnlyWhenUnfiltered() async throws {
        let model = await model()
        let task = try #require(model.snapshot?.tasks.first { $0.projectID == "mobile" })
        let loose = try #require(model.snapshot?.tasks.first { $0.projectID == nil })
        #expect(model.chipProject(for: task)?.name == "Mobile app")
        #expect(model.chipProject(for: loose) == nil)
        model.taskProjectFilter = .project("mobile")
        #expect(model.chipProject(for: task) == nil)
    }
}
