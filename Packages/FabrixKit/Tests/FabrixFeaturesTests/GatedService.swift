import FabrixCore
import Foundation

/// Wraps a service and can hold the next snapshot response, so tests can make
/// responses arrive out of order. The held response is read before holding, so it is stale.
/// Like URLSession, every call throws when its task is cancelled.
actor GatedService: FactoryService {
    private let inner: any FactoryService
    private var holdNext = false
    private var held: CheckedContinuation<Void, Never>?
    private var heldWaiters: [CheckedContinuation<Void, Never>] = []
    private let failingDecisions: Set<Approval.ID>
    private var failingSnapshots = false
    private var failingPauses = false
    private var companiesError: (any Error)?
    private var removedCompanies: Set<Company.ID> = []
    private(set) var snapshotCalls = 0
    private(set) var companiesCalls = 0

    init(_ inner: any FactoryService = DemoFactoryService(), failingDecisions: Set<Approval.ID> = []) {
        self.inner = inner
        self.failingDecisions = failingDecisions
    }

    func holdNextSnapshot() { holdNext = true }
    func failSnapshots(_ failing: Bool) { failingSnapshots = failing }
    func failPauses(_ failing: Bool) { failingPauses = failing }
    func failCompanies(with error: (any Error)?) { companiesError = error }
    /// Like deleting a company on the board: it leaves the list, and its snapshot answers 403.
    func removeCompany(_ id: Company.ID) { removedCompanies.insert(id) }

    /// Returns once a snapshot response is being held.
    func waitUntilHolding() async {
        if held != nil { return }
        await withCheckedContinuation { heldWaiters.append($0) }
    }

    func release() {
        held?.resume()
        held = nil
    }

    func companies() async throws -> [Company] {
        try Task.checkCancellation()
        companiesCalls += 1
        if let companiesError { throw companiesError }
        return try await inner.companies().filter { !removedCompanies.contains($0.id) }
    }

    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot {
        try Task.checkCancellation()
        snapshotCalls += 1
        if removedCompanies.contains(companyID) {
            throw PaperclipError.forbidden("User does not have access to this company")
        }
        if failingSnapshots { throw URLError(.notConnectedToInternet) }
        let snapshot = try await inner.snapshot(companyID: companyID)
        if holdNext {
            holdNext = false
            await withCheckedContinuation { continuation in
                held = continuation
                heldWaiters.forEach { $0.resume() }
                heldWaiters = []
            }
        }
        return snapshot
    }

    func decide(approvalID: Approval.ID, approve: Bool) async throws {
        try Task.checkCancellation()
        if failingDecisions.contains(approvalID) { throw URLError(.badServerResponse) }
        try await inner.decide(approvalID: approvalID, approve: approve)
    }

    func wake(agentID: Agent.ID) async throws {
        try Task.checkCancellation()
        try await inner.wake(agentID: agentID)
    }

    func pause(agentID: Agent.ID) async throws {
        try Task.checkCancellation()
        if failingPauses { throw PaperclipError.conflict("Agent is not invokable in its current state") }
        try await inner.pause(agentID: agentID)
    }
    func setCompanyPaused(_ paused: Bool, companyID: Company.ID) async throws {
        try await inner.setCompanyPaused(paused, companyID: companyID)
    }
}

/// A one-company factory whose company is not the demo's, to tell factories apart.
struct OtherFactory: FactoryService {
    let base = DemoFactoryService()

    func companies() async throws -> [Company] { [Company(id: "orbit", name: "Orbit")] }

    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot {
        guard companyID == "orbit" else { throw URLError(.fileDoesNotExist) }
        var snapshot = try await base.snapshot(companyID: "atlas")
        snapshot.company = Company(id: "orbit", name: "Orbit")
        return snapshot
    }

    func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
}

/// Two companies, to switch between.
struct TwoCompanyFactory: FactoryService {
    let atlas = DemoFactoryService()
    let orbit = OtherFactory()

    func companies() async throws -> [Company] {
        try await atlas.companies() + orbit.companies()
    }

    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot {
        companyID == "orbit" ? try await orbit.snapshot(companyID: companyID) : try await atlas.snapshot(companyID: companyID)
    }

    func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
    func wake(agentID _: Agent.ID) async throws {}
    func pause(agentID _: Agent.ID) async throws {}
    func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
}
