import FabrixCore
import FabrixDesign
import SwiftUI

/// All projects of the selected company, active or completed.
struct ProjectsView: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    @Environment(\.isCompact) private var isCompact
    @State private var showsCompleted = false

    var body: some View {
        let board = ProjectBoard(projects: model.projects, snapshot: model.snapshot)
        let shown = showsCompleted ? board.completed : board.active
        List {
            Section {
                Picker(.features("Show"), selection: $showsCompleted) {
                    Text("Active · \(board.active.count)", bundle: .module).tag(false)
                    Text("Completed · \(board.completed.count)", bundle: .module).tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .listRowBackground(Color.clear)
            }
            if let failure = model.projectsFailure {
                ProjectsFailureRow(message: failure)
            }
            Section {
                if model.projectsState == .loading {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        ProjectRow(project: ProjectsView.placeholder, counts: TaskCounts(open: 3), unloaded: 0, lead: .none, isCompact: isCompact)
                    }
                    .redacted(reason: .placeholder)
                    .accessibilityLabel(.features("Loading projects"))
                } else {
                    ForEach(shown) { project in
                        Button { navigator.open(project: project.id) } label: {
                            ProjectRow(
                                project: project, counts: board.counts(for: project.id), unloaded: board.unloadedTaskCount(for: project),
                                lead: board.lead(of: project), isCompact: isCompact
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .overlay {
            if model.projectsState != .loading, model.projectsFailure == nil, shown.isEmpty {
                ContentUnavailableView {
                    Label(showsCompleted ? "No completed projects" : "No projects in \(model.snapshot?.company.name ?? "this company")", systemImage: "folder")
                } description: {
                    Text("Projects group tasks and repositories. Create one in Paperclip and it shows up here on the next refresh.", bundle: .module)
                }
            }
        }
        .navigationTitle(.features("Projects"))
    }

    static let placeholder = Project(id: "placeholder", name: "Project name", status: .inProgress)
}

struct ProjectsFailureRow: View {
    @Environment(AppModel.self) private var model
    let message: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "exclamationmark.circle").accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.projects.isEmpty ? "Projects didn't load" : "Projects didn't refresh").fontWeight(.semibold)
                Text(message).font(.caption)
            }
            Spacer()
            Button(.features("Retry")) { Task { await model.retryProjects() } }
                .buttonStyle(.fabrixSecondary)
                .controlSize(.small)
        }
        .foregroundStyle(Palette.haltInk)
        .listRowBackground(Palette.haltTint)
    }
}

struct ProjectRow: View {
    let project: Project
    let counts: TaskCounts
    let unloaded: Int
    let lead: ProjectLead
    let isCompact: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProjectSwatch(colorHex: project.colorHex, size: 12).padding(.top, 4)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(project.name).font(.fabrix(.headline))
                    if isCompact { Pill(project.status.style) }
                }
                if let goal = project.goals.first {
                    Text(goal).font(.caption).foregroundStyle(Palette.muted).lineLimit(1)
                }
                TaskCountsBar(open: counts.open, blocked: counts.blocked, done: counts.done)
                    .frame(maxWidth: 320, alignment: .leading)
                UnloadedTasksNote(count: unloaded)
                LeadLabel(lead: lead)
            }
            Spacer(minLength: 12)
            if !isCompact {
                VStack(alignment: .trailing, spacing: 6) {
                    Pill(project.status.style)
                    if let day = project.targetDay {
                        Text(day, format: .dateTime.month(.abbreviated).day()).font(.fabrix(.monoCaption)).foregroundStyle(Palette.steel)
                    }
                    Text("^[\(project.repositories.count) repository](inflect: true)", bundle: .module)
                        .font(.caption).foregroundStyle(Palette.muted)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

struct LeadLabel: View {
    let lead: ProjectLead

    var body: some View {
        switch lead {
        case let .agent(agent):
            HStack(spacing: 6) {
                AvatarBadge(agent.initials, size: 20)
                Text(agent.name)
            }
            .font(.caption)
            .foregroundStyle(Palette.steel)
            .accessibilityLabel(.features("Lead \(agent.name)"))
        case .outsideCompany:
            Label(.features("Lead outside this company"), systemImage: "person.crop.circle.badge.questionmark")
                .font(.caption)
                .foregroundStyle(Palette.muted)
        case .former:
            Label(.features("Former agent"), systemImage: "person.crop.circle.badge.xmark")
                .font(.caption)
                .foregroundStyle(Palette.muted)
        case .none:
            Text("No lead", bundle: .module).font(.caption).foregroundStyle(Palette.muted)
        }
    }
}

/// Counts come from the newest company tasks Fabrix loads; say when the server knows of more.
struct UnloadedTasksNote: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("^[\(count) older task](inflect: true) not loaded, so not counted", bundle: .module)
                .font(.caption)
                .foregroundStyle(Palette.muted)
        }
    }
}
