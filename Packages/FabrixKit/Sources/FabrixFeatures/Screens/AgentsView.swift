import FabrixCore
import FabrixDesign
import SwiftUI

struct AgentsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List(model.visibleAgents) { agent in
            NavigationLink(value: agent.id) {
                HStack(spacing: 12) {
                    AvatarBadge(initials: agent.initials, size: 36, tint: agent.tileColor)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(agent.name).fontWeight(.semibold)
                        StatusPill(status: agent.status)
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

extension Agent {
    var tileColor: Color {
        switch status {
        case .needsYou: Palette.signal
        case .paused: Palette.muted
        default: Palette.graphite
        }
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
                        Button("Pause") { Task { await model.pause(agent) } }
                            .buttonStyle(FabrixButtonStyle(role: .secondary, fullWidth: true))
                            .disabled(agent.status == .paused)
                        Button("Wake now") { Task { await model.wake(agent) } }
                            .buttonStyle(FabrixButtonStyle(role: .signal, fullWidth: true))
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
            AvatarBadge(initials: agent.initials, size: 56, tint: agent.tileColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name).font(.title2.weight(.semibold))
                HStack(spacing: 4) {
                    StatusPill(status: agent.status)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Current run").font(.caption.weight(.semibold)).textCase(.uppercase)
                Spacer()
                ElapsedText(since: run.startedAt).font(.title3.monospaced().weight(.medium))
            }
            .foregroundStyle(.white.opacity(0.8))
            if let task = run.taskIdentifier {
                Text(task).font(.caption.monospaced()).foregroundStyle(.white.opacity(0.7))
            }
            Text(run.title).font(.headline).foregroundStyle(.white)
            if let summary = run.summary {
                Text(summary).font(.subheadline).foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.graphite, in: .rect(cornerRadius: 14))
    }
}

private struct BudgetSection: View {
    let agent: Agent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Budget this month").font(.subheadline.weight(.semibold))
                Spacer()
                Text(Money.usage(agent.budget)).font(.subheadline.monospaced())
            }
            if let fraction = agent.budget.fraction {
                BudgetBar(fraction: fraction, height: 8)
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
        .padding(16)
        .fabrixCard()
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
