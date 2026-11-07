import AuthenticationServices
import FabrixCore
import Foundation
@testable import FabrixFeatures
import Synchronization
import Testing

/// Answers like a factory whose board key was rejected, and counts how often it was asked.
private final class RejectingService: FactoryService {
    let calls = Mutex(0)

    func companies() async throws -> [Company] {
        calls.withLock { $0 += 1 }
        throw PaperclipError.unauthorized("Board authentication required")
    }

    func snapshot(companyID _: Company.ID) async throws -> CompanySnapshot { throw PaperclipError.unauthorized(nil) }
    func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
}

/// Atlas loads; switching to Orbit is refused because the key expired.
private final class ExpiresOnSwitchService: FactoryService {
    let base = DemoFactoryService()
    let projectCalls = Mutex(0)

    func companies() async throws -> [Company] {
        try await base.companies() + [Company(id: "orbit", name: "Orbit")]
    }

    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot {
        if companyID == "orbit" { throw PaperclipError.unauthorized("Board authentication required") }
        return try await base.snapshot(companyID: companyID)
    }

    func projects(companyID: Company.ID) async throws -> [Project] {
        projectCalls.withLock { $0 += 1 }
        return try await base.projects(companyID: companyID)
    }

    func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
}

private struct ExpiringService: FactoryService {
    let base = DemoFactoryService()
    let expiry: Date

    func companies() async throws -> [Company] { try await base.companies() }
    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot { try await base.snapshot(companyID: companyID) }
    func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
    func credentialExpiry() async throws -> Date? { expiry }
}

/// Plays the web authentication sheet that shows Paperclip's approval page. The page never
/// redirects back, so the sheet stays up until the flow dismisses it or the user closes it.
private final class ApprovalSheet: WebAuthenticator {
    enum Mode { case staysOpen, closedByUser }

    private let mode: Mode
    private let state = Mutex<(opened: [URL], dismissed: Bool)>(([], false))

    init(_ mode: Mode = .staysOpen) {
        self.mode = mode
    }

    var opened: [URL] { state.withLock { $0.opened } }
    var dismissed: Bool { state.withLock { $0.dismissed } }

    func waitUntilOpened() async {
        while opened.isEmpty {
            await Task.yield()
        }
    }

    func authenticate(url: URL, callbackScheme _: String) async throws -> URL {
        state.withLock { $0.opened.append(url) }
        if mode == .closedByUser { throw ASWebAuthenticationSessionError(.canceledLogin) }
        do {
            try await Task.sleep(for: .seconds(3600))
        } catch {
            state.withLock { $0.dismissed = true }
            throw error
        }
        throw CancellationError()
    }
}

@MainActor
struct BrowserSignInTests {
    private let defaults = UserDefaults(suiteName: "BrowserSignInTests.\(UUID().uuidString)")!

    private func model(_ connector: RecordingConnector) -> AppModel {
        AppModel(connector: connector, defaults: defaults)
    }

    /// Connects with a pasted key, then relaunches with the saved factory answering through `service`.
    private func relaunched(
        _ connector: RecordingConnector, service: any FactoryService, usesBoardKey: Bool = true, usesOIDC: Bool = false
    ) async -> AppModel {
        let first = model(connector)
        await first.connect(ConnectForm(address: "factory.example", method: .paperclip, apiKey: "old"))
        let factory = first.factory!
        connector.saved[factory.id] = FactoryConnection(factory: factory, service: service, usesBoardKey: usesBoardKey, usesOIDC: usesOIDC)
        let model = model(connector)
        await model.refresh()
        return model
    }

    private func waitUntilWaiting(_ model: AppModel) async {
        while model.browserSignIn == nil || model.browserSignIn?.failure != nil {
            await Task.yield()
        }
    }

    @Test func approvalDismissesTheSheetAndConnects() async {
        let connector = RecordingConnector()
        let sheet = ApprovalSheet()
        connector.beforeCompleting = { await sheet.waitUntilOpened() }
        let model = model(connector)
        var form = ConnectForm(address: "factory.example")
        form.headers = [ConnectForm.HeaderRow(name: "X-Proxy-Token", value: "p")]

        let connected = await model.connect(form, webAuthenticator: sheet)

        #expect(connected)
        #expect(connector.browserCalls == [ConnectCall(url: "https://factory.example", auth: .browser, headers: [CustomHeader(name: "X-Proxy-Token", value: "p")])])
        #expect(sheet.opened == [URL(string: "https://factory.example/cli-auth/ch-1")!])
        #expect(sheet.dismissed)
        #expect(model.factory?.id == "f-browser")
        #expect(model.browserSignIn == nil)
        #expect(model.snapshot?.company.name == "Atlas")
    }

