import FabrixCore
@testable import FabrixFeatures
import Testing

struct OrgTreeTests {
    private func agent(_ id: String, reportsTo boss: String? = nil) -> Agent {
        Agent(id: id, name: id, status: .idle, reportsToID: boss)
    }

    @Test func buildsTreeFromReportsToKeepingInputOrder() {
        let roots = OrgTree.build([
            agent("ceo"), agent("cto", reportsTo: "ceo"), agent("cmo", reportsTo: "ceo"), agent("fe", reportsTo: "cto"),
        ])
        #expect(roots.map(\.id) == ["ceo"])
        #expect(roots[0].reports.map(\.id) == ["cto", "cmo"])
        #expect(roots[0].reports[0].reports.map(\.id) == ["fe"])
    }

    @Test func agentWithUnknownManagerBecomesARoot() {
        let roots = OrgTree.build([agent("ceo"), agent("orphan", reportsTo: "gone")])
        #expect(roots.map(\.id) == ["ceo", "orphan"])
    }

    @Test func cyclesStillShowEveryAgentOnce() {
        let roots = OrgTree.build([agent("a", reportsTo: "b"), agent("b", reportsTo: "a")])
        let all = roots.flatMap { [$0.id] + $0.reports.map(\.id) }
        #expect(all.sorted() == ["a", "b"])
    }

    @Test func demoCompanyHasTheCEOAtTheTop() async throws {
        let snapshot = try await DemoFactoryService().snapshot(companyID: "atlas")
        let roots = OrgTree.build(snapshot.agents)
        #expect(roots.map(\.agent.name) == ["CEO"])
        #expect(roots[0].reports.map(\.agent.name) == ["CTO", "CMO"])
    }
}
