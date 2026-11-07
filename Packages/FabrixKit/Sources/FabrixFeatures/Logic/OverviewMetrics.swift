import FabrixCore

struct OverviewMetrics: Equatable {
    var agentsWorking: Int
    var agentsTotal: Int
    var agentsIdle: Int
    var agentsPaused: Int
    var openTasks: Int
    var tasksBlocked: Int
    var tasksInReview: Int
    var waitingByKind: [ApprovalKind: Int]
    var spend: Budget

    init(snapshot: CompanySnapshot, waiting: [Approval]) {
        let agents = snapshot.agents
        agentsWorking = agents.count(where: { $0.status == .running })
        agentsTotal = agents.count
        agentsIdle = agents.count(where: { $0.status == .idle })
        agentsPaused = agents.count(where: { $0.status == .paused })

        let open = snapshot.tasks.filter(\.status.isOpen)
        openTasks = open.count
        tasksBlocked = open.count(where: { $0.status == .blocked })
        tasksInReview = open.count(where: { $0.status == .inReview })

        waitingByKind = Dictionary(grouping: waiting, by: \.kind).mapValues(\.count)
        spend = Budget(spentCents: snapshot.spentMonthlyCents, capCents: snapshot.budgetMonthlyCents)
    }

    var waitingCount: Int { waitingByKind.values.reduce(0, +) }
}