    @Test func waitingShowsTheApprovalLink() async {
        let connector = RecordingConnector()
        connector.browserOutcome = .waitUntilCancelled
        let model = model(connector)
        let connecting = Task { await model.connect(ConnectForm(address: "factory.example")) }

        await waitUntilWaiting(model)

        #expect(model.browserSignIn?.approvalURL == URL(string: "https://factory.example/cli-auth/ch-1"))
        model.cancelBrowserSignIn()
        await connecting.value
    }

    @Test func cancellingBrowserSignInStopsWaiting() async {
        let connector = RecordingConnector()
        connector.browserOutcome = .waitUntilCancelled
        let model = model(connector)
        let connecting = Task { await model.connect(ConnectForm(address: "factory.example")) }
        await waitUntilWaiting(model)

        model.cancelBrowserSignIn()
        await connecting.value

        #expect(connector.cancelledWaits == 1)
        #expect(model.browserSignIn == nil)
        #expect(model.connectError == nil)
        #expect(model.isOnboarding)
    }

    @Test func closingTheSheetCancelsTheSignIn() async {
        let connector = RecordingConnector()
        connector.browserOutcome = .waitUntilCancelled
        let model = model(connector)

        let connected = await model.connect(ConnectForm(address: "factory.example"), webAuthenticator: ApprovalSheet(.closedByUser))

        #expect(!connected)
        #expect(connector.cancelledWaits == 1)
        #expect(model.browserSignIn == nil)
        #expect(model.connectError == nil)
    }

    @Test func expiryDismissesTheSheetAndShowsTheMessage() async {
        let connector = RecordingConnector()
        let sheet = ApprovalSheet()
        connector.beforeCompleting = { await sheet.waitUntilOpened() }
        connector.browserOutcome = .fail(.signInExpired)
        let model = model(connector)

        await model.connect(ConnectForm(address: "factory.example"), webAuthenticator: sheet)

        #expect(sheet.dismissed)
        #expect(model.browserSignIn?.failure?.contains("expired") == true)
    }

    @Test(arguments: [(PaperclipError.signInExpired, "expired"), (.signInCancelled, "cancelled")])
    func expiredOrDeclinedSignInShowsItsMessage(error: PaperclipError, word: String) async {
        let connector = RecordingConnector()
        connector.browserOutcome = .fail(error)
        let model = model(connector)

        await model.connect(ConnectForm(address: "factory.example"))

        #expect(model.browserSignIn?.failure?.contains(word) == true)
        #expect(model.isOnboarding)
    }

    @Test func tryAgainRestartsTheSignIn() async {
        let connector = RecordingConnector()
        connector.browserOutcome = .fail(.signInExpired)
        let model = model(connector)
        await model.connect(ConnectForm(address: "factory.example"))
        connector.browserOutcome = .approve

        await model.retryBrowserSignIn()

        #expect(connector.browserCalls.count == 2)
        #expect(model.factory?.id == "f-browser")
        #expect(model.browserSignIn == nil)
    }

    @Test func insecureAddressIsRefusedBeforeWaiting() async {
        let model = model(RecordingConnector(error: PaperclipError.insecureConnection))
        let sheet = ApprovalSheet()

        await model.connect(ConnectForm(address: "http://paperclip.example.com"), webAuthenticator: sheet)

        #expect(sheet.opened.isEmpty)
        #expect(model.browserSignIn?.failure == PaperclipError.insecureConnection.localizedDescription)
    }

    // MARK: - Sign in again

    private func rejectedModel() async -> (AppModel, RecordingConnector, RejectingService) {
        let connector = RecordingConnector()
        let rejecting = RejectingService()
        return await (relaunched(connector, service: rejecting), connector, rejecting)
    }

