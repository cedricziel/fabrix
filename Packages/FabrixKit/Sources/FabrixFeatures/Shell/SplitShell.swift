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
                #if os(iOS)
                    .safeAreaInset(edge: .bottom) {
                        SettingsButton()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                #endif
        } detail: {
            NavigationStack(path: $navigator.path) {
                SectionScreen(section: navigator.section)
                    .id(model.snapshot?.company.id)
                    .factoryTitle()
                    .fabrixDestinations()
            }
            .refreshable { await model.refresh() }
        }
        .searchable(text: $model.searchText, placement: .toolbar, prompt: LocalizedStringResource("Search tasks, agents", bundle: .module))
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
        #if os(macOS)
        // The leading edge belongs to navigation and the title menu.
        ToolbarItem(placement: .secondaryAction) { pauseButton }
        ToolbarItem(placement: .automatic) { newTaskButton }
        #else
        ToolbarItemGroup(placement: .primaryAction) {
            pauseButton
            newTaskButton
        }
        #endif
    }

    @ViewBuilder private var pauseButton: some View {
        if let company = model.snapshot?.company {
            Button {
                Task { await model.setCompanyPaused(!company.isPaused) }
            } label: {
                Label(company.isPaused ? LocalizedStringResource("Resume company", bundle: .module) : LocalizedStringResource("Pause company", bundle: .module),
                      systemImage: company.isPaused ? "play.fill" : "pause.fill")
            }
            .help(company.isPaused
                ? LocalizedStringResource("Resume every agent in \(company.name)", bundle: .module)
                : LocalizedStringResource("Pause every agent in \(company.name)", bundle: .module))
        }
    }

    private var newTaskButton: some View {
        Button {
            navigator.showingNewTask = true
        } label: {
            Label(LocalizedStringResource("New task", bundle: .module), systemImage: "plus")
        }
        .keyboardShortcut("n", modifiers: .command)
    }
}
