import FabrixCore
import Foundation
import Observation

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
    public var searchText = ""

    private var service: (any FactoryService)?
    private var generation = 0
    private var requestCount = 0
    private var appliedRequest = 0
    private let connector: (any FactoryConnector)?
    private let defaults: UserDefaults
    private var index = SnapshotIndex(nil)

    private static let demoKey = "fabrix.exploringDemo"

    /// - Parameters:
    ///   - connection: a factory restored from a previous launch; skips onboarding.
    ///   - connector: enables "Connect a factory" during onboarding.
    public init(
        connection: FactoryConnection? = nil,
        connector: (any FactoryConnector)? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.connector = connector
        self.defaults = defaults
        if let connection = connection ?? (defaults.bool(forKey: Self.demoKey) ? .demo() : nil) {
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

    public func exploreDemo() async {
        defaults.set(true, forKey: Self.demoKey)
        use(.demo())
        await refresh()
    }

    func connect(_ form: ConnectForm) async {
        guard let connector else { return }
        let request: (baseURL: URL, auth: FactoryAuth)
        do {
            request = try form.validated()
        } catch {
            connectError = error.message
            return
        }
        isConnecting = true
        defer { isConnecting = false }
        do {
            try use(await connector.connect(baseURL: request.baseURL, auth: request.auth))
            connectError = nil
            await refresh()
        } catch {
            connectError = error.localizedDescription
        }
    }

    public func disconnect() {
        defaults.removeObject(forKey: Self.demoKey)
        generation += 1
        service = nil
        factory = nil
        companies = []
        snapshot = nil
        loadState = .loading
        lastError = nil
    }

    private func use(_ connection: FactoryConnection) {
        generation += 1
        factory = connection.factory
        service = connection.service
        companies = []
        snapshot = nil
        lastError = nil
        loadState = .loading
    }

    // MARK: Loading

    public func refresh() async {
        guard let service else { return }
        let request = beginRequest()
        let shown = snapshot?.company.id
        do {
            let (companies, current) = try await Self.load(from: service, current: shown)
            let fresh: CompanySnapshot?
            if let selected = companies.first(where: { $0.id == shown }) ?? companies.first {
                fresh = if let current, current.company.id == selected.id {
                    current
                } else {
                    try await service.snapshot(companyID: selected.id)
                }
            } else {
                fresh = nil
            }
            guard accept(request) else { return }
            if companies != self.companies {
                self.companies = companies
            }
            if fresh != snapshot {
                snapshot = fresh
            }
            lastError = nil
            loadState = fresh == nil ? .empty : .loaded
        } catch {
            guard accept(request) else { return }
            lastError = error.localizedDescription
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

    /// Refreshes on a fixed interval until cancelled; the first call loads right away.
    public func keepFresh(every interval: Duration = .seconds(20)) async {
        if loadState == .loading {
            await refresh()
        }
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    public func select(_ company: Company) async {
        guard let service, company.id != snapshot?.company.id else { return }
        let request = beginRequest()
        do {
            let fresh = try await service.snapshot(companyID: company.id)
            guard accept(request) else { return }
            snapshot = fresh
        } catch {
            guard accept(request) else { return }
            lastError = error.localizedDescription
        }
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
            lastError = error.localizedDescription
        }
    }

    // MARK: Lookup and search

    func agent(_ id: Agent.ID?) -> Agent? {
        id.flatMap { index.agents[$0] }
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
