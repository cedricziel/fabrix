@testable import FabrixCore
import Foundation
import Testing

struct SandboxEnvironment {
    var url: URL
    var key: String
    var companyID: String

    static var current: SandboxEnvironment? {
        let env = ProcessInfo.processInfo.environment
        guard let url = env["FABRIX_SANDBOX_URL"].flatMap(URL.init(string:)),
              let key = env["FABRIX_SANDBOX_KEY"], let companyID = env["FABRIX_SANDBOX_COMPANY_ID"]
        else { return nil }
        return SandboxEnvironment(url: url, key: key, companyID: companyID)
    }
}

/// Runs against a real Paperclip seeded by `scripts/paperclip-sandbox-seed.sh`.
/// Skipped unless `FABRIX_SANDBOX_URL` is set; see the `validate` skill.
@MainActor
@Suite(.serialized, .enabled(if: SandboxEnvironment.current != nil, "Set FABRIX_SANDBOX_URL to run against a Paperclip sandbox"))
struct SandboxContractTests {
    private let sandbox = SandboxEnvironment.current!
    private let store = FactoryStore(defaults: UserDefaults(suiteName: "SandboxContractTests-\(UUID().uuidString)")!, credentials: InMemoryCredentialStore())

    @Test func rejectsUnknownBoardKey() async throws {
        await #expect {
            try await store.connect(url: sandbox.url, credential: "pcp_board_not_a_real_key")
        } throws: { error in
            if case .unauthorized = error as? PaperclipError {
                true
            } else {
                false
            }
        }
    }

    @Test func liveFactoryRoundTrip() async throws {
        let factory = try await store.connect(url: sandbox.url.appending(path: "api"), credential: sandbox.key, name: "Sandbox")
        let service = try store.service(for: factory)

        let companies = try await service.companies()
        #expect(companies.contains { $0.id == sandbox.companyID && $0.name == "Atlas Sandbox" })

        let snapshot = try await service.snapshot(companyID: sandbox.companyID)
        let cto = try #require(snapshot.agents.first { $0.name == "CTO" })
        let ops = try #require(snapshot.agents.first { $0.name == "DevOps" })
        #expect(cto.role == "Chief Technology Officer")
        #expect(ops.status == .paused)
        #expect(ops.reportsToID == cto.id)
        #expect(Set(snapshot.tasks.map(\.title)).isSuperset(of: ["Split sync worker into queue consumers", "Rotate staging certificates", "Evaluate push provider"]))
        #expect(snapshot.tasks.contains { $0.status == .blocked && $0.assigneeID == ops.id })
        #expect(snapshot.tasks.allSatisfy { $0.identifier.hasPrefix("ATL-") })
        #expect(Set(snapshot.pendingApprovals.map(\.kind)) == [.hire, .strategy])
        #expect(snapshot.pendingApprovals.contains { $0.title == "Hire Designer" && $0.requestedBy == "CTO" })

        let hire = try #require(snapshot.pendingApprovals.first { $0.kind == .hire })
        let strategy = try #require(snapshot.pendingApprovals.first { $0.kind == .strategy })
        try await service.decide(approvalID: hire.id, approve: true)
        try await service.decide(approvalID: strategy.id, approve: false)

        try await service.pause(agentID: cto.id)
        #expect(try await service.snapshot(companyID: sandbox.companyID).agents.first { $0.id == cto.id }?.status == .paused)

        try await service.wake(agentID: ops.id)
        let after = try await service.snapshot(companyID: sandbox.companyID)
        #expect(after.agents.first { $0.id == ops.id }?.status != .paused)
        #expect(!after.approvals.contains { $0.id == hire.id || $0.id == strategy.id })
    }

    @Test func companyPauseRoundTrip() async throws {
        let factory = try await store.connect(url: sandbox.url, credential: sandbox.key)
        let service = try store.service(for: factory)

        try await service.setCompanyPaused(true, companyID: sandbox.companyID)
        #expect(try await service.snapshot(companyID: sandbox.companyID).company.isPaused)

        try await service.setCompanyPaused(false, companyID: sandbox.companyID)
        #expect(try await service.snapshot(companyID: sandbox.companyID).company.isPaused == false)
    }

    @Test func connectsWithACustomHeader() async throws {
        let headers = [CustomHeader(name: "X-Fabrix-Sandbox", value: "proxy-token")]
        let factory = try await store.connect(url: sandbox.url, credential: sandbox.key, headers: headers)

        #expect(try store.customHeaders(for: factory) == headers)
        #expect(try await store.service(for: factory).companies().contains { $0.id == sandbox.companyID })
    }
}
