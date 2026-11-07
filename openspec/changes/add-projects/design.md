## Context

- `FactoryService` returns one `CompanySnapshot` per company: agents, tasks, approvals, runs, activity, spend. `AppModel` refreshes it about every 20 seconds and keeps one `LoadState` for the whole app.
- Paperclip (checked on the `/validate` sandbox, image `ghcr.io/paperclipai/paperclip:latest`, 2026-11-07):
  - `GET /api/companies/{id}/projects` leaves archived projects out unless `?includeArchived=true`. Rows carry `taskCount` (all tasks, done included) and `budget`.
  - `GET /api/projects/{id}` returns 404 `{"error":"Project not found"}` for an unknown id.
  - Issues carry `projectId`, and `?projectId=` filters them.
  - Repositories come back as `workspaces`: `sourceType` (`git_repo`, `local_path`, `remote_managed`, `non_git_path`), `repoUrl`, `defaultRef`, `cwd`, `isPrimary`.
  - Activity rows carry `entityType` and `entityId`; issue rows don't say which project they belong to.
  - Every project link is company-scoped except `leadAgentId`, which Paperclip accepts from another company.
- PRs #35/#37 (OpenSpec change `factory-title-menu`) move factory and company switching into a toolbar title menu, so the sidebar lists only sections. This change builds on that layout and is rebased onto it once it merges.
- Canvas: the Projects row and the company-facet note, version 18.

## Goals / Non-Goals

**Goals:**

- Read-only projects for the selected company on every platform, with counts, detail, a task filter and chips.
- A projects failure or an old server never breaks the rest of the company.
- `FactoryService` stays source-compatible for existing conformers.

**Non-Goals:**

