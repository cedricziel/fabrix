import AuthenticationServices
import FabrixCore
import Foundation
import Observation

/// A browser sign-in in progress, or how the last one ended.
public struct BrowserSignInState: Equatable, Sendable {
    /// The page where the user approves Fabrix; nil when the request couldn't be created.
    public var approvalURL: URL?
    public var expiresAt: Date?
    /// Why the sign-in ended without a connection.
    public var failure: String?

}

public enum LoadState: Equatable, Sendable {
    case loading, loaded, empty
    case failed(String)
}

@MainActor
@Observable
public final class AppModel {
    public private(set) var factory: Factory?
    public private(set) var companies: [Company] = []
    public private(set) var snapshot: CompanySnapshot? {
        didSet {
            if snapshot != oldValue {
                index = SnapshotIndex(snapshot)
            }
        }
    }

    public private(set) var loadState: LoadState = .loading
    public private(set) var lastError: String?
    public private(set) var connectError: String?
    public private(set) var isConnecting = false
    public private(set) var browserSignIn: BrowserSignInState?
    /// The factory from the last launch couldn't reopen; onboarding asks for what is missing.
    public private(set) var reconnect: ReconnectNeeded?
    /// The factory rejected its board key; refreshing waits until the user signs in again.
    public private(set) var needsSignIn = false
    /// When the board key expires, set only once that is close.
    public private(set) var keyExpiry: Date?
    /// Successful connections to real factories this session; the demo and restores don't count.
    public private(set) var connectCount = 0
    public var searchText = ""

    private var service: (any FactoryService)?
    private var generation = 0
    private let clock = ContinuousClock()
    private var lastRefresh: ContinuousClock.Instant?
    /// The company the user chose; requests for any other company are stale.
    private var selectedCompanyID: Company.ID?
    private var requestCount = 0
    private var appliedRequest = 0
    private let connector: (any FactoryConnector)?
    private let defaults: UserDefaults
    private let undoWindow: Duration
    private var usesBoardKey = false
    private var usesOIDC = false
    private var signInTask: Task<FactoryConnection, any Error>?
    /// Bumped by every start and cancel, so a run that was overtaken never connects.
    private var signInRun = 0
    /// The request the app is waiting on; cancelled on the server when the user backs out.
    private var pendingChallenge: SignInChallenge?
    private var retrySignIn: (@MainActor () async -> Void)?
    private var checkedKeyExpiry = false
    private static let expiryWarning: TimeInterval = 5 * 24 * 60 * 60
    private var index = SnapshotIndex(nil)
    private var desk = ApprovalDesk()
    /// Why a decision didn't reach the factory, shown on its approval until decided again.
    private(set) var decisionErrors: [Approval.ID: String] = [:]
    private var commitTimers: [Approval.ID: Task<Void, Never>] = [:]

    private static let demoKey = "fabrix.exploringDemo"
    private static let factoryKey = "fabrix.currentFactoryID"

    /// - Parameters:
    ///   - connection: a factory restored from a previous launch; skips onboarding.
    ///   - connector: enables "Connect a factory" during onboarding.
    public init(
        connection: FactoryConnection? = nil,
        connector: (any FactoryConnector)? = nil,
        defaults: UserDefaults = .standard,
        undoWindow: Duration = .seconds(8)
    ) {
        self.connector = connector
        self.defaults = defaults
        self.undoWindow = undoWindow
        if let connection = connection ?? restoredConnection() {
            use(connection)
        }
    }

    public static func demo() -> AppModel {
        AppModel(connection: .demo(), defaults: UserDefaults(suiteName: "fabrix.preview") ?? .standard)
    }

    // MARK: Onboarding

    public var isOnboarding: Bool {
        service == nil
    }

    public var canConnect: Bool {
        connector != nil
    }

    /// The demo, or the factory connected at the last launch.
    private func restoredConnection() -> FactoryConnection? {
        if defaults.bool(forKey: Self.demoKey) { return .demo() }
        guard let id = defaults.string(forKey: Self.factoryKey) else { return nil }
        do {
            return try connector?.restore(factoryID: id)
        } catch let request as ReconnectNeeded {
            reconnect = request
        } catch {}
        return nil
    }

    public func exploreDemo() async {
        await commitStagedDecisions()
        defaults.set(true, forKey: Self.demoKey)
        defaults.removeObject(forKey: Self.factoryKey)
        use(.demo())
        await refresh()
    }

