import FabrixCore
import FabrixDesign
import SwiftUI

struct TasksView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.isCompact) private var isCompact
    @State private var selectedID: WorkItem.ID?

    var body: some View {
        let visible = model.visibleTasks
        Group {
            if isCompact {
                TaskList(sections: TaskBoard.sections(for: visible))
            } else {
                TaskBoardView(columns: TaskBoard.columns(for: visible), selectedID: $selectedID)
                    .inspector(isPresented: $selectedID.isPresent()) {
                        if let task = model.snapshot?.tasks.first(where: { $0.id == selectedID }) {
                            TaskDetailView(task: task)
                                .inspectorColumnWidth(min: 300, ideal: 340, max: 420)
                        }
                    }
            }
        }
        .navigationTitle("Tasks")
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
            Text("\(count)").font(.caption).foregroundStyle(Palette.muted)
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
            AssigneeLine(task: task)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .fabrixCard(cornerRadius: 10, selected: isSelected)
    }
}

private struct AssigneeLine: View {
    @Environment(AppModel.self) private var model
    let task: WorkItem

    var body: some View {
        HStack(spacing: 6) {
            if let agent = model.agent(task.assigneeID) {
                AvatarBadge(initials: agent.initials, size: 22)
                Text(agent.name).font(.caption).foregroundStyle(Palette.steel)
            } else {
                Text("Unassigned").font(.caption).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
            if model.liveRun(for: task) != nil {
                Text("running").font(.caption2.weight(.semibold)).foregroundStyle(Palette.run)
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
                            TaskDetailView(task: task)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.identifier).font(.caption.monospaced()).foregroundStyle(Palette.steel)
                                Text(task.title).fontWeight(.semibold)
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
        .overlay {
            if sections.isEmpty {
                ContentUnavailableView.search
            }
        }
    }
}

struct TaskDetailView: View {
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
                        Text("Assignee").foregroundStyle(Palette.muted)
                        Text(assignee?.name ?? String(localized: "Unassigned")).fontWeight(.medium)
                    }
                    GridRow {
                        Text("Updated").foregroundStyle(Palette.muted)
                        Text(task.updatedAt, format: .relative(presentation: .named))
                    }
                }
                if let run = model.liveRun(for: task) {
                    HStack {
                        Text("Running for")
                        ElapsedText(since: run.startedAt).font(.body.monospaced())
                    }
                    .foregroundStyle(Palette.run)
                }
                if let assignee {
                    HStack(spacing: 8) {
                        Button("Wake agent") { Task { await model.wake(assignee) } }
                            .buttonStyle(.fabrixPrimary)
                            .disabled(assignee.status == .running)
                        NavigationLink(value: assignee.id) { Text("Open agent") }
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
