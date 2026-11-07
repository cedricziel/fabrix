import FabrixCore
import FabrixDesign
import SwiftUI

struct OverviewView: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    @Environment(\.isCompact) private var isCompact
    @State private var isWide = true

    var body: some View {
        if let snapshot = model.snapshot {
            let waiting = model.waitingApprovals
            let runs = snapshot.liveRuns
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CompanyHeader(company: snapshot.company)
                    MetricGrid(metrics: OverviewMetrics(snapshot: snapshot, waiting: waiting))
                    let layout = isWide
                        ? AnyLayout(HStackLayout(alignment: .top, spacing: 16))
                        : AnyLayout(VStackLayout(spacing: 16))
                    layout {
                        LiveRunsCard(runs: runs)
                        DecisionsCard(waiting: waiting)
                            .frame(maxWidth: isWide ? 380 : .infinity)
                    }
                    if isCompact, model.supportsProjects {
                        ProjectsCard()
                    }
                    SectionCard(.features("Activity"), actionTitle: .features("All activity"), action: { navigator.open(.activity) }) {
                        ActivityRows(events: Array(snapshot.activity.prefix(5)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: 1200, alignment: .leading)
                .onGeometryChange(for: Bool.self) { $0.size.width >= 760 } action: { isWide = $0 }
            }
            .background(Palette.paper)
        }
    }
}

private struct CompanyHeader: View {
    let company: Company

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom) {
                mission
                Spacer()
                StatePill(company: company)
            }
            VStack(alignment: .leading, spacing: 10) {
                mission
                StatePill(company: company)
            }
        }
    }

    @ViewBuilder private var mission: some View {
        if let mission = company.mission {
            Text("Mission: \(mission)", bundle: .module)
                .font(.callout)
                .foregroundStyle(Palette.steel)
        }
    }
}

private struct StatePill: View {
    let company: Company

    var body: some View {
        if company.isPaused {
            StatusPill(.paused)
        } else {
            StatusPill(.running, detail: heartbeat)
        }
    }

    private var heartbeat: String? {
        company.heartbeatMinutes.map { String(localized: "heartbeat every \($0) min", bundle: .module) }
    }
}

private struct MetricGrid: View {
    let metrics: OverviewMetrics

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
            MetricCard(.features("Agents working"), value: "\(metrics.agentsWorking)", total: "/ \(metrics.agentsTotal)") {
                Text(Self.join([
                    (metrics.agentsIdle, String(localized: "\(metrics.agentsIdle) idle", bundle: .module)),
                    (metrics.agentsPaused, String(localized: "\(metrics.agentsPaused) paused", bundle: .module)),
                ]))
            }
            MetricCard(.features("Open tasks"), value: "\(metrics.openTasks)") {
                Text(Self.join([
                    (metrics.tasksBlocked, String(localized: "\(metrics.tasksBlocked) blocked", bundle: .module)),
                    (metrics.tasksInReview, String(localized: "\(metrics.tasksInReview) in review", bundle: .module)),
                ]))
            }
            MetricCard(
                .features("Waiting on you"), value: "\(metrics.waitingCount)", emphasis: metrics.waitingCount > 0
            ) {
                Text(metrics.waitingCount > 0 ? waitingSummary : String(localized: "All clear", bundle: .module))
            }
            MetricCard(
                .features("Spend this month"), value: Money.dollars(metrics.spend.spentCents),
                total: metrics.spend.capCents.map { "/ \(Money.dollars($0))" }
            ) {
                if metrics.spend.fraction != nil {
                    BudgetBar(metrics.spend, height: 6).padding(.top, 4)
                } else {
                    Text("No company cap", bundle: .module)
                }
            }
        }
    }

    private var waitingSummary: String {
        Self.join(ApprovalKind.allCases.map { kind in
            let count = metrics.waitingByKind[kind] ?? 0
            return (count, "\(count) \(kind.label.lowercased())")
        })
    }

    private static func join(_ parts: [(count: Int, text: String)]) -> String {
        parts.filter { $0.count > 0 }.map(\.text).joined(separator: " · ")
    }
}

