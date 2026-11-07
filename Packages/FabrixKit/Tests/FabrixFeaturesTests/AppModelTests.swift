import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
struct AppModelTests {
    private func freshDefaults() -> UserDefaults {
        let name = "AppModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func demoModel() async -> AppModel {
        let model = AppModel(defaults: freshDefaults())
        await model.exploreDemo()
        return model
    }

    @Test func firstLaunchStartsInOnboarding() {
        let model = AppModel(defaults: freshDefaults())
        #expect(model.isOnboarding)
        #expect(model.snapshot == nil)
    }

    @Test func exploringTheDemoLoadsTheDemoCompany() async {
        let model = await demoModel()
        #expect(!model.isOnboarding)
        #expect(model.factory?.name == "Demo factory")
        #expect(model.companies.map(\.name) == ["Atlas"])
        #expect(model.snapshot?.company.name == "Atlas")
    }

    @Test func demoChoiceIsRememberedOnNextLaunch() async {
        let defaults = freshDefaults()
        await AppModel(defaults: defaults).exploreDemo()
        let relaunched = AppModel(defaults: defaults)
        #expect(!relaunched.isOnboarding)
        #expect(relaunched.factory?.name == "Demo factory")
    }

    @Test func connectingIsUnavailableWithoutAConnector() {
        let model = AppModel(defaults: freshDefaults())
        #expect(!model.canConnect)
    }

    @Test func connectingUsesTheConnectorWithANormalizedURL() async throws {
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: freshDefaults())
        #expect(model.canConnect)

        await model.connect(ConnectForm(address: "factory.local:3100", apiKey: "secret"))

        #expect(await connector.calls == [ConnectCall(url: "https://factory.local:3100", auth: .paperclip(apiKey: "secret"))])
        #expect(model.factory?.name == "factory.local")
        #expect(model.snapshot?.company.name == "Atlas")
        #expect(model.connectError == nil)
    }

    @Test func invalidAddressShowsAnErrorWithoutCallingTheConnector() async {
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: freshDefaults())

        await model.connect(ConnectForm(address: "ftp://nope", apiKey: "k"))

        #expect(await connector.calls.isEmpty)
        #expect(model.isOnboarding)
        #expect(model.connectError != nil)
    }

    @Test func connectorFailureStaysInOnboardingWithTheMessage() async {
        let model = AppModel(connector: RecordingConnector(failure: "Unauthorized"), defaults: freshDefaults())
        await model.connect(ConnectForm(address: "https://f.example", apiKey: "bad"))
        #expect(model.isOnboarding)
        #expect(model.connectError == "Unauthorized")
    }

    @Test func lookupsFollowTheSnapshot() async throws {
        let model = await demoModel()
        let task = try #require(model.snapshot?.tasks.first { $0.identifier == "ATL-151" })
        #expect(model.agent("fe")?.name == "Founding Engineer")
        #expect(model.liveRun(for: task)?.id == "r2")
        #expect(model.runs(of: "fe").map(\.id) == ["r2", "r5", "r6"])
    }

    @Test func refreshFromAnOldFactoryIsDroppedAfterSwitching() async {
        let old = GatedService(OtherFactory())
        let model = AppModel(connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: old), defaults: freshDefaults())
        await model.refresh()
        #expect(model.snapshot?.company.name == "Orbit")

        await old.holdNextSnapshot()
        let stale = Task { await model.refresh() }
        await old.waitUntilHolding()
        await model.exploreDemo()
        await old.release()
        await stale.value

        #expect(model.snapshot?.company.name == "Atlas")
        #expect(model.companies.map(\.name) == ["Atlas"])
        #expect(model.loadState == .loaded)
        await model.refresh()
        #expect(model.loadState == .loaded)
    }

    @Test func olderRefreshCannotOverwriteANewerOne() async throws {
        let service = GatedService()
        let model = AppModel(connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service), defaults: freshDefaults())
        await model.refresh()
        let agent = try #require(model.agent("cto"))

        await service.holdNextSnapshot()
        let poll = Task { await model.refresh() }
        await service.waitUntilHolding()
        await model.pause(agent)
        await service.release()
        await poll.value

        #expect(model.agent("cto")?.status == .paused)
    }

    @Test func leavingTheFactoryReturnsToOnboarding() async {
        let defaults = freshDefaults()
        let model = AppModel(defaults: defaults)
        await model.exploreDemo()
        model.disconnect()
        #expect(model.isOnboarding)
        #expect(AppModel(defaults: defaults).isOnboarding)
    }

    @Test func pausingTheCompanyFlipsItsState() async {
        let model = await demoModel()
        await model.setCompanyPaused(true)
        #expect(model.snapshot?.company.isPaused == true)
    }

    @Test func searchFiltersTasksAndAgents() async {
        let model = await demoModel()
        model.searchText = "atl-14"
        #expect(Set(model.visibleTasks.map(\.identifier)) == ["ATL-142", "ATL-147", "ATL-148"])
        model.searchText = "engineer"
        #expect(model.visibleAgents.map(\.name) == ["Founding Engineer", "QA Engineer"])
    }
}