    @Test func rejectedKeyAsksToSignInAgainWithoutRepeatingErrors() async {
        let (model, _, rejecting) = await rejectedModel()

        #expect(model.needsSignIn)
        #expect(model.signedOutReason == .boardKeyRejected)
        #expect(model.connectionProblem?.issue == .signedOut)
        #expect(model.actionError == nil)
        let callsAfterRejection = rejecting.calls.withLock { $0 }
        await model.refresh()
        #expect(rejecting.calls.withLock { $0 } == callsAfterRejection)
    }

    @Test func expiredKeyOnCompanySwitchSkipsTheProjectsReload() async throws {
        let service = ExpiresOnSwitchService()
        let model = await relaunched(RecordingConnector(), service: service)
        let callsBefore = service.projectCalls.withLock { $0 }

        try await model.select(#require(model.companies.first { $0.id == "orbit" }))

        #expect(model.needsSignIn)
        #expect(service.projectCalls.withLock { $0 } == callsBefore)
        #expect(model.projectsFailure == nil)
    }

    @Test func rejectedTokenWithoutABoardKeyIsAnError() async {
        let rejecting = RejectingService()

        let model = await relaunched(RecordingConnector(), service: rejecting, usesBoardKey: false)

        #expect(!model.needsSignIn)
        #expect(model.connectionProblem != nil)
    }

    @Test func signingInAgainKeepsTheFactory() async {
        let (model, connector, _) = await rejectedModel()
        let factory = model.factory
        let sheet = ApprovalSheet()
        connector.beforeCompleting = { await sheet.waitUntilOpened() }

        await model.signInAgain(webAuthenticator: sheet)

        #expect(connector.reauthenticated == [factory?.id])
        #expect(model.factory == factory)
        #expect(!model.needsSignIn)
        #expect(sheet.opened.count == 1)
        #expect(sheet.dismissed)
        #expect(model.snapshot?.company.name == "Atlas")
    }

    @Test func expiringKeyOffersSignInAgain() async {
        let soon = Date.now + 2 * 86400

        let model = await relaunched(RecordingConnector(), service: ExpiringService(expiry: soon))

        #expect(model.keyExpiry == soon)
    }

    @Test func distantExpiryIsNotShown() async {
        let model = await relaunched(RecordingConnector(), service: ExpiringService(expiry: .now + 20 * 86400))

        #expect(model.keyExpiry == nil)
    }

    @Test func demoNeverAsksToSignInAgain() async {
        let model = AppModel(connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: RejectingService()), defaults: UserDefaults(suiteName: UUID().uuidString)!)

        await model.refresh()

        #expect(!model.needsSignIn)
        #expect(model.connectionProblem != nil)
    }

    // MARK: - Re-entering lost header values

    @Test func missingHeaderValuesOpenTheConnectFormForThatFactory() async {
        let connector = RecordingConnector()
        await model(connector).connect(ConnectForm(address: "factory.example", method: .paperclip, apiKey: "k"))
        let factory = connector.saved.values.first!.factory
        connector.restoreError = ReconnectNeeded(factory: factory, headerNames: ["X-Proxy-Token"], reason: "values are gone")

        let relaunched = model(connector)

        #expect(relaunched.isOnboarding)
        #expect(relaunched.reconnect?.factory == factory)
        let form = ConnectForm(reconnecting: relaunched.reconnect!)
        #expect(form.address == "https://factory.example")
        #expect(form.headers.map(\.name) == ["X-Proxy-Token"])
        #expect(form.headers.map(\.value) == [""])
    }

    @Test func connectingAgainClearsTheReconnectNotice() async {
        let connector = RecordingConnector()
        await model(connector).connect(ConnectForm(address: "factory.example", method: .paperclip, apiKey: "k"))
        let factory = connector.saved.values.first!.factory
        connector.restoreError = ReconnectNeeded(factory: factory, headerNames: ["X-Proxy-Token"], reason: "values are gone")
        let relaunched = model(connector)
        connector.restoreError = nil

        await relaunched.connect(ConnectForm(address: "factory.example"))

        #expect(relaunched.reconnect == nil)
        #expect(!relaunched.isOnboarding)
    }

    // MARK: - Release fixes

    private func waitUntilCancelledOnServer(_ connector: RecordingConnector) async {
        while connector.cancelledChallenges.isEmpty {
            await Task.yield()
        }
    }

