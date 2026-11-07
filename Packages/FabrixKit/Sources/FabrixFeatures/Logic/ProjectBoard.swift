import FabrixCore
import Foundation

struct TaskCounts: Equatable {
    var open = 0
    var blocked = 0
    var done = 0
}

/// Who leads a project, as far as the selected company knows.
enum ProjectLead: Equatable {
    case agent(Agent)
    /// Paperclip accepts another company's agent as lead; that agent isn't in this snapshot.
    case outsideCompany
    case none
}

/// Projects joined with the company's tasks, agents and activity.
struct ProjectBoard {
    let projects: [Project]
    private let tasksByProject: [Project.ID: [WorkItem]]
    private let agents: [Agent.ID: Agent]
    private let activity: [ActivityEvent]

    init(projects: [Project], snapshot: CompanySnapshot?) {
        self.projects = projects.filter { !$0.isArchived }
        let tasks = snapshot?.tasks ?? []
        tasksByProject = Dictionary(grouping: tasks.filter { $0.projectID != nil }) { $0.projectID! }
        agents = Dictionary((snapshot?.agents ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        activity = snapshot?.activity ?? []
    }

    var active: [Project] {
        projects.filter(\.status.isActive)
    }

    var completed: [Project] {
        projects.filter { !$0.status.isActive }
    }

    func project(_ id: Project.ID) -> Project? {
        projects.first { $0.id == id }
    }

    func counts(for id: Project.ID) -> TaskCounts {
        (tasksByProject[id] ?? []).reduce(into: TaskCounts()) { counts, task in
            switch task.status {
            case .backlog, .todo, .inProgress, .inReview: counts.open += 1
            case .blocked: counts.blocked += 1
            case .done: counts.done += 1
            case .cancelled: break
            }
        }
    }

    func tasks(in id: Project.ID) -> [WorkItem] {
        tasksByProject[id] ?? []
    }

    /// Events about the project itself or one of its tasks, newest first.
    func activity(for id: Project.ID) -> [ActivityEvent] {
        let taskIDs = Set(tasks(in: id).map(\.id))
        return activity
            .filter { $0.projectID == id || $0.taskID.map(taskIDs.contains) == true }
            .sorted { $0.at > $1.at }
    }

    func lead(of project: Project) -> ProjectLead {
        guard let id = project.leadAgentID else { return .none }
        return agents[id].map(ProjectLead.agent) ?? .outsideCompany
    }
}