struct ConnectCall: Equatable {
    var url: String
    var auth: FactoryAuth
}

actor RecordingConnector: FactoryConnector {
    private(set) var calls: [ConnectCall] = []
    private let failure: String?

    init(failure: String? = nil) {
        self.failure = failure
    }

    func connect(baseURL: URL, auth: FactoryAuth) async throws -> FactoryConnection {
        calls.append(ConnectCall(url: baseURL.absoluteString, auth: auth))
        if let failure { throw ConnectFailure(message: failure) }
        let factory = Factory(id: "f", name: baseURL.host() ?? "", baseURL: baseURL, isOnline: true)
        return FactoryConnection(factory: factory, service: DemoFactoryService())
    }
}

struct ConnectFailure: LocalizedError {
    var message: String
    var errorDescription: String? { message }
}

@MainActor
struct AppModelLoadStateTests {
    struct EmptyService: FactoryService {
        func companies() async throws -> [Company] { [] }
        func snapshot(companyID _: Company.ID) async throws -> CompanySnapshot { fatalError("unused") }
        func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
        func wake(agentID _: Agent.ID) async throws {}
        func pause(agentID _: Agent.ID) async throws {}
        func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
    }

    struct FailingService: FactoryService {
        struct Boom: Error {}
        func companies() async throws -> [Company] { throw Boom() }
        func snapshot(companyID _: Company.ID) async throws -> CompanySnapshot { throw Boom() }
        func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
        func wake(agentID _: Agent.ID) async throws {}
        func pause(agentID _: Agent.ID) async throws {}
        func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
    }

    private func model(_ service: any FactoryService) -> AppModel {
        let factory = FactoryConnection.demo().factory
        return AppModel(connection: FactoryConnection(factory: factory, service: service), defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    @Test func noCompaniesIsAnEmptyState() async {
        let model = model(EmptyService())
        await model.refresh()
        #expect(model.loadState == .empty)
        #expect(model.snapshot == nil)
    }

    @Test func failureIsAnErrorState() async {
        let model = model(FailingService())
        await model.refresh()
        guard case .failed = model.loadState else {
            Issue.record("expected failed, got \(model.loadState)")
            return
        }
    }

    @Test func successIsLoaded() async {
        let model = model(DemoFactoryService())
        await model.refresh()
        #expect(model.loadState == .loaded)
    }

    @Test func keepFreshLoadsRightAway() async {
        let model = model(DemoFactoryService())
        let polling = Task { await model.keepFresh(every: .seconds(60)) }
        defer { polling.cancel() }
        while model.loadState == .loading { await Task.yield() }
        #expect(model.loadState == .loaded)
    }
}
