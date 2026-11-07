import AuthenticationServices
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

        #expect(connector.calls == [ConnectCall(url: "https://factory.local:3100", auth: .paperclip(apiKey: "secret"))])
        #expect(model.factory?.name == "factory.local")
        #expect(model.snapshot?.company.name == "Atlas")
        #expect(model.connectError == nil)
    }

    @Test func invalidAddressShowsAnErrorWithoutCallingTheConnector() async {
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: freshDefaults())

        await model.connect(ConnectForm(address: "ftp://nope", apiKey: "k"))

        #expect(connector.calls.isEmpty)
        #expect(model.isOnboarding)
        #expect(model.connectError != nil)
    }

    @Test(arguments: [
        CancellationError() as any Error,
        ASWebAuthenticationSessionError(.canceledLogin),
        URLError(.cancelled),
        PaperclipError.transport(.cancelled),
    ])
    func cancelledSignInLeavesNoError(cancellation: any Error) async {
        let connector = RecordingConnector(error: cancellation)
        let model = AppModel(connector: connector, defaults: freshDefaults())
        await model.connect(ConnectForm(address: "f.example", method: .oidc, issuer: "auth.example", clientID: "c"))
        #expect(model.isOnboarding)
        #expect(model.connectError == nil)
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

    @Test func failedRefreshKeepsDataAndShowsADismissibleError() async {
        let service = GatedService()
        let model = AppModel(connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service), defaults: freshDefaults())
        await model.refresh()

        await service.failSnapshots(true)
        await model.refresh()
        #expect(model.loadState == .loaded)
        #expect(model.snapshot?.company.name == "Atlas")
        #expect(model.lastError != nil)

        model.dismissError()
        #expect(model.lastError == nil)

        await service.failSnapshots(false)
        await model.refresh()
        #expect(model.lastError == nil)
    }

    @Test func pollDuringCompanySwitchKeepsTheChosenCompany() async throws {
        let service = GatedService(TwoCompanyFactory())
        let model = AppModel(connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service), defaults: freshDefaults())
        await model.refresh()
        #expect(model.snapshot?.company.name == "Atlas")
        let orbit = try #require(model.companies.first { $0.name == "Orbit" })

        await service.holdNextSnapshot()
        let switching = Task { await model.select(orbit) }
        await service.waitUntilHolding()
        await model.refresh()
        await service.release()
        await switching.value

        #expect(model.snapshot?.company.name == "Orbit")
        await model.refresh()
        #expect(model.snapshot?.company.name == "Orbit")
    }

    @Test func cancelledFirstLoadIsNotAFailure() async {
        let model = AppModel(connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: GatedService()), defaults: freshDefaults())
        let load = Task { await model.refresh() }
        load.cancel()
        await load.value
        #expect(model.loadState == .loading)
        #expect(model.lastError == nil)

        let polling = Task { await model.keepFresh(every: .seconds(60)) }
        defer { polling.cancel() }
        for _ in 0 ..< 1000 where model.loadState != .loaded {
            await Task.yield()
        }
        #expect(model.loadState == .loaded)
    }

    @Test func failedCompanySwitchCanBeRetried() async throws {
        let service = GatedService(TwoCompanyFactory())
        let model = AppModel(connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service), defaults: freshDefaults())
        await model.refresh()
        let orbit = try #require(model.companies.first { $0.name == "Orbit" })

        await service.failSnapshots(true)
        await model.select(orbit)
        #expect(model.snapshot?.company.name == "Atlas")
        #expect(model.lastError != nil)

        await service.failSnapshots(false)
        await model.select(orbit)
        #expect(model.snapshot?.company.name == "Orbit")
    }

    @Test func keepFreshReloadsRightAwayWhenDataIsStale() async {
        let service = GatedService()
        let model = AppModel(connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service), defaults: freshDefaults())
        await model.refresh()
        let before = await service.snapshotCalls

        let polling = Task { await model.keepFresh(every: .seconds(60), staleAfter: .zero) }
        defer { polling.cancel() }
        for _ in 0 ..< 1000 where await service.snapshotCalls == before {
            await Task.yield()
        }
        #expect(await service.snapshotCalls > before)
    }

    @Test func keepFreshWaitsWhenDataIsRecent() async {
        let service = GatedService()
        let model = AppModel(connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service), defaults: freshDefaults())
        await model.refresh()
        let before = await service.snapshotCalls

        let polling = Task { await model.keepFresh(every: .seconds(60)) }
        for _ in 0 ..< 200 { await Task.yield() }
        polling.cancel()
        #expect(await service.snapshotCalls == before)
    }

    @Test func connectedFactoryReopensOnNextLaunch() async {
        let defaults = freshDefaults()
        let connector = RecordingConnector()
        await AppModel(connector: connector, defaults: defaults).connect(ConnectForm(address: "f.example", apiKey: "k"))

        let relaunched = AppModel(connector: connector, defaults: defaults)

        #expect(!relaunched.isOnboarding)
        #expect(relaunched.factory?.name == "f.example")
    }

    @Test func forgottenFactoryFallsBackToOnboarding() async {
        let defaults = freshDefaults()
        let connector = RecordingConnector()
        await AppModel(connector: connector, defaults: defaults).connect(ConnectForm(address: "f.example", apiKey: "k"))
        connector.saved = [:]

        #expect(AppModel(connector: connector, defaults: defaults).isOnboarding)
    }

    @Test func connectingReplacesTheDemoOnRelaunch() async {
        let defaults = freshDefaults()
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: defaults)
        await model.exploreDemo()
        model.disconnect()
        await model.connect(ConnectForm(address: "f.example", apiKey: "k"))

        #expect(AppModel(connector: connector, defaults: defaults).factory?.name == "f.example")
    }

    @Test func leavingAConnectedFactoryShowsOnboardingNextLaunch() async {
        let defaults = freshDefaults()
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: defaults)
        await model.connect(ConnectForm(address: "f.example", apiKey: "k"))
        model.disconnect()

        #expect(AppModel(connector: connector, defaults: defaults).isOnboarding)
    }

    @Test func forgettingAFactoryDeletesItAndReturnsToOnboarding() async {
        let defaults = freshDefaults()
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: defaults)
        await model.connect(ConnectForm(address: "f.example", apiKey: "k"))
        #expect(model.canForgetFactory)

        model.forgetFactory()

        #expect(model.isOnboarding)
        #expect(connector.saved.isEmpty)
        #expect(AppModel(connector: connector, defaults: defaults).isOnboarding)
    }

    @Test func failedForgetKeepsTheFactoryOpen() async {
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: freshDefaults())
        await model.connect(ConnectForm(address: "f.example", apiKey: "k"))
        connector.forgetError = ConnectFailure(message: "Keychain locked")

        model.forgetFactory()

        #expect(!model.isOnboarding)
        #expect(model.lastError == "Keychain locked")
    }

    @Test func theDemoCannotBeForgotten() async {
        let model = AppModel(connector: RecordingConnector(), defaults: freshDefaults())
        await model.exploreDemo()
        #expect(!model.canForgetFactory)
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

@MainActor
final class RecordingConnector: FactoryConnector {
    private(set) var calls: [ConnectCall] = []
    private(set) var authenticators = 0
    private let error: (any Error)?
    var saved: [Factory.ID: FactoryConnection] = [:]

    init(failure: String? = nil) {
        error = failure.map { ConnectFailure(message: $0) }
    }

    init(error: any Error) {
        self.error = error
    }

    func connect(baseURL: URL, auth: FactoryAuth, webAuthenticator: (any WebAuthenticator)?) async throws -> FactoryConnection {
        calls.append(ConnectCall(url: baseURL.absoluteString, auth: auth))
        if webAuthenticator != nil { authenticators += 1 }
        if let error { throw error }
        let factory = Factory(id: "f-\(calls.count)", name: baseURL.host() ?? "", baseURL: baseURL, isOnline: true)
        let connection = FactoryConnection(factory: factory, service: DemoFactoryService())
        saved[factory.id] = connection
        return connection
    }

    func restore(factoryID: Factory.ID) -> FactoryConnection? {
        saved[factoryID]
    }

    var forgetError: (any Error)?

    func forget(factoryID: Factory.ID) throws {
        if let forgetError { throw forgetError }
        saved[factoryID] = nil
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
