import FabrixCore
import FabrixDesign
import SwiftUI

struct AgentsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List(model.visibleAgents) { agent in
            NavigationLink(value: agent.id) {
                HStack(spacing: 12) {
                    AvatarBadge(agent.initials, size: 36)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(agent.name).fontWeight(.semibold)
                        StatusPill(agent.status.style)
                    }
                    Spacer()
                    if agent.budget.capCents != nil {
                        Text(Money.usage(agent.budget))
                            .font(.caption.monospaced())
                            .foregroundStyle(agent.budget.isNearCap ? Palette.signal : Palette.steel)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .overlay {
            if model.visibleAgents.isEmpty { ContentUnavailableView.search }
        }
        .navigationTitle("Agents")
    }
}

struct AgentDetailView: View {
    @Environment(AppModel.self) private var model
    let agentID: Agent.ID

    var body: some View {
        if let agent = model.agent(agentID) {
            let runs = model.runs(of: agentID)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(agent)
                    if let run = runs.first(where: \.isLive) {
                        CurrentRunCard(run: run)
                    }
                    BudgetSection(agent: agent)
                    RecentRuns(runs: runs.filter { !$0.isLive })
                    HStack(spacing: 10) {
                        Button { Task { await model.pause(agent) } } label: {
                            Text("Pause").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.fabrixSecondary)
                            .disabled(agent.status == .paused)
                        Button { Task { await model.wake(agent) } } label: {
                            Text("Wake now").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.fabrixSignal)
                            .disabled(agent.status == .running)
                    }
                    .controlSize(.large)
                }
                .padding(20)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.paper)
            .navigationTitle(agent.name)
        } else {
            ContentUnavailableView("Agent not found", systemImage: "person.crop.circle.badge.questionmark")
        }
    }

    private func header(_ agent: Agent) -> some View {
        HStack(spacing: 14) {
            AvatarBadge(agent.initials, size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name).font(.title2.weight(.semibold))
                HStack(spacing: 4) {
                    StatusPill(agent.status.style)
                    Text("· reports to \(model.agent(agent.reportsToID)?.name ?? String(localized: "the board"))")
                        .font(.caption)
                        .foregroundStyle(Palette.steel)
                }
                if let role = agent.role, let adapter = agent.adapter {
                    Text("\(role) · \(adapter)").font(.caption.monospaced()).foregroundStyle(Palette.muted)
                }
            }
        }
    }
}

private struct CurrentRunCard: View {
    let run: Run

    var body: some View {
        Card(style: .inverse) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Current run").font(.caption.weight(.semibold)).textCase(.uppercase)
                    Spacer()
                    ElapsedText(since: run.startedAt).font(.title3.monospaced().weight(.medium))
                }
                .foregroundStyle(Palette.onInverseMuted)
                if let task = run.taskIdentifier {
                    Text(task).font(.caption.monospaced()).foregroundStyle(Palette.onInverseMuted)
                }
                Text(run.title).font(.headline)
                if let summary = run.summary {
                    Text(summary).font(.subheadline).foregroundStyle(Palette.onInverseMuted)
                }
            }
        }
    }
}

private struct BudgetSection: View {
    let agent: Agent

    var body: some View {
        Card { content }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Budget this month").font(.subheadline.weight(.semibold))
                Spacer()
                Text(Money.usage(agent.budget)).font(.subheadline.monospaced())
            }
            if let fraction = agent.budget.fraction {
                BudgetBar(agent.budget)
                if agent.budget.isNearCap {
                    Text("Near cap: agent pauses automatically at 100%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.signal)
                } else {
                    Text("\(fraction, format: .percent.precision(.fractionLength(0))) used")
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }
            } else {
                Text("No monthly cap").font(.caption).foregroundStyle(Palette.muted)
            }
        }
    }
}

private struct RecentRuns: View {
    let runs: [Run]

    var body: some View {
        SectionCard(title: "Recent runs") {
            if runs.isEmpty {
                EmptyRow(text: "No finished runs yet.")
            }
            ForEach(runs) { run in
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text([run.taskIdentifier, run.title].compactMap(\.self).joined(separator: " "))
                            .fontWeight(.medium)
                            .lineLimit(1)
                        HStack(spacing: 0) {
                            Text(run.startedAt, format: .dateTime.hour().minute())
                            if let summary = run.summary { Text(" · \(summary)") }
                        }
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    if let cost = run.costCents {
                        Text(Money.exact(cost)).font(.caption.monospaced()).foregroundStyle(Palette.steel)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }
}

#Preview { PreviewHost { NavigationStack { AgentDetailView(agentID: "fe") } } }
