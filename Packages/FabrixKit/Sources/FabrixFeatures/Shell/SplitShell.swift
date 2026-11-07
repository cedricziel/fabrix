import FabrixCore
import FabrixDesign
import SwiftUI

/// Mac and iPad: factories and sections in the sidebar, the chosen section on the right.
struct SplitShell: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator
        @Bindable var model = model
        NavigationSplitView {
            Sidebar()
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
        } detail: {
            NavigationStack(path: $navigator.path) {
                SectionScreen(section: navigator.section)
                    .fabrixDestinations()
            }
            .refreshable { await model.refresh() }
        }
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "Search tasks, agents")
        .toolbar { CompanyToolbar() }
    }
}

struct SectionScreen: View {
    let section: AppSection

    var body: some View {
        switch section {
        case .overview: OverviewView()
        case .tasks: TasksView()
        case .agents: AgentsView()
        case .orgChart: OrgChartView()
        case .approvals: ApprovalsView()
        case .activity: ActivityView()
        }
    }
}

private struct Sidebar: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator
        List(selection: Binding($navigator.section)) {
            Section("Factories") {
                if let factory = model.factory {
                    FactoryRow(factory: factory)
                }
                ForEach(model.companies) { company in
                    CompanyRow(company: company, isSelected: company.id == model.snapshot?.company.id)
                }
                Button {
                    model.disconnect()
                } label: {
                    Label("Switch factory", systemImage: "arrow.left.arrow.right")
                }
                .foregroundStyle(Palette.muted)
                .buttonStyle(.plain)
            }
            Section(model.snapshot?.company.name ?? "") {
                ForEach(AppSection.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .badge(badge(for: section))
                        .tag(section)
                }
            }
        }
        .navigationTitle(model.snapshot?.company.name ?? "Fabrix")
    }

    private func badge(for section: AppSection) -> Int {
        switch section {
        case .approvals: model.waitingCount
        case .tasks: model.snapshot?.tasks.count(where: \.status.isOpen) ?? 0
        default: 0
        }
    }
}

private struct FactoryRow: View {
    let factory: Factory

    var body: some View {
        HStack(spacing: 8) {
            StatusDot(factory.isOnline ? .done : .paused, size: 8)
            Text(factory.name).fontWeight(.semibold)
            Spacer()
            Text(factory.isOnline ? "online" : "offline")
                .font(.caption.monospaced())
                .foregroundStyle(Palette.muted)
        }
        .selectionDisabled()
    }
}

private struct CompanyRow: View {
    @Environment(AppModel.self) private var model
    let company: Company
    let isSelected: Bool

    var body: some View {
        Button {
            Task { await model.select(company) }
        } label: {
            HStack {
                Text(company.name).fontWeight(isSelected ? .semibold : .regular)
                Spacer()
                if company.isPaused {
                    Text("paused").font(.caption).foregroundStyle(Palette.muted)
                } else if isSelected, let count = model.snapshot?.agents.count {
                    Text("\(count) agents").font(.caption).foregroundStyle(Palette.muted)
                }
            }
            .padding(.leading, 16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .selectionDisabled()
    }
}

/// Pause company and New task, shared by the split view and the iPhone Factory tab.
struct CompanyToolbar: ToolbarContent {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if let company = model.snapshot?.company {
                Button {
                    Task { await model.setCompanyPaused(!company.isPaused) }
                } label: {
                    Label(company.isPaused ? "Resume company" : "Pause company",
                          systemImage: company.isPaused ? "play.fill" : "pause.fill")
                }
                .help(company.isPaused ? "Resume every agent in \(company.name)" : "Pause every agent in \(company.name)")
            }
            Button {
                navigator.showingNewTask = true
            } label: {
                Label("New task", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