private struct LiveRunsCard: View {
    let runs: [Run]

    var body: some View {
        SectionCard(.features("Live runs")) {
            if runs.isEmpty {
                EmptyRow(.features("No agent is running right now."))
            }
            ForEach(runs) { run in
                LiveRunRow(run: run)
                if run.id != runs.last?.id { Divider().overlay(Palette.divider) }
            }
        }
    }
}

private struct LiveRunRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.isCompact) private var isCompact
    let run: Run

    var body: some View {
        NavigationLink(value: run.agentID) {
            let agent = model.agent(run.agentID)
            HStack(spacing: 12) {
                AvatarBadge(agent?.initials ?? "?")
                VStack(alignment: .leading, spacing: 2) {
                    Text(agent?.name ?? run.agentID).fontWeight(.semibold)
                    HStack(spacing: 4) {
                        if let task = run.taskIdentifier {
                            Text(task).font(.caption.monospaced())
                        }
                        Text(run.title).lineLimit(1)
                    }
                    .foregroundStyle(Palette.steel)
                }
                Spacer(minLength: 8)
                if let adapter = run.adapter, !isCompact {
                    Text(adapter)
                        .font(.caption.monospaced())
                        .foregroundStyle(Palette.steel)
                }
                ElapsedText(since: run.startedAt)
                    .font(.caption.monospaced())
                    .foregroundStyle(Palette.run)
                    .frame(minWidth: 48, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private struct DecisionsCard: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    @Environment(AppLock.self) private var lock
    let waiting: [Approval]

    var body: some View {
        SectionCard(.features("Needs your decision")) {
            if waiting.isEmpty {
                EmptyRow(.features("Nothing is waiting on you."))
            }
            ForEach(waiting) { approval in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        KindTag(title: approval.kind.label)
                        Text("from \(approval.requestedBy)", bundle: .module)
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }
                    Text(approval.title).fontWeight(.semibold)
                    HStack(spacing: 8) {
                        Button(.features("Approve")) { Task { await model.decide(approval, approve: true, confirmingWith: lock) } }
                            .buttonStyle(.fabrixPrimary)
                        Button(.features("Open")) { navigator.open(.approvals) }
                            .buttonStyle(.fabrixSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                if approval.id != waiting.last?.id { Divider().overlay(Palette.divider) }
            }
        }
    }
}

#Preview { PreviewHost { NavigationStack { OverviewView() } } }

/// iPhone: up to three active projects, with a way to all of them.
private struct ProjectsCard: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator

    var body: some View {
        let board = ProjectBoard(projects: model.projects, snapshot: model.snapshot)
        if board.active.isEmpty {
            SectionCard(.features("Projects")) { rows(board) }
        } else {
            SectionCard(
                .features("Projects"), actionTitle: .features("See all \(board.active.count)"),
                action: { navigator.open(.projects) }
            ) { rows(board) }
        }
    }

    @ViewBuilder private func rows(_ board: ProjectBoard) -> some View {
            VStack(alignment: .leading, spacing: 0) {
                if let failure = model.projectsFailure {
                    ProjectsFailureRow(message: failure).padding(.horizontal, 16).padding(.vertical, 8)
                } else if model.projectsState == .loading {
                    EmptyRow(.features("Loading projects…"))
                } else if board.active.isEmpty {
                    if board.completed.isEmpty {
                        EmptyRow(.features("No projects yet. Create one in Paperclip."))
                    } else {
                        EmptyRow(.features("No active projects."))
                    }
                }
                ForEach(board.active.prefix(3)) { project in
                    let counts = board.counts(for: project.id)
                    Button { navigator.open(project: project.id) } label: {
                        HStack(spacing: 12) {
                            ProjectSwatch(colorHex: project.colorHex, size: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.name).font(.fabrix(.headline))
                                Text("\(counts.open) open · \(counts.blocked) blocked", bundle: .module)
                                    .font(.caption)
                                    .foregroundStyle(counts.blocked > 0 ? Palette.haltInk : Palette.steel)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.idle)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 56)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            }

}
