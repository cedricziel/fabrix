import FabrixCore
import FabrixDesign
import SwiftUI

struct OverviewView: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
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
                    SectionCard(title: "Activity") {
                        Button("All activity") { navigator.open(.activity) }
                            .buttonStyle(.borderless)
                    } content: {
                        ActivityRows(events: Array(snapshot.activity.prefix(5)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: 1200, alignment: .leading)
                .onGeometryChange(for: Bool.self) { $0.size.width >= 760 } action: { isWide = $0 }
            }
            .background(Palette.paper)
            .navigationTitle(snapshot.company.name)
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
            Text("Mission: \(mission)")
                .font(.callout)
                .foregroundStyle(Palette.steel)
        }
    }
}

private struct StatePill: View {
    let company: Company

    var body: some View {
        HStack(spacing: 6) {
            StatusDot(color: company.isPaused ? Palette.muted : Palette.done, hollow: company.isPaused, size: 7)
            Text(label)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(company.isPaused ? Palette.graphite : Palette.doneInk)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(company.isPaused ? Palette.rail : Palette.doneTint, in: .capsule)
    }

    private var label: String {
        if company.isPaused { return String(localized: "Paused") }
        guard let minutes = company.heartbeatMinutes else { return String(localized: "Running") }
        return String(localized: "Running · heartbeat every \(minutes) min")
    }
}

private struct MetricGrid: View {
    let metrics: OverviewMetrics

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
            MetricCard(title: "Agents working", value: "\(metrics.agentsWorking)", total: "\(metrics.agentsTotal)") {
                Text(Self.join([
                    (metrics.agentsIdle, String(localized: "\(metrics.agentsIdle) idle")),
                    (metrics.agentsPaused, String(localized: "\(metrics.agentsPaused) paused")),
                ]))
            }
            MetricCard(title: "Open tasks", value: "\(metrics.openTasks)") {
                Text(Self.join([
                    (metrics.tasksBlocked, String(localized: "\(metrics.tasksBlocked) blocked")),
                    (metrics.tasksInReview, String(localized: "\(metrics.tasksInReview) in review")),
                ]))
            }
            MetricCard(
                title: "Waiting on you", value: "\(metrics.waitingCount)",
                valueColor: metrics.waitingCount > 0 ? Palette.signal : Palette.graphite
            ) {
                Text(metrics.waitingCount > 0 ? waitingSummary : String(localized: "All clear"))
            }
            MetricCard(
                title: "Spend this month", value: Money.dollars(metrics.spend.spentCents),
                total: metrics.spend.capCents.map { Money.dollars($0) }
            ) {
                if let fraction = metrics.spend.fraction {
                    BudgetBar(fraction: fraction).padding(.top, 4)
                } else {
                    Text("No company cap")
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
        SectionCard(title: "Live runs") {
            if runs.isEmpty {
                EmptyRow(text: "No agent is running right now.")
            }
            ForEach(runs) { run in
                LiveRunRow(run: run)
                if run.id != runs.last?.id { Divider().overlay(Palette.rail) }
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
                AvatarBadge(initials: agent?.initials ?? "?")
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
    let waiting: [Approval]

    var body: some View {
        SectionCard(title: "Needs your decision") {
            if waiting.isEmpty {
                EmptyRow(text: "Nothing is waiting on you.")
            }
            ForEach(waiting) { approval in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        KindTag(kind: approval.kind)
                        Text("from \(approval.requestedBy)")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }
                    Text(approval.title).fontWeight(.semibold)
                    HStack(spacing: 8) {
                        Button("Approve") { model.decide(approval, approve: true) }
                            .buttonStyle(.fabrixPrimary)
                        Button("Open") { navigator.open(.approvals) }
                            .buttonStyle(.fabrixSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                if approval.id != waiting.last?.id { Divider().overlay(Palette.rail) }
            }
        }
    }
}

#Preview { PreviewHost { NavigationStack { OverviewView() } } }
