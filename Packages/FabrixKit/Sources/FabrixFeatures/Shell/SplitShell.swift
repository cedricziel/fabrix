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
                Group {
                    if let project = navigator.project {
                        ProjectDetailView(projectID: project)
                    } else {
                        SectionScreen(section: navigator.section)
                    }
                }
                .id(model.snapshot?.company.id)
                    .factoryTitle()
                    .fabrixDestinations()
            }
            .refreshable { await model.refresh() }
        }
        .searchable(text: $model.searchText, placement: .toolbar, prompt: .features("Search tasks, agents"))
        .toolbar { CompanyToolbar() }
    }
}

struct SectionScreen: View {
    let section: AppSection

    var body: some View {
        switch section {
        case .overview: OverviewView()
        case .projects: ProjectsView()
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
        List(selection: selection) {
            ForEach(AppSection.allCases.filter { $0 != .projects }) { section in
                Label(section.title, systemImage: section.systemImage)
                    .badge(badge(for: section))
                    .tag(SidebarItem.section(section))
            }
            if model.supportsProjects {
                Section(.features("Projects")) { ProjectsSidebarGroup() }
            }
        }
    }

    private var selection: Binding<SidebarItem?> {
        Binding {
            navigator.project.map(SidebarItem.project) ?? .section(navigator.section)
        } set: { item in
            switch item {
            case let .section(section): navigator.open(section)
            case let .project(id): navigator.open(project: id)
            case nil: break
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
        // Pull to refresh doesn't exist on macOS.
        ToolbarItem(placement: .automatic) { refreshButton }
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
                Label(company.isPaused ? .features("Resume company") : .features("Pause company"),
                      systemImage: company.isPaused ? "play.fill" : "pause.fill")
            }
            .help(company.isPaused
                ? .features("Resume every agent in \(company.name)")
                : .features("Pause every agent in \(company.name)"))
        }
    }

    #if os(macOS)
    private var refreshButton: some View {
        Button {
            Task { await model.refresh() }
        } label: {
            if model.isRefreshing {
                ProgressView().controlSize(.small)
            } else {
                Label(.features("Refresh"), systemImage: "arrow.clockwise")
            }
        }
        .disabled(model.isRefreshing)
        .help(Text("Refresh (⌘R)", bundle: .module))
    }
    #endif

    private var newTaskButton: some View {
        Button {
            navigator.showingNewTask = true
        } label: {
            Label(.features("New task"), systemImage: "plus")
        }
        .keyboardShortcut("n", modifiers: .command)
    }
}

enum SidebarItem: Hashable {
    case section(AppSection)
    case project(Project.ID)
}

/// All projects, then one row per active project with its open and blocked counts.
private struct ProjectsSidebarGroup: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let board = ProjectBoard(projects: model.projects, snapshot: model.snapshot)
        Label(.features("All projects"), systemImage: AppSection.projects.systemImage)
            .badge(board.active.count)
            .tag(SidebarItem.section(.projects))
        if model.projectsState == .loading {
            ForEach(0 ..< 3, id: \.self) { _ in
                Label(.features("Project"), systemImage: "square.fill").redacted(reason: .placeholder)
            }
            .accessibilityHidden(true)
        }
        if model.projectsFailure != nil {
            Button(model.projects.isEmpty ? "Didn't load · Retry" : "Didn't refresh · Retry", systemImage: "exclamationmark.circle") {
                Task { await model.retryProjects() }
            }
            .foregroundStyle(Palette.haltInk)
        }
        ForEach(board.active) { project in
            let counts = board.counts(for: project.id)
            HStack(spacing: 8) {
                ProjectSwatch(colorHex: project.colorHex)
                    .frame(width: 18)
                Text(project.name).lineLimit(1)
                Spacer()
                if counts.blocked > 0 {
                    Label(.features("\(counts.blocked)"), systemImage: "circle.fill")
                        .labelStyle(BlockedCountStyle())
                        .accessibilityLabel(.features("\(counts.blocked) blocked"))
                }
                Text("\(counts.open)", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                    .accessibilityLabel(.features("\(counts.open) open"))
            }
            .tag(SidebarItem.project(project.id))
        }
    }
}

private struct BlockedCountStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon.font(.system(size: 6)).foregroundStyle(Palette.halt)
            configuration.title.font(.caption.weight(.semibold)).foregroundStyle(Palette.haltInk)
        }
    }
}
