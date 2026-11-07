import FabrixCore
import FabrixDesign
import SwiftUI

struct TasksView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.isCompact) private var isCompact
    @State private var selectedID: WorkItem.ID?

    var body: some View {
        let visible = model.visibleTasks
        let emptiness = ListEmptiness(total: model.snapshot?.tasks.count ?? 0, visible: visible.count, query: model.searchText)
        Group {
            if isCompact {
                TaskList(sections: TaskBoard.sections(for: visible))
                    .overlay {
                        EmptyStateView(
                            emptiness: emptiness, title: .features("No tasks yet"), systemImage: "rectangle.split.3x1",
                            hint: .features("Create one on your Paperclip board.")
                        )
                    }
            } else {
                TaskBoardView(columns: TaskBoard.columns(for: visible), selectedID: $selectedID)
                    .overlay {
                        EmptyStateView(
                            emptiness: emptiness, title: .features("No tasks yet"), systemImage: "rectangle.split.3x1",
                            hint: .features("Create one on your Paperclip board.")
                        )
                    }
                    .inspector(isPresented: $selectedID.isPresent()) {
                        if let selectedID {
                            TaskDetailView(taskID: selectedID)
                                .inspectorColumnWidth(min: 300, ideal: 340, max: 420)
                        }
                    }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { ProjectFilterToken() }
        .toolbar {
            if model.supportsProjects, !model.projects.isEmpty {
                ToolbarItem { ProjectFilterMenu() }
            }
        }
    }
}

private struct ProjectFilterMenu: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Menu {
            Picker(.features("Project"), selection: $model.taskProjectFilter) {
                Text("All projects", bundle: .module).tag(ProjectFilter.all)
                ForEach(model.projects) { project in
                    Text(project.name).tag(ProjectFilter.project(project.id))
                }
                Text("No project", bundle: .module).tag(ProjectFilter.none)
            }
            .pickerStyle(.inline)
        } label: {
            Label(.features("Project"), systemImage: model.taskProjectFilter == .all
                ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
        .help(.features("Filter by project"))
    }
}

/// The active project filter, with a way to clear it and to open the project.
private struct ProjectFilterToken: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator

    var body: some View {
        if model.taskProjectFilter != .all {
            let project: Project? = if case let .project(id) = model.taskProjectFilter {
                model.projects.first { $0.id == id }
            } else {
                nil
            }
            HStack(spacing: 10) {
                FilterChip(
                    project?.name ?? String(localized: "No project", bundle: .module),
                    clearLabel: String(localized: "Show all projects", bundle: .module),
                    onClear: { model.taskProjectFilter = .all }
                ) {
                    if let project { ProjectSwatch(colorHex: project.colorHex) }
                }
                Text("^[\(model.visibleTasks.count) task](inflect: true)", bundle: .module).font(.caption).foregroundStyle(Palette.steel)
                Spacer()
                if let project {
                    Button(.features("Project details")) { navigator.open(project: project.id) }
                        .buttonStyle(.borderless)
                        .font(.caption.weight(.medium))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Palette.paper)
        }
    }
}

private struct TaskBoardView: View {
    let columns: [TaskColumn]
    @Binding var selectedID: WorkItem.ID?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(columns) { column in
                    VStack(alignment: .leading, spacing: 8) {
                        ColumnHeader(status: column.status, count: column.tasks.count)
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 8) {
                                ForEach(column.tasks) { task in
                                    Button { selectedID = task.id } label: {
                                        TaskCard(task: task, isSelected: task.id == selectedID)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .scrollIndicators(.hidden)
                    }
                    .frame(width: 220)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Palette.paper)
    }
}

private struct ColumnHeader: View {
    let status: TaskStatus
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(status.color).frame(width: 8, height: 8)
            Text(status.title).font(.subheadline.weight(.semibold))
            Text(count, format: .number).font(.caption).foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct TaskCard: View {
    let task: WorkItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.identifier)
                .font(.caption2.monospaced())
                .foregroundStyle(Palette.steel)
            Text(task.title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            TaskProjectChip(task: task)
            AssigneeLine(task: task)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .fabrixCard(selected: isSelected)
    }
}

private struct AssigneeLine: View {
    @Environment(AppModel.self) private var model
    let task: WorkItem

    var body: some View {
        HStack(spacing: 6) {
            if let agent = model.agent(task.assigneeID) {
                AvatarBadge(agent.initials, size: 22)
                Text(agent.name).font(.caption).foregroundStyle(Palette.steel)
            } else {
                Text("Unassigned", bundle: .module).font(.caption).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
            if model.liveRun(for: task) != nil {
                Text("running", bundle: .module).font(.caption2.weight(.semibold)).foregroundStyle(Palette.run)
            }
        }
    }
}

private struct TaskList: View {
    let sections: [TaskColumn]

    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.tasks) { task in
                        NavigationLink {
                            TaskDetailView(taskID: task.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.identifier).font(.caption.monospaced()).foregroundStyle(Palette.steel)
                                Text(task.title).fontWeight(.semibold)
                                TaskProjectChip(task: task)
                                AssigneeLine(task: task)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    ColumnHeader(status: section.status, count: section.tasks.count)
                }
            }
        }

    }
}

