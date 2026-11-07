import FabrixCore

struct TaskColumn: Identifiable, Hashable {
    var status: TaskStatus
    var tasks: [WorkItem]
    var id: TaskStatus { status }
}

enum TaskBoard {
    static let statuses: [TaskStatus] = [.backlog, .todo, .inProgress, .inReview, .blocked, .done]

    static func columns(for tasks: [WorkItem]) -> [TaskColumn] {
        let grouped = Dictionary(grouping: tasks, by: \.status)
        return statuses.map { status in
            TaskColumn(status: status, tasks: (grouped[status] ?? []).sorted { $0.updatedAt > $1.updatedAt })
        }
    }

    static func sections(for tasks: [WorkItem]) -> [TaskColumn] {
        columns(for: tasks).filter { !$0.tasks.isEmpty }
    }
}
