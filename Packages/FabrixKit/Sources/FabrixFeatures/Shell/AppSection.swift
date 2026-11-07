import FabrixCore
import SwiftUI

enum AppSection: String, Hashable, CaseIterable, Identifiable {
    case overview, projects, tasks, agents, orgChart, approvals, activity

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .overview: .features("Overview")
        case .projects: .features("Projects")
        case .tasks: .features("Tasks")
        case .agents: .features("Agents")
        case .orgChart: .features("Org chart")
        case .approvals: .features("Approvals")
        case .activity: .features("Activity")
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .projects: "folder"
        case .tasks: "rectangle.split.3x1"
        case .agents: "person.2"
        case .orgChart: "point.3.connected.trianglepath.dotted"
        case .approvals: "checkmark"
        case .activity: "waveform.path.ecg"
        }
    }
}

/// The iPhone tabs. Sections without a tab open inside the Factory tab.
enum CompactTab: Hashable, CaseIterable {
    case factory, tasks, approvals, agents

    init(containing section: AppSection) {
        switch section {
        case .tasks: self = .tasks
        case .approvals: self = .approvals
        case .agents: self = .agents
        case .overview, .projects, .orgChart, .activity: self = .factory
        }
    }

    var root: AppSection {
        switch self {
        case .factory: .overview
        case .tasks: .tasks
        case .approvals: .approvals
        case .agents: .agents
        }
    }

    var title: LocalizedStringResource { self == .factory ? .features("Factory") : root.title }

    /// Sections reached from inside this tab rather than from a tab of their own.
    var nestedSections: [AppSection] {
        AppSection.allCases.filter { $0 != root && CompactTab(containing: $0) == self }
    }
}

/// Where the user is. Screens call `open(_:)`; each shell decides how to get there.
@MainActor
@Observable
final class Navigator {
    var section = AppSection.overview {
        didSet { if section != oldValue { path = NavigationPath() } }
    }
    var path = NavigationPath()
    var tab = CompactTab.factory
    var tabPaths: [CompactTab: NavigationPath] = [:]
    var showingNewTask = false
    var confirmingRemove = false
    var showingAddFactory = false
    var showingSettings = false

    /// Another sheet can't present on top; the lock offer waits for these to close.
    var isPresentingSheet: Bool {
        showingNewTask || showingAddFactory || showingSettings
    }
    var confirmingPauseCompany = false
    var isCompact = false
    /// The project picked in the regular-width sidebar; its detail replaces the section.
    var project: Project.ID? {
        didSet { if project != oldValue { path = NavigationPath() } }
    }

    /// A new factory or company starts every stack at its root, and leaves any project.
    func resetPaths() {
        path = NavigationPath()
        tabPaths = [:]
        project = nil
    }

    func open(_ section: AppSection) {
        guard isCompact else {
            project = nil
            self.section = section
            return
        }
        let tab = CompactTab(containing: section)
        self.tab = tab
        var path = NavigationPath()
        if section != tab.root { path.append(section) }
        tabPaths[tab] = path
    }
}

extension Navigator {
    /// The factory has no projects (any more): leave anything that shows them.
    func leaveProjects() {
        if project != nil || section == .projects {
            project = nil
            section = .overview
        }
        tabPaths[.factory] = nil
    }

    func open(project id: Project.ID) {
        guard isCompact else {
            section = .projects
            project = id
            return
        }
        tab = .factory
        var path = tabPaths[.factory] ?? NavigationPath()
        path.append(ProjectRoute(id: id))
        tabPaths[.factory] = path
    }
}

struct ProjectRoute: Hashable {
    var id: Project.ID
}

extension View {
    /// Destinations every navigation stack in the app can push.
    func fabrixDestinations() -> some View {
        navigationDestination(for: Agent.ID.self) { AgentDetailView(agentID: $0).statusInsets() }
            .navigationDestination(for: AppSection.self) {
                SectionScreen(section: $0).statusInsets().navigationTitle($0.title)
            }
            .navigationDestination(for: ProjectRoute.self) { ProjectDetailView(projectID: $0.id).statusInsets() }
    }
}
