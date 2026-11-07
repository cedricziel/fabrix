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

        await model.connect(ConnectForm(address: "factory.local:3100", method: .paperclip, apiKey: "secret"))

        #expect(connector.calls == [ConnectCall(url: "https://factory.local:3100", auth: .paperclip(apiKey: "secret"))])
        #expect(model.factory?.name == "factory.local")
        #expect(model.snapshot?.company.name == "Atlas")
        #expect(model.connectError == nil)
    }

    @Test func connectingPassesCustomHeaders() async {
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: freshDefaults())
        var form = ConnectForm(address: "f.example", method: .paperclip, apiKey: "secret")
        form.headers = [ConnectForm.HeaderRow(name: "X-Proxy-Token", value: "proxy-secret")]

        await model.connect(form)

        #expect(connector.calls.first?.headers == [CustomHeader(name: "X-Proxy-Token", value: "proxy-secret")])
    }

    @Test func invalidAddressShowsAnErrorWithoutCallingTheConnector() async {
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: freshDefaults())

        await model.connect(ConnectForm(address: "ftp://nope", method: .paperclip, apiKey: "k"))

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
        await model.connect(ConnectForm(address: "https://f.example", method: .paperclip, apiKey: "bad"))
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
        await AppModel(connector: connector, defaults: defaults).connect(ConnectForm(address: "f.example", method: .paperclip, apiKey: "k"))

        let relaunched = AppModel(connector: connector, defaults: defaults)

        #expect(!relaunched.isOnboarding)
        #expect(relaunched.factory?.name == "f.example")
    }

    @Test func forgottenFactoryFallsBackToOnboarding() async {
        let defaults = freshDefaults()
        let connector = RecordingConnector()
        await AppModel(connector: connector, defaults: defaults).connect(ConnectForm(address: "f.example", method: .paperclip, apiKey: "k"))
        connector.saved = [:]

        #expect(AppModel(connector: connector, defaults: defaults).isOnboarding)
    }

    @Test func connectingReplacesTheDemoOnRelaunch() async {
        let defaults = freshDefaults()
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: defaults)
        await model.exploreDemo()
        model.disconnect()
        await model.connect(ConnectForm(address: "f.example", method: .paperclip, apiKey: "k"))

        #expect(AppModel(connector: connector, defaults: defaults).factory?.name == "f.example")
    }

    @Test func connectingCountsOnlyRealFactories() async {
        let defaults = freshDefaults()
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: defaults)
        await model.exploreDemo()
        #expect(model.connectCount == 0)

        model.disconnect()
        await model.connect(ConnectForm(address: "f.example", apiKey: "k"))
        #expect(model.connectCount == 1)
        #expect(AppModel(connector: connector, defaults: defaults).connectCount == 0)
    }

    @Test func leavingAConnectedFactoryShowsOnboardingNextLaunch() async {
        let defaults = freshDefaults()
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: defaults)
        await model.connect(ConnectForm(address: "f.example", method: .paperclip, apiKey: "k"))
        model.disconnect()

        #expect(AppModel(connector: connector, defaults: defaults).isOnboarding)
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
    var headers: [CustomHeader] = []
}

@MainActor
final class RecordingConnector: FactoryConnector {
    private(set) var calls: [ConnectCall] = []
    private(set) var authenticators = 0
    var error: (any Error)?
    private(set) var revision = 0
    var saved: [Factory.ID: FactoryConnection] = [:]
    private var order: [Factory.ID] = []
    /// Shared by every connection, so tests can see what reached the factory.
    var service: (any FactoryService)?
    var delay: Duration?

    var factories: [Factory] {
        order.compactMap { saved[$0]?.factory }
    }

    init(failure: String? = nil) {
        error = failure.map { ConnectFailure(message: $0) }
    }

    init(error: any Error) {
        self.error = error
    }

    func connect(
        baseURL: URL, auth: FactoryAuth, headers: [CustomHeader], webAuthenticator: (any WebAuthenticator)?
    ) async throws -> FactoryConnection {
        calls.append(ConnectCall(url: baseURL.absoluteString, auth: auth, headers: headers))
        if let delay { try await Task.sleep(for: delay) }
        if webAuthenticator != nil { authenticators += 1 }
        if let error { throw error }
        // Like FactoryStore, connecting to a saved address again keeps its ID.
        let id = factories.first { $0.baseURL == baseURL }?.id ?? "f-\(calls.count)"
        let factory = Factory(id: id, name: baseURL.host() ?? "", baseURL: baseURL, isOnline: true)
        let connection = FactoryConnection(factory: factory, service: service ?? DemoFactoryService(), usesBoardKey: true)
        if saved[id] == nil { order.append(id) }
        saved[id] = connection
        revision += 1
        return connection
    }

