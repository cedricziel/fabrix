import FabrixCore

struct OrgNode: Identifiable, Hashable {
    var agent: Agent
    var reports: [OrgNode]
    var id: Agent.ID { agent.id }
}

enum OrgTree {
    /// Agents whose manager is missing become roots; agents caught in a reporting cycle are
    /// attached once, under the first of them in input order.
    static func build(_ agents: [Agent]) -> [OrgNode] {
        let ids = Set(agents.map(\.id))
        let reports = Dictionary(grouping: agents.filter { $0.reportsToID.map(ids.contains) == true }) { $0.reportsToID! }
        var placed = Set<Agent.ID>()

        func node(for agent: Agent) -> OrgNode {
            placed.insert(agent.id)
            let children = (reports[agent.id] ?? []).filter { !placed.contains($0.id) }
            children.forEach { placed.insert($0.id) }
            return OrgNode(agent: agent, reports: children.map(node(for:)))
        }

        var roots = agents.filter { $0.reportsToID.map(ids.contains) != true }.map(node(for:))
        for agent in agents where !placed.contains(agent.id) {
            roots.append(node(for: agent))
        }
        return roots
    }
}