    @Test func cancelTellsTheServer() async {
        let connector = RecordingConnector()
        connector.browserOutcome = .waitUntilCancelled
        let model = model(connector)
        let connecting = Task { await model.connect(ConnectForm(address: "factory.example")) }
        await waitUntilWaiting(model)

        model.cancelBrowserSignIn()
        await connecting.value
        await waitUntilCancelledOnServer(connector)

        #expect(connector.cancelledChallenges == ["ch-1"])
    }

    @Test func closingTheSheetTellsTheServer() async {
        let connector = RecordingConnector()
        connector.browserOutcome = .waitUntilCancelled
        let model = model(connector)

        await model.connect(ConnectForm(address: "factory.example"), webAuthenticator: ApprovalSheet(.closedByUser))
        await waitUntilCancelledOnServer(connector)

        #expect(connector.cancelledChallenges == ["ch-1"])
    }

    @Test func secondSignInAgainWhileOneRunsDoesNothing() async {
        let (model, connector, _) = await rejectedModel()
        connector.browserOutcome = .waitUntilCancelled
        let first = Task { await model.signInAgain(webAuthenticator: nil) }
        await waitUntilWaiting(model)

        await model.signInAgain(webAuthenticator: nil)
        model.cancelBrowserSignIn()
        await first.value

        #expect(connector.reauthenticated.count == 1)
        #expect(connector.cancelledWaits == 1)
    }

    @Test func leavingForTheDemoCancelsTheSignIn() async {
        let connector = RecordingConnector()
        connector.browserOutcome = .waitUntilCancelled
        let model = model(connector)
        let connecting = Task { await model.connect(ConnectForm(address: "factory.example")) }
        await waitUntilWaiting(model)

        await model.exploreDemo()
        await connecting.value

        #expect(connector.cancelledWaits == 1)
        #expect(model.browserSignIn == nil)
        #expect(model.factory?.id == FactoryConnection.demo().factory.id)
    }

    @Test func cancelWinsOverAnApprovalThatLandsAtTheSameTime() async {
        let connector = RecordingConnector()
        let model = model(connector)
        connector.beforeCompleting = { await MainActor.run { model.cancelBrowserSignIn() } }

        let connected = await model.connect(ConnectForm(address: "factory.example"))

        #expect(!connected)
        #expect(model.isOnboarding)
        #expect(model.browserSignIn == nil)
    }

    @Test func decisionsStayStagedWhileSignedOutAndGoOutAfterSigningInAgain() async throws {
        let connector = RecordingConnector()
        let renewed = RecordingDecisions()
        connector.renewedService = renewed
        let model = await relaunched(connector, service: RejectingDecisions())
        let approval = try #require(model.waitingApprovals.first)

        model.decide(approval, approve: true)
        await model.commitStagedDecisions()

        #expect(model.needsSignIn)
        #expect(model.decisionErrors.isEmpty)
        #expect(model.decidedApprovals.map(\.id) == [approval.id])

        await model.signInAgain(webAuthenticator: nil)

        #expect(renewed.decided.withLock { $0 } == [approval.id])
    }

    // MARK: - Follow-ups

    @Test func publicSignInAgainUsesTheAuthenticatorTheViewsProvide() async {
        let (model, connector, _) = await rejectedModel()
        let sheet = ApprovalSheet()
        connector.beforeCompleting = { await sheet.waitUntilOpened() }
        model.webAuthenticator = sheet

        await model.signInAgain()

        #expect(connector.reauthenticators == 1)
        #expect(sheet.opened.count == 1)
        #expect(!model.needsSignIn)
    }

    @Test func oidcOnlyFactorySignsInAgainThroughTheIdentityProvider() async {
        let connector = RecordingConnector()
        let model = await relaunched(connector, service: ProxySignedOut(), usesBoardKey: false, usesOIDC: true)
        #expect(model.needsSignIn)
        model.webAuthenticator = ApprovalSheet()

        await model.signInAgain()

        #expect(connector.identityProviderSignIns == [model.factory?.id])
        #expect(connector.reauthenticated.isEmpty)
        #expect(!model.needsSignIn)
        #expect(model.snapshot?.company.name == "Atlas")
    }

