import FabrixCore
import FabrixDesign
import SwiftUI

struct ProjectDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    @Environment(\.dismiss) private var dismiss
    let projectID: Project.ID

    var body: some View {
        let board = ProjectBoard(projects: model.projects, snapshot: model.snapshot)
        if let project = board.project(projectID) {
            ProjectDetailContent(project: project, board: board)
                .navigationTitle(project.name)
        } else if model.projectsState == .loading {
            ProgressView()
        } else {
            ContentUnavailableView {
                Label("This project is gone", systemImage: "folder.badge.minus")
            } description: {
                Text("It was deleted, archived or made private in Paperclip.")
            } actions: {
                Button("Back to projects") {
                    if navigator.isCompact {
                        dismiss()
                    } else {
                        navigator.open(.projects)
                    }
                }
                .buttonStyle(.fabrixSecondary)
            }
        }
    }
}

private struct ProjectDetailContent: View {
    @Environment(AppModel.self) private var model
    @Environment(\.isCompact) private var isCompact
    let project: Project
    let board: ProjectBoard

    var body: some View {
        let counts = board.counts(for: project.id)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ProjectSwatch(colorHex: project.colorHex, size: 14)
                        // The Mac and iPad toolbar title is the company menu, so the name goes here.
                        if !isCompact {
                            Text(project.name).font(.fabrix(.title)).accessibilityAddTraits(.isHeader)
                        }
                        StatusPill(project.status.style)
                    }
                    if let summary = project.summary {
                        Text(summary).foregroundStyle(Palette.steel)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 24) { facts }
                        VStack(alignment: .leading, spacing: 8) { facts }
                    }
                }
                if let failure = model.projectsFailure {
                    Text("Projects didn't refresh: \(failure)").font(.caption).foregroundStyle(Palette.haltInk)
                }
                TaskCountsBar(open: counts.open, blocked: counts.blocked, done: counts.done)
                    .frame(maxWidth: 420, alignment: .leading)
                UnloadedTasksNote(count: board.unloadedTaskCount(for: project))
                SectionCard(title: "Tasks") {
                    ProjectTasks(columns: TaskBoard.sections(for: board.tasks(in: project.id)))
                }
                SectionCard(title: "Repositories") {
                    RepositoryRows(repositories: project.repositories)
                }
                SectionCard(title: "Activity") {
                    ActivityRows(events: Array(board.activity(for: project.id).prefix(10)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: 1000, alignment: .leading)
        }
        .background(Palette.paper)
    }

    @ViewBuilder private var facts: some View {
        LeadLabel(lead: board.lead(of: project))
        if let goal = project.goals.first {
            Label(goal, systemImage: "flag").font(.caption).foregroundStyle(Palette.steel)
        }
        if let day = project.targetDay {
            Label {
                Text(day, format: .dateTime.year().month(.abbreviated).day())
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.caption)
            .foregroundStyle(Palette.steel)
        }
    }
}

private struct ProjectTasks: View {
    @Environment(AppModel.self) private var model
    let columns: [TaskColumn]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if columns.isEmpty {
                EmptyRow(text: "No tasks in this project yet.")
            }
            ForEach(columns) { column in
                HStack(spacing: 8) {
                    Circle().fill(column.status.color).frame(width: 8, height: 8).accessibilityHidden(true)
                    Text(column.status.title).font(.fabrix(.subheadline))
                    Text("\(column.tasks.count)").font(.caption).foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
                ForEach(column.tasks) { task in
                    HStack(spacing: 12) {
                        Text(task.identifier).font(.fabrix(.monoCaption)).foregroundStyle(Palette.steel)
                        Text(task.title).lineLimit(1)
                        Spacer()
                        if let agent = model.agent(task.assigneeID) {
                            AvatarBadge(agent.initials, size: 22)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

private struct RepositoryRows: View {
    let repositories: [ProjectRepository]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if repositories.isEmpty {
                EmptyRow(text: "No repository linked. Link one in Paperclip.")
            }
            ForEach(repositories) { repository in
                if let url = repository.url {
                    Link(destination: url) { row(repository) }
                        .buttonStyle(.plain)
                } else {
                    row(repository)
                }
            }
        }
    }

    private func row(_ repository: ProjectRepository) -> some View {
        HStack(spacing: 12) {
            Image(systemName: repository.kind == .git ? "arrow.triangle.branch" : "folder")
                .foregroundStyle(Palette.steel)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(repository.name).font(.fabrix(.mono))
                if let ref = repository.ref {
                    Text(ref).font(.caption).foregroundStyle(Palette.muted)
                }
            }
            Spacer()
            if repository.isPrimary {
                Text("PRIMARY")
                    .font(.fabrix(.tag))
                    .foregroundStyle(Palette.neutralInk)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Palette.neutralTint, in: RoundedRectangle(cornerRadius: Radius.tag))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
