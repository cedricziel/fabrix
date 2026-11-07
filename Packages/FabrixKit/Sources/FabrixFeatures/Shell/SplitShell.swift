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
                    .factoryTitle()
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
            ForEach(AppSection.allCases) { section in
                Label(section.title, systemImage: section.systemImage)
                    .badge(badge(for: section))
                    .tag(section)
            }
        }
    }

    private func badge(for section: AppSection) -> Int {
        switch section {
        case .approvals: model.waitingCount
        case .tasks: model.snapshot?.tasks.count(where: \.status.isOpen) ?? 0
        default: 0
        }
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
