import FabrixCore
import FabrixDesign
import SwiftUI

struct OrgChartView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedID: Agent.ID?

    var body: some View {
        let agents = model.snapshot?.agents ?? []
        VStack(spacing: 0) {
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 24) {
                    ForEach(OrgTree.build(agents)) { root in
                        OrgBranch(node: root, selectedID: $selectedID)
                    }
                }
                .padding(28)
            }
            OrgSummary()
                .padding([.horizontal, .bottom], 20)
        }
        .background(Palette.paper)
        .inspector(isPresented: $selectedID.isPresent()) {
            if let selectedID {
                AgentDetailView(agentID: selectedID)
                    .inspectorColumnWidth(min: 320, ideal: 360, max: 440)
            }
        }
    }
}

/// A node with its reports below it, joined by elbow connectors.
private struct OrgBranch: View {
    let node: OrgNode
    @Binding var selectedID: Agent.ID?

    var body: some View {
        VStack(spacing: 0) {
            OrgNodeCard(agent: node.agent, isSelected: node.id == selectedID) { selectedID = node.id }
            if !node.reports.isEmpty {
                Connector().frame(width: 2, height: 18)
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(node.reports.enumerated()), id: \.element.id) { index, child in
                        VStack(spacing: 0) {
                            Connector().frame(width: 2, height: 18)
                            OrgBranch(node: child, selectedID: $selectedID)
                        }
                        .overlay(alignment: .top) {
                            Rail(isFirst: index == 0, isLast: index == node.reports.count - 1)
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
    }
}

private struct Connector: View {
    var body: some View {
        Rectangle().fill(Palette.hairline)
    }
}

/// The horizontal bar above a child; each child draws its share so the bar spans first to last.
private struct Rail: View {
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: 0) {
            Connector().opacity(isFirst ? 0 : 1)
            Connector().opacity(isLast ? 0 : 1)
        }
        .frame(height: 2)
        .padding(.horizontal, -8)
    }
}

private struct OrgNodeCard: View {
    @Environment(AppModel.self) private var model
    let agent: Agent
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 10) {
                AvatarBadge(agent.initials, size: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(agent.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    StatusPill(model.status(of: agent).style)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 68)
            .fabrixCard(selected: isSelected)
            .frame(width: 180)
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OrgSummary: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let snapshot = model.snapshot {
            let metrics = OverviewMetrics(snapshot: snapshot, waiting: model.waitingApprovals)
            HStack(spacing: 28) {
                stat(LocalizedStringResource("Agents", bundle: .module), "\(metrics.agentsTotal)")
                stat(LocalizedStringResource("Working now", bundle: .module), "\(metrics.agentsWorking)")
                stat(LocalizedStringResource("Pending hires", bundle: .module), "\(metrics.waitingByKind[.hire] ?? 0)", color: Palette.signal)
                if metrics.spend.fraction != nil {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Company spend · \(Money.usage(metrics.spend))", bundle: .module)
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                        BudgetBar(metrics.spend)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .fabrixCard()
        }
    }

    private func stat(_ title: LocalizedStringResource, _ value: String, color: Color = Palette.graphite) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(Palette.muted)
            Text(value).font(.title3.weight(.semibold)).foregroundStyle(color)
        }
    }
}

#Preview { PreviewHost { NavigationStack { OrgChartView() } } }