- Creating, editing, archiving or deleting projects, or linking repositories.
- A cross-company projects view.
- Project budgets, private-project membership, workspaces' runtime services.
- Pre-filling New task with a project (the New task sheet doesn't create tasks yet).

## Decisions

### 1. A separate `projects(companyID:)` call, not a snapshot field

`FactoryService` gains `func projects(companyID: Company.ID) async throws -> [Project]`. A protocol extension gives it a default that throws `FactoryServiceError.unsupported`, so existing test doubles still compile.

- Alternative: add `projects` to `CompanySnapshot`. Rejected. The snapshot is all or nothing, and the design needs projects to fail on their own. The 403-on-runs pattern swallows errors silently, but projects must show their error.
- `PaperclipFactoryService` maps a `404` on the list request to `FactoryServiceError.unsupported`. Every other error passes through.

### 2. Model in FabrixCore

`FabrixCore/Models.swift` gains:

- `ProjectStatus`: `backlog`, `planned`, `inProgress`, `completed`, `cancelled`, with `isActive` true for the first three.
- `ProjectRepository`: `id`, `kind` (`.git`, `.folder`, `.other`), `name` (for example `atlas/mobile` or a folder path), `url: URL?` (only for `.git`), `ref: String?`, `isPrimary`.
- `Project`: `id`, `name`, `summary: String?`, `status`, `leadAgentID: String?`, `targetDate: DateComponents?`, `colorHex: String?`, `goals: [String]`, `repositories: [ProjectRepository]`, `isArchived`.
  - `targetDate` stays a calendar date, so no time-zone shift turns Dec 15 into Dec 14.
  - The hex colour is kept as a string. FabrixDesign parses it, so FabrixDesign still doesn't depend on FabrixCore.

Existing models gain fields:

- `WorkItem.projectID: String?`, default `nil`.
- `ActivityEvent.taskID: String?` and `projectID: String?`, default `nil`.

Mapping lives in `PaperclipMapping.swift`, and `ProjectDTO`/`ProjectWorkspaceDTO` live in `PaperclipDTOs.swift`.

- A workspace's repository name is the `owner/name` path of `repoUrl`, falling back to the workspace `name`.
- A `local_path` workspace uses `cwd`.
- An unknown project status maps to `.other`, which isn't active, so a server status like `on_hold` can't hide a finished project among active ones.
- Rows decode leniently: a malformed project or workspace is skipped, not fatal for the list.
- Repository links keep only `http`/`https` URLs.
- Activity with `entityType == "issue"` sets `taskID`, and `"project"` sets `projectID`.

### 3. Counts and project activity are computed in FabrixFeatures

`FabrixFeatures/Logic/ProjectBoard.swift` is a pure value built from `[Project]` and the snapshot.

- `counts(for:)` returns `TaskCounts(open, blocked, done)`. Open covers backlog, todo, in progress and in review. Cancelled tasks are ignored.
- `tasks(in:)` groups a project's tasks by status.
- `activity(for:)` returns events whose `projectID` matches, or whose `taskID` belongs to the project, newest first.
- It also gives active and completed lists and the lead resolution: `.agent(Agent)`, `.outsideCompany`, or `.none`.

Counts come from the snapshot's issues, which are capped at 500. The server's `taskCount` (every task, done and cancelled included) is kept on `Project`. When it exceeds the project's loaded tasks, the UI says how many older tasks weren't loaded and aren't counted, instead of a fetch per project. `CompanySnapshot.formerAgentIDs` lets a terminated lead show as a former agent rather than as another company's.

### 4. `AppModel` owns project state and the filter

- `projectsState: ProjectsState` holds `.loading`, `.loaded([Project])`, `.failed(String, last: [Project])` or `.unsupported`.
- `refresh()` starts `projects(companyID:)` in parallel with the snapshot (`async let`) when a company is already shown, under the same request generation, so a stale answer from the previous company is dropped.
- An `unsupported` answer is remembered for the open factory, so it isn't asked again on every poll.
- A failed company switch reloads the shown company's projects.
- A loaded list without the filtered project resets the task filter to `.all`.
- The first load for a company shows `.loading`. Later failures keep the last list in `.failed`.
- `taskProjectFilter: ProjectFilter` is `.all`, `.project(ID)` or `.none`.
- `select(_ company:)` resets the projects to `.loading`, the filter to `.all`, and the open project.
- `visibleTasks` applies the filter after search.
- If a refresh drops the open project, the detail shows the "gone" state.

### 5. Navigation

- Regular width: the sidebar selection becomes `SidebarItem` (`.section(AppSection)`, `.allProjects`, `.project(Project.ID)`). The Projects group sits below the sections and is hidden when projects are `.unsupported`. This is the one place the change touches `SplitShell`, so it must merge after #35.
- Compact width: `CompactTab.factory` gains `.projects` among its nested sections, so it shows in the More menu. `OverviewView` shows a Projects card at compact width. Project detail is a `navigationDestination(for: ProjectRoute.self)`.
- No fifth tab. The tab bar keeps a few top-level peers people switch between often, a project is a lens on tasks, and the iPhone's job is the pager.

### 6. Design components

`FabrixDesign` gains the proposed `ProjectSwatch`, `ProjectChip`, `TaskCountsBar` and a generic `FilterChip`. They take plain values (name, hex string, three integers), never Core types. Project statuses use the shared `Pill` through `Pill(_ project: ProjectStatusStyle)`: a design-side `ProjectStatusStyle` names the label and the `StatusStyle` whose dot and tone it borrows, and FabrixFeatures maps `ProjectStatus` onto it. The primary repository uses `KindTag(title:tone: .neutral)`. Projects copy resolves from the Features catalog (`.features(…)`, `bundle: .module`).

### 7. Lead from another company

`ProjectBoard` resolves the lead against `snapshot.agents`. If the lead isn't found, the UI shows "Lead outside this company" with no link and no actions. Fetching that agent's name through `GET /api/agents/{id}` would need a new service call for an edge case, so it is left out. The canvas mock shows the name; the code shows the neutral label.

## Risks / Trade-offs

- [Two requests per refresh] → Projects are one small request per 20 s, run in parallel with the snapshot, and only while the app is active.
- [Merge order with #35/#37] → The core and design groups don't touch the shell. Only the features group depends on the title-menu layout. The stack is rebased onto main once #35/#37 merge.
- [Paperclip's `projectId` filter isn't used] → Counts come from the 500-issue snapshot. A company with more than 500 issues undercounts, as the board already does today.
- [Archived projects' tasks] → Tasks of an archived project show no chip, because the project isn't loaded, and they appear only under All projects. That's acceptable for a read-only first version.
