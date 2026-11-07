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
                Picker("Show", selection: $showsCompleted) {
                    Text("Active · \(board.active.count)").tag(false)
                    Text("Completed · \(board.completed.count)").tag(true)
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
                        ProjectRow(project: ProjectsView.placeholder, counts: TaskCounts(open: 3), lead: .none, isCompact: isCompact)
                    }
                    .redacted(reason: .placeholder)
                    .accessibilityLabel("Loading projects")
                } else {
                    ForEach(shown) { project in
                        Button { navigator.open(project: project.id) } label: {
                            ProjectRow(project: project, counts: board.counts(for: project.id), lead: board.lead(of: project), isCompact: isCompact)
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
                    Text("Projects group tasks and repositories. Create one in Paperclip and it shows up here on the next refresh.")
                }
            }
        }
        .navigationTitle("Projects")
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
                Text("Projects didn't load").fontWeight(.semibold)
                Text(message).font(.caption)
            }
            Spacer()
            Button("Retry") { Task { await model.retryProjects() } }
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
    let lead: ProjectLead
    let isCompact: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProjectSwatch(colorHex: project.colorHex, size: 12).padding(.top, 4)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(project.name).font(.fabrix(.headline))
                    if isCompact { ProjectStatusPill(project.status.style) }
                }
                if let goal = project.goals.first {
                    Text(goal).font(.caption).foregroundStyle(Palette.muted).lineLimit(1)
                }
                TaskCountsBar(open: counts.open, blocked: counts.blocked, done: counts.done)
                    .frame(maxWidth: 320, alignment: .leading)
                LeadLabel(lead: lead)
            }
            Spacer(minLength: 12)
            if !isCompact {
                VStack(alignment: .trailing, spacing: 6) {
                    ProjectStatusPill(project.status.style)
                    if let day = project.targetDay {
                        Text(day, format: .dateTime.month(.abbreviated).day()).font(.fabrix(.monoCaption)).foregroundStyle(Palette.steel)
                    }
                    Text("^[\(project.repositories.count) repository](inflect: true)")
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
            .accessibilityLabel("Lead \(agent.name)")
        case .outsideCompany:
            Label("Lead outside this company", systemImage: "person.crop.circle.badge.questionmark")
                .font(.caption)
                .foregroundStyle(Palette.muted)
        case .none:
            Text("No lead").font(.caption).foregroundStyle(Palette.muted)
        }
    }
}
