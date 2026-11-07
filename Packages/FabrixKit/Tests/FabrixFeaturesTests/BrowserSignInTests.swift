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
    private func relaunched(_ connector: RecordingConnector, service: any FactoryService, usesBoardKey: Bool = true) async -> AppModel {
        let first = model(connector)
        await first.connect(ConnectForm(address: "factory.example", method: .paperclip, apiKey: "old"))
        let factory = first.factory!
        connector.saved[factory.id] = FactoryConnection(factory: factory, service: service, usesBoardKey: usesBoardKey)
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
        #expect(model.lastError == nil)
        let callsAfterRejection = rejecting.calls.withLock { $0 }
        await model.refresh()
        #expect(rejecting.calls.withLock { $0 } == callsAfterRejection)
    }

    @Test func rejectedTokenWithoutABoardKeyIsAnError() async {
        let rejecting = RejectingService()

        let model = await relaunched(RecordingConnector(), service: rejecting, usesBoardKey: false)

        #expect(!model.needsSignIn)
        #expect(model.lastError != nil)
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
        #expect(model.lastError != nil)
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
}
