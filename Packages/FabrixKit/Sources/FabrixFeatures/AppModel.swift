import FabrixCore
import Observation

public enum LoadState: Equatable, Sendable {
    case loading, loaded, empty
    case failed(String)
}

@MainActor
@Observable
public final class AppModel {
    public private(set) var snapshot: CompanySnapshot?
    public private(set) var loadState: LoadState = .loading
    public private(set) var lastError: String?
    public let service: any FactoryService

    public init(service: any FactoryService = DemoFactoryService()) {
        self.service = service
    }

    public func refresh() async {
        do {
            guard let company = try await service.companies().first else {
                snapshot = nil
                lastError = nil
                loadState = .empty
                return
            }
            snapshot = try await service.snapshot(companyID: company.id)
            lastError = nil
            loadState = .loaded
        } catch {
            lastError = error.localizedDescription
            if snapshot == nil { loadState = .failed(error.localizedDescription) }
        }
    }

    public func decide(_ approval: Approval, approve: Bool) async {
        await perform { try await $0.decide(approvalID: approval.id, approve: approve) }
    }

    public func wake(_ agent: Agent) async {
        await perform { try await $0.wake(agentID: agent.id) }
    }

    public func pause(_ agent: Agent) async {
        await perform { try await $0.pause(agentID: agent.id) }
    }

    private func perform(_ action: (any FactoryService) async throws -> Void) async {
        do {
            try await action(service)
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }
}