    var restoreError: (any Error)?

    func restore(factoryID: Factory.ID) throws -> FactoryConnection? {
        if let restoreError { throw restoreError }
        return saved[factoryID]
    }

    /// How a browser sign-in ends once the app starts waiting.
    enum BrowserOutcome {
        case approve
        case fail(PaperclipError)
        case waitUntilCancelled
    }

    var browserOutcome = BrowserOutcome.approve
    /// Runs before the outcome, e.g. to wait until the approval sheet is up.
    var beforeCompleting: (@Sendable () async -> Void)?
    /// The service a re-signed-in factory gets, standing in for the renewed key.
    var renewedService: any FactoryService = DemoFactoryService()
    private(set) var browserCalls: [ConnectCall] = []
    private(set) var reauthenticated: [Factory.ID] = []
    private(set) var cancelledWaits = 0
    private(set) var cancelledChallenges: [String] = []

    func signInAgainToIdentityProvider(factoryID: Factory.ID, webAuthenticator _: any WebAuthenticator) async throws -> FactoryConnection {
        identityProviderSignIns.append(factoryID)
        guard let existing = saved[factoryID] else { throw PaperclipError.notFound(nil) }
        let renewed = FactoryConnection(factory: existing.factory, service: renewedService, usesBoardKey: existing.usesBoardKey, usesOIDC: existing.usesOIDC)
        saved[factoryID] = renewed
        return renewed
    }

    func cancelBrowserSignIn(_ challenge: SignInChallenge) async throws {
        cancelledChallenges.append(challenge.id)
    }

    func startBrowserSignIn(
        baseURL: URL, auth: FactoryAuth, headers: [CustomHeader], webAuthenticator _: (any WebAuthenticator)?
    ) async throws -> SignInChallenge {
        browserCalls.append(ConnectCall(url: baseURL.absoluteString, auth: auth, headers: headers))
        if let error { throw error }
        return challenge(for: baseURL)
    }

    private(set) var reauthenticators = 0
    private(set) var identityProviderSignIns: [Factory.ID] = []

    func startReauthentication(factoryID: Factory.ID, webAuthenticator: (any WebAuthenticator)?) async throws -> SignInChallenge {
        reauthenticated.append(factoryID)
        if webAuthenticator != nil { reauthenticators += 1 }
        guard let factory = saved[factoryID]?.factory else { throw PaperclipError.notFound(nil) }
        return challenge(for: factory.baseURL)
    }

    func completeBrowserSignIn(_ challenge: SignInChallenge) async throws -> FactoryConnection {
        await beforeCompleting?()
        switch browserOutcome {
        case .approve:
            if let existing = saved.values.first(where: { $0.factory.baseURL == challenge.serverURL }) {
                let renewed = FactoryConnection(factory: existing.factory, service: renewedService, usesBoardKey: true)
                saved[existing.factory.id] = renewed
                return renewed
            }
            let factory = Factory(id: "f-browser", name: challenge.serverURL.host() ?? "", baseURL: challenge.serverURL, isOnline: true)
            let connection = FactoryConnection(factory: factory, service: DemoFactoryService(), usesBoardKey: true)
            saved[factory.id] = connection
            return connection
        case let .fail(error):
            throw error
        case .waitUntilCancelled:
            do {
                try await Task.sleep(for: .seconds(3600))
            } catch {
                cancelledWaits += 1
                throw error
            }
            throw PaperclipError.signInExpired
        }
    }

    private func challenge(for baseURL: URL) -> SignInChallenge {
        SignInChallenge(
            serverURL: baseURL, id: "ch-1", token: "pcp_cli_auth_abc", boardAPIToken: "pcp_board_new",
            approvalURL: baseURL.appending(path: "cli-auth/ch-1"), pollInterval: .zero, expiresAt: .now + 600
        )
    }

    var forgetError: (any Error)?

    func forget(factoryID: Factory.ID) throws {
        if let forgetError { throw forgetError }
        saved[factoryID] = nil
        revision += 1
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