    @Test func failedIdentityProviderSignInShowsWhyAndCanBeRetried() async {
        let connector = RecordingConnector()
        connector.identityProviderError = OIDCError.provider(code: "access_denied", description: "User said no")
        let model = await relaunched(connector, service: ProxySignedOut(), usesBoardKey: false, usesOIDC: true)
        model.webAuthenticator = ApprovalSheet()

        await model.signInAgain()

        #expect(model.browserSignIn?.failure == "User said no")
        #expect(model.needsSignIn)
        connector.identityProviderError = nil
        await model.retryBrowserSignIn()
        #expect(connector.identityProviderSignIns.count == 2)
        #expect(!model.needsSignIn)
        #expect(model.browserSignIn == nil)
    }

    @Test func signedOutTextNamesWhatEnded() {
        #expect(SignedOutReason.boardKeyRejected.message(for: "Atlas") == "Atlas no longer accepts Fabrix's key.")
        #expect(SignedOutReason.identityProviderSessionEnded.message(for: "Atlas") == "Your single sign-on session for Atlas ended.")
    }

    @Test func cancelBeatsALateIdentityProviderFailure() async {
        let connector = RecordingConnector()
        connector.identityProviderError = OIDCError.provider(code: "access_denied", description: "User said no")
        let model = await relaunched(connector, service: ProxySignedOut(), usesBoardKey: false, usesOIDC: true)
        model.webAuthenticator = ApprovalSheet()
        connector.beforeIdentityProvider = { await MainActor.run { model.cancelBrowserSignIn() } }

        await model.signInAgain()

        #expect(model.browserSignIn == nil)
        #expect(model.needsSignIn)
    }

    @Test func expiredProxySessionOnABoardKeyFactoryAsksToSignInAgain() async {
        let model = await relaunched(RecordingConnector(), service: ProxySignedOut(), usesBoardKey: true, usesOIDC: true)

        #expect(model.needsSignIn)
        #expect(model.signedOutReason == .identityProviderSessionEnded)
        #expect(model.connectionProblem?.issue == .signedOut)
    }

    @Test(arguments: [(true, ConnectForm.Method.oidcWithBrowser), (false, .oidc)])
    func reconnectFormKeepsTheSingleSignOnSettings(usesBoardKey: Bool, method: ConnectForm.Method) {
        let oidc = OIDCSettings(issuer: URL(string: "https://auth.example")!, clientID: "fabrix", redirectURI: StoreConnector.redirectURI)
        let request = ReconnectNeeded(
            factory: Factory(id: "f", name: "F", baseURL: URL(string: "https://f.example")!, isOnline: true),
            headerNames: ["X-Proxy-Token"], reason: "gone", auth: FactoryAuthConfiguration(oidc: oidc, usesBoardKey: usesBoardKey)
        )

        let form = ConnectForm(reconnecting: request)

        #expect(form.method == method)
        #expect(form.issuer == "https://auth.example")
        #expect(form.clientID == "fabrix")
        #expect(form.headers.map(\.name) == ["X-Proxy-Token"])
    }
}

/// Loads nothing because the proxy session in front of Paperclip ended.
private struct ProxySignedOut: FactoryService {
    func companies() async throws -> [Company] { throw PaperclipError.signInRequired("Session expired") }
    func snapshot(companyID _: Company.ID) async throws -> CompanySnapshot { throw PaperclipError.signInRequired(nil) }
    func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
}

/// Loads like the demo but rejects decisions, as a factory does once the key is revoked.
private struct RejectingDecisions: FactoryService {
    let base = DemoFactoryService()

    func companies() async throws -> [Company] { try await base.companies() }
    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot { try await base.snapshot(companyID: companyID) }
    func decide(approvalID _: Approval.ID, approve _: Bool) async throws { throw PaperclipError.unauthorized(nil) }
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
}

private final class RecordingDecisions: FactoryService {
    let base = DemoFactoryService()
    let decided = Mutex<[Approval.ID]>([])

    func companies() async throws -> [Company] { try await base.companies() }
    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot { try await base.snapshot(companyID: companyID) }
    func decide(approvalID: Approval.ID, approve: Bool) async throws {
        decided.withLock { $0.append(approvalID) }
        try await base.decide(approvalID: approvalID, approve: approve)
    }
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
}