/// Looks the task up on every update so details follow polls, wakes and edits.
struct TaskDetailView: View {
    @Environment(AppModel.self) private var model
    let taskID: WorkItem.ID

    var body: some View {
        if let task = model.task(taskID) {
            TaskDetailContent(task: task)
        } else {
            ContentUnavailableView {
                Label(.features("Task not found"), systemImage: "rectangle.slash")
            } description: {
                Text("It was deleted or moved on the board.", bundle: .module)
            }
        }
    }
}

private struct TaskDetailContent: View {
    @Environment(AppModel.self) private var model
    let task: WorkItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text(task.identifier).font(.caption.monospaced()).foregroundStyle(Palette.steel)
                    Text(task.status.title)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Palette.rail, in: .capsule)
                }
                Text(task.title).font(.title3.weight(.semibold))
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                    GridRow {
                        Text("Assignee", bundle: .module).foregroundStyle(Palette.muted)
                        Text(assignee?.name ?? String(localized: "Unassigned", bundle: .module)).fontWeight(.medium)
                    }
                    GridRow {
                        Text("Updated", bundle: .module).foregroundStyle(Palette.muted)
                        Text(task.updatedAt, format: .relative(presentation: .named))
                    }
                }
                if let run = model.liveRun(for: task) {
                    HStack {
                        Text("Running for", bundle: .module)
                        ElapsedText(since: run.startedAt).font(.body.monospaced())
                    }
                    .foregroundStyle(Palette.run)
                }
                if let assignee {
                    HStack(spacing: 8) {
                        Button { Task { await model.wake(assignee) } } label: {
                            ActionLabel(.features("Wake agent"), isBusy: model.isPending(.wake(assignee.id)))
                        }
                        .buttonStyle(.fabrixPrimary)
                        .disabled(!model.canWake(assignee))
                        NavigationLink(value: assignee.id) { Text("Open agent", bundle: .module) }
                            .buttonStyle(.fabrixSecondary)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.card)
    }

    private var assignee: Agent? { model.agent(task.assigneeID) }
}

#Preview { PreviewHost { NavigationStack { TasksView() } } }

extension AppModel {
    func task(_ id: WorkItem.ID) -> WorkItem? {
        snapshot?.tasks.first { $0.id == id }
    }
}

private struct TaskProjectChip: View {
    @Environment(AppModel.self) private var model
    let task: WorkItem

    var body: some View {
        if let project = model.chipProject(for: task) {
            ProjectChip(name: project.name, colorHex: project.colorHex)
        }
    }
}