    /// - Parameter webAuthenticator: Shows the identity provider's login page, and Paperclip's approval page for browser sign-in.
    /// - Returns: Whether the factory is now open.
    @discardableResult
    func connect(_ form: ConnectForm, webAuthenticator: (any WebAuthenticator)? = nil) async -> Bool {
        guard let connector, !isConnecting else { return false }
        let request: (baseURL: URL, auth: FactoryAuth, headers: [CustomHeader])
        do {
            request = try form.validated()
        } catch {
            connectError = error.message
            return false
        }
        if request.auth.usesBrowserSignIn {
            return await runBrowserSignIn(webAuthenticator: webAuthenticator) {
                try await connector.startBrowserSignIn(
                    baseURL: request.baseURL, auth: request.auth, headers: request.headers, webAuthenticator: webAuthenticator
                )
            }
        }
        isConnecting = true
        defer { isConnecting = false }
        do {
            let connection = try await connector.connect(
                baseURL: request.baseURL, auth: request.auth, headers: request.headers, webAuthenticator: webAuthenticator
            )
            await finishConnecting(connection)
            return true
        } catch {
            // Closing the sign-in sheet is a choice, not a failure.
            connectError = Self.isCancellation(error) ? nil : error.localizedDescription
            return false
        }
    }

    var storeRevision: Int {
        connector?.revision ?? 0
    }

    var factoryMenu: FactoryMenu {
        FactoryMenu(saved: connector?.factories ?? [], open: factory, companies: companies, selectedCompanyID: snapshot?.company.id)
    }

    private func finishConnecting(_ connection: FactoryConnection) async {
        reconnect = nil
        connectCount += 1
        if connection.factory.id == factory?.id {
            // Signed in again: same factory, new key. Decisions held while signed out go out now.
            renew(connection)
            await commitStagedDecisions()
            await refresh()
            return
        }
        // Only now is the open factory being left; a cancelled or failed sign-in keeps the undo window.
        await commitStagedDecisions()
        use(connection)
        defaults.set(connection.factory.id, forKey: Self.factoryKey)
        defaults.removeObject(forKey: Self.demoKey)
        connectError = nil
        await refresh()
    }

    // MARK: Browser sign-in

    /// Only a saved factory that uses a Paperclip key can get a new one through the browser.
    public var canSignInAgain: Bool {
        canForgetFactory && (usesBoardKey || usesOIDC)
    }

    /// Shows the identity provider's and Paperclip's pages for "Sign in again". The views set it
    /// from their web authentication session, so callers of `signInAgain()` need nothing from the view.
    public var webAuthenticator: (any WebAuthenticator)?

    /// Signs in to the open factory again with whatever its saved sign-in needs, keeping its ID,
    /// headers and settings. For a connection-health state or a banner to call.
    public func signInAgain() async {
        await signInAgain(webAuthenticator: webAuthenticator)
    }

    func signInAgain(webAuthenticator: (any WebAuthenticator)?) async {
        guard canSignInAgain, !isConnecting, let connector, let factory else { return }
        if usesBoardKey {
            // Browser approval for a new key; an OIDC front door is logged in to again on the way.
            await runBrowserSignIn(webAuthenticator: webAuthenticator) {
                try await connector.startReauthentication(factoryID: factory.id, webAuthenticator: webAuthenticator)
            }
            return
        }
        guard let webAuthenticator else { return }
        isConnecting = true
        defer { isConnecting = false }
        do {
            await finishConnecting(try await connector.signInAgainToIdentityProvider(factoryID: factory.id, webAuthenticator: webAuthenticator))
        } catch where !Self.isCancellation(error) {
            lastError = error.localizedDescription
        } catch {}
    }

    func retryBrowserSignIn() async {
        await retrySignIn?()
    }

    /// Stops waiting for approval, or dismisses a failed sign-in. A pending request is also
    /// cancelled on the server, so a later approval can't activate its key.
    func cancelBrowserSignIn() {
        signInRun += 1
        signInTask?.cancel()
        signInTask = nil
        retrySignIn = nil
        browserSignIn = nil
        if let challenge = pendingChallenge, let connector {
            pendingChallenge = nil
            Task { try? await connector.cancelBrowserSignIn(challenge) }
        }
    }

    /// - Returns: Whether the factory is now open.
    @discardableResult
    private func runBrowserSignIn(
        webAuthenticator: (any WebAuthenticator)?, start: @escaping @MainActor () async throws -> SignInChallenge
    ) async -> Bool {
        guard let connector else { return false }
        signInTask?.cancel()
        signInRun += 1
        let run = signInRun
        retrySignIn = { [weak self] in await self?.runBrowserSignIn(webAuthenticator: webAuthenticator, start: start) }
        connectError = nil
        isConnecting = true
        defer { isConnecting = false }
        do {
            let challenge = try await start()
            guard run == signInRun else {
                // Cancelled while the request was being created.
                Task { try? await connector.cancelBrowserSignIn(challenge) }
                return false
            }
            pendingChallenge = challenge
            browserSignIn = BrowserSignInState(approvalURL: challenge.approvalURL, expiresAt: challenge.expiresAt)
            let task = Task { try await Self.awaitApproval(of: challenge, connector: connector, sheet: webAuthenticator) }
            signInTask = task
            let connection = try await withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }
            // An approval that lands as the user cancels must not open the factory anyway.
            guard run == signInRun else { return false }
            pendingChallenge = nil
            signInTask = nil
            retrySignIn = nil
            browserSignIn = nil
            await finishConnecting(connection)
            return true
        } catch {
            guard run == signInRun else { return false }
            if Self.isCancellation(error) {
                // Closing the approval sheet is the same as Cancel.
                cancelBrowserSignIn()
            } else {
                pendingChallenge = nil
                browserSignIn = BrowserSignInState(failure: Self.signInFailure(error))
            }
            return false
        }
    }

    private enum ApprovalEvent {
        case connected(FactoryConnection)
        case sheetClosed
        case sheetFailed
    }

    /// Shows the approval page in a web authentication session while polling the request. The page
    /// never redirects back, so polling decides: approval, expiry or decline dismisses the sheet,
    /// and the user closing the sheet cancels the sign-in. Without a sheet, polling alone runs
    /// and the user opens the copied link.
    private static func awaitApproval(
        of challenge: SignInChallenge, connector: any FactoryConnector, sheet: (any WebAuthenticator)?
    ) async throws -> FactoryConnection {
        try await withThrowingTaskGroup(of: ApprovalEvent.self) { group in
            group.addTask { try await .connected(connector.completeBrowserSignIn(challenge)) }
            if let sheet {
                group.addTask {
                    do {
                        _ = try await sheet.authenticate(url: challenge.approvalURL, callbackScheme: StoreConnector.callbackScheme)
                        return .sheetFailed
                    } catch {
                        return isCancellation(error) ? .sheetClosed : .sheetFailed
                    }
                }
            }
            for try await event in group {
                switch event {
                case let .connected(connection):
                    group.cancelAll()
                    return connection
                case .sheetClosed:
                    group.cancelAll()
                    throw CancellationError()
                case .sheetFailed:
                    // Polling continues; the copied link still works in any browser.
                    continue
                }
            }
            throw CancellationError()
        }
    }

    private static func signInFailure(_ error: any Error) -> String {
        switch error as? PaperclipError {
        case .signInExpired: "The sign-in request expired before it was approved."
        case .signInCancelled: "The sign-in request was cancelled in the browser."
        default: error.localizedDescription
        }
    }

    /// Shows a failed request. A rejected key asks for sign-in instead of failing every refresh.
    /// A rejected board key, or an identity-provider session that ended; "Sign in again" fixes both.
    private func isSignedOut(_ error: any Error) -> Bool {
        switch error as? PaperclipError {
        case .unauthorized: canForgetFactory && usesBoardKey
        case .signInRequired: canForgetFactory && usesOIDC
        default: false
        }
    }

    private func report(_ error: any Error) {
        if isSignedOut(error) {
            needsSignIn = true
            lastError = nil
        } else {
            lastError = error.localizedDescription
        }
    }

    private func checkKeyExpiry(_ service: any FactoryService) async {
        guard canForgetFactory, usesBoardKey, !checkedKeyExpiry else { return }
        checkedKeyExpiry = true
        let session = generation
        guard let expiry = try? await service.credentialExpiry(), session == generation else { return }
        keyExpiry = expiry.timeIntervalSinceNow < Self.expiryWarning ? expiry : nil
    }

    /// A real factory can be forgotten; the demo has nothing saved.
    public var canForgetFactory: Bool {
        connector != nil && factory != nil && factory?.id != FactoryConnection.demo().factory.id
    }

    /// Opens a saved factory or the demo, and remembers it for the next launch.
    func open(_ target: Factory) async {
        guard target.id != factory?.id else { return }
        await commitStagedDecisions()
        if target.id == FactoryConnection.demo().factory.id {
            await exploreDemo()
            return
        }
        let restored: FactoryConnection?
        do {
            restored = try connector?.restore(factoryID: target.id)
        } catch let request as ReconnectNeeded {
            // Its header values are gone; onboarding asks for them with the address filled in.
            disconnect()
            reconnect = request
            return
        } catch {
            restored = nil
        }
        guard let connection = restored else {
            lastError = String(localized: "\(target.name) couldn't be opened. Remove it and add it again.")
            return
        }
        use(connection)
        defaults.set(connection.factory.id, forKey: Self.factoryKey)
        defaults.removeObject(forKey: Self.demoKey)
        await refresh()
    }

    /// Deletes the open factory and its credentials, then opens the next saved factory,
    /// or onboarding when none is left. The demo has nothing saved and can't be removed.
    func removeOpenFactory() async {
        guard factoryMenu.canRemove, let connector, let factory else { return }
        // Decisions already shown under Decided go out before the credentials disappear.
        await commitStagedDecisions()
        do {
            try connector.forget(factoryID: factory.id)
        } catch {
            lastError = error.localizedDescription
            return
        }
        await leaveForNextFactory()
    }

    /// Leaves the open factory when it was removed elsewhere, e.g. from another window.
    /// Follows changes another window made to the saved factories: leaves the open factory when
    /// it was removed, and picks up new credentials when it was connected again.
    func followStoreChanges() async {
        guard let connector, let factory, factory.id != FactoryConnection.demo().factory.id else { return }
        let current: FactoryConnection?
        do {
            current = try connector.restore(factoryID: factory.id)
        } catch {
            // Still saved, but its secrets can't be read here; keep the open connection.
            return
        }
        guard let current else {
            await leaveForNextFactory()
            return
        }
        self.factory = current.factory
        service = current.service
        await refresh()
    }

    private func leaveForNextFactory() async {
        disconnect()
        if let next = connector?.factories.first {
            await open(next)
        }
    }

    func clearConnectError() {
        connectError = nil
    }

    public func dismissError() {
        lastError = nil
    }

    /// Leaves the current factory. A connected factory stays saved, with its credentials,
    /// in the connector's store; it just isn't reopened on the next launch.
    public func disconnect() {
        cancelBrowserSignIn()
        defaults.removeObject(forKey: Self.demoKey)
        defaults.removeObject(forKey: Self.factoryKey)
        generation += 1
        commitTimers.values.forEach { $0.cancel() }
        commitTimers = [:]
        desk = ApprovalDesk()
        decisionErrors = [:]
        service = nil
        factory = nil
        companies = []
        snapshot = nil
        loadState = .loading
        lastError = nil
    }

    /// Staged decisions belong to the open factory. Callers send them before switching,
    /// and anything still staged is dropped here so it can never reach the next factory.
    /// Swaps in new credentials for the open factory without dropping what is on screen.
    private func renew(_ connection: FactoryConnection) {
        factory = connection.factory
        service = connection.service
        usesBoardKey = connection.usesBoardKey
        usesOIDC = connection.usesOIDC
        needsSignIn = false
        keyExpiry = nil
        checkedKeyExpiry = false
        lastError = nil
    }

    private func use(_ connection: FactoryConnection) {
        cancelBrowserSignIn()
        commitTimers.values.forEach { $0.cancel() }
        commitTimers = [:]
        desk = ApprovalDesk()
        decisionErrors = [:]
        generation += 1
        lastRefresh = nil
        selectedCompanyID = nil
        factory = connection.factory
        service = connection.service
        usesBoardKey = connection.usesBoardKey
        usesOIDC = connection.usesOIDC
        needsSignIn = false
        keyExpiry = nil
        checkedKeyExpiry = false
        companies = []
        snapshot = nil
        lastError = nil
        loadState = .loading
    }

    // MARK: Loading

    public func refresh() async {
        guard let service, !needsSignIn else { return }
        let request = beginRequest()
        let wanted = selectedCompanyID
        do {
            let (companies, current) = try await Self.load(from: service, current: wanted)
            let fresh: CompanySnapshot?
            if let selected = companies.first(where: { $0.id == wanted }) ?? companies.first {
                fresh = if let current, current.company.id == selected.id {
                    current
                } else {
                    try await service.snapshot(companyID: selected.id)
                }
            } else {
                fresh = nil
            }
            guard selectedCompanyID == wanted, accept(request) else { return }
            selectedCompanyID = fresh?.company.id
            if companies != self.companies {
                self.companies = companies
            }
            if fresh != snapshot {
                snapshot = fresh
            }
            desk.settle(with: fresh?.approvals ?? [])
            lastRefresh = clock.now
            lastError = nil
            loadState = fresh == nil ? .empty : .loaded
            await checkKeyExpiry(service)
        } catch {
            guard !Self.isCancellation(error), selectedCompanyID == wanted, accept(request) else { return }
            report(error)
            if snapshot == nil {
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    /// Loads the company list and, when a company is already shown, its snapshot in parallel.
    private static func load(
        from service: any FactoryService, current id: Company.ID?
    ) async throws -> ([Company], CompanySnapshot?) {
        guard let id else { return try (await service.companies(), nil) }
        async let companies = service.companies()
        async let snapshot = service.snapshot(companyID: id)
        return try await (companies, snapshot)
    }

    /// Refreshes on a fixed interval until cancelled. Loads right away when nothing is loaded
    /// yet or the data is older than `staleAfter` (e.g. on returning from the background).
    public func keepFresh(every interval: Duration = .seconds(20), staleAfter: Duration? = nil) async {
        let isStale = lastRefresh.map { $0.duration(to: clock.now) >= (staleAfter ?? interval) } ?? true
        if loadState != .loaded || isStale {
            await refresh()
        }
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    public func select(_ company: Company) async {
        guard let service, company.id != selectedCompanyID else { return }
        selectedCompanyID = company.id
        let request = beginRequest()
        do {
            let fresh = try await service.snapshot(companyID: company.id)
            guard selectedCompanyID == company.id, accept(request) else { return }
            snapshot = fresh
            lastError = nil
        } catch {
            guard !Self.isCancellation(error), selectedCompanyID == company.id, accept(request) else { return }
            selectedCompanyID = snapshot?.company.id
            report(error)
        }
    }

    /// A cancelled request (the scene went inactive, the view went away) is not a failure.
    private nonisolated static func isCancellation(_ error: any Error) -> Bool {
        error is CancellationError
            || (error as? URLError)?.code == .cancelled
            || error as? PaperclipError == .transport(.cancelled)
            || (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
            || Task.isCancelled
    }

    /// Responses arrive out of order: a slow poll can land after a newer refresh, or after
    /// the user switched factories. Only the newest response for the current factory counts.
    private struct Request {
        var generation: Int
        var number: Int
    }

    private func beginRequest() -> Request {
        requestCount += 1
        return Request(generation: generation, number: requestCount)
    }

    private func accept(_ request: Request) -> Bool {
        guard request.generation == generation, request.number > appliedRequest else { return false }
        appliedRequest = request.number
        return true
    }

    // MARK: Approvals

    var waitingApprovals: [Approval] {
        desk.waiting(snapshot?.approvals ?? [])
    }

    var decidedApprovals: [DecidedApproval] {
        desk.decided(snapshot?.approvals ?? [])
    }

    public var waitingCount: Int {
        waitingApprovals.count
    }

    /// Stages the decision; it reaches the factory after the undo window.
    func decide(_ approval: Approval, approve: Bool) {
        desk.stage(approval.id, approve: approve)
        decisionErrors[approval.id] = nil
        commitTimers[approval.id]?.cancel()
        commitTimers[approval.id] = Task { [undoWindow] in
            try? await Task.sleep(for: undoWindow)
            guard !Task.isCancelled else { return }
            // The timer is done; drop it so commit() doesn't cancel the task it runs in.
            self.commitTimers[approval.id] = nil
            await self.commit([approval.id])
        }
    }

    func undo(_ id: Approval.ID) {
        if desk.undo(id) {
            commitTimers.removeValue(forKey: id)?.cancel()
        }
    }

    /// Sends every staged decision now, e.g. when the app goes to the background.
    public func commitStagedDecisions() async {
        await commit(desk.stagedIDs)
    }

    private func commit(_ ids: [Approval.ID]) async {
        // Signed out, every decision would bounce; they stay staged until signing in again.
        guard let service, !needsSignIn else { return }
        let verdicts = ids.compactMap { id -> (Approval.ID, Bool)? in
            commitTimers.removeValue(forKey: id)?.cancel()
            return desk.beginCommit(id).map { (id, $0) }
        }
        guard !verdicts.isEmpty else { return }
        let session = generation
        let failures = await withTaskGroup(of: (Approval.ID, any Error)?.self) { group in
            for (id, approve) in verdicts {
                group.addTask {
                    do {
                        try await service.decide(approvalID: id, approve: approve)
                        return nil
                    } catch {
                        return (id, error)
                    }
                }
            }
            var failures: [Approval.ID: any Error] = [:]
            for await case let (id, error)? in group {
                failures[id] = error
            }
            return failures
        }
        guard session == generation else { return }
        let verdictByID = Dictionary(uniqueKeysWithValues: verdicts)
        var messages: [Approval.ID: String] = [:]
        for (id, error) in failures {
            if isSignedOut(error), let approve = verdictByID[id] {
                // The key was rejected, not the decision: keep it for after signing in again.
                desk.stage(id, approve: approve)
                needsSignIn = true
            } else {
                desk.finish(id)
                messages[id] = error.localizedDescription
            }
        }
        decisionErrors.merge(messages) { _, new in new }
        guard !needsSignIn else { return }
        await refresh()
        guard session == generation, let failure = messages.values.first else { return }
        lastError = failure
    }

    // MARK: Agents and company

    func wake(_ agent: Agent) async {
        await perform { try await $0.wake(agentID: agent.id) }
    }

    func pause(_ agent: Agent) async {
        await perform { try await $0.pause(agentID: agent.id) }
    }

    func setCompanyPaused(_ paused: Bool) async {
        guard let id = snapshot?.company.id else { return }
        await perform { try await $0.setCompanyPaused(paused, companyID: id) }
    }

    private func perform(_ action: (any FactoryService) async throws -> Void) async {
        guard let service else { return }
        do {
            try await action(service)
            await refresh()
        } catch {
            report(error)
        }
    }

    // MARK: Lookup and search

    func agent(_ id: Agent.ID?) -> Agent? {
        id.flatMap { index.agents[$0] }
    }

    func status(of agent: Agent) -> AgentStatus {
        .shown(reported: agent.status, hasLiveRun: runs(of: agent.id).contains(where: \.isLive))
    }

    func liveRun(for task: WorkItem) -> Run? {
        index.liveRunsByTask[task.identifier]
    }

    func runs(of agentID: Agent.ID) -> [Run] {
        index.runsByAgent[agentID] ?? []
    }

    var visibleTasks: [WorkItem] {
        let tasks = snapshot?.tasks ?? []
        guard let query = trimmedQuery else { return tasks }
        return tasks.filter { task in
            task.identifier.localizedStandardContains(query)
                || task.title.localizedStandardContains(query)
                || agent(task.assigneeID)?.name.localizedStandardContains(query) == true
        }
    }

    var visibleAgents: [Agent] {
        let agents = snapshot?.agents ?? []
        guard let query = trimmedQuery else { return agents }
        return agents.filter { $0.name.localizedStandardContains(query) }
    }

    private var trimmedQuery: String? {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return query.isEmpty ? nil : query
    }
}

/// Lookups rebuilt once per snapshot so rows don't scan arrays.
private struct SnapshotIndex {
    var agents: [Agent.ID: Agent] = [:]
    var liveRunsByTask: [String: Run] = [:]
    var runsByAgent: [Agent.ID: [Run]] = [:]

    init(_ snapshot: CompanySnapshot?) {
        guard let snapshot else { return }
        agents = Dictionary(snapshot.agents.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for run in snapshot.runs.sorted(by: { $0.startedAt > $1.startedAt }) {
            runsByAgent[run.agentID, default: []].append(run)
            if run.isLive, let task = run.taskIdentifier, liveRunsByTask[task] == nil {
                liveRunsByTask[task] = run
            }
        }
    }
}

extension ConnectForm.Problem {
    var message: String {
        switch self {
        case .address: String(localized: "Enter the factory address, like https://factory.example.com.")
        case .apiKey: String(localized: "Paste the Paperclip API key for this factory.")
        case .issuer: String(localized: "Enter the OIDC issuer URL.")
        case .clientID: String(localized: "Enter the OIDC client ID.")
        }
    }
}
