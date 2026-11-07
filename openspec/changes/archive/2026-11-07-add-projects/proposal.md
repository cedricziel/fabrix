## Why

Paperclip groups a company's tasks into projects, each with a lead agent, a status, a target date and linked repositories. Fabrix shows tasks only as one flat company board, so the board user can't see how a project is doing or narrow the board to one project. The design canvas now has a Projects row (version 18) that shows how projects fit the company facet on every platform.

## What Changes

- A read-only `Project` model in FabrixCore: name, description, status, lead agent, target date, colour, goals, linked repositories and archived flag. Tasks carry the project they belong to, and activity events carry the task or project they are about.
- `FactoryService` gains `projects(companyID:)`. The demo factory ships sample projects for Atlas. The live factory reads `GET /api/companies/{id}/projects` and maps the project's workspaces to repositories. A server without the endpoint reports projects as unsupported instead of failing.
- Projects load beside the company snapshot. A failed projects request marks only the Projects area as failed; the rest of the company stays usable. Projects never cross companies: switching company swaps the list and resets any project selection or filter.
- Regular width (iPad, Mac): a Projects sidebar group under the sections, with All projects and one row per active project (open count, blocked count). All projects lists every project with its status, lead, task counts, target date and repository count, split into Active and Completed.
- Compact width (iPhone): no new tab. The Factory tab gains a Projects card and a Projects entry in its More menu.
- Project detail on every platform: status, lead, goal, target date, open/blocked/done counts, the project's tasks by status, its repositories and its recent activity.
- Tasks gain a project filter (All projects, one project, No project). While the board spans several projects, each task shows a project chip.
- A lead agent from another company, which Paperclip allows, is shown as a read-only reference without agent actions.

Out of scope: creating, editing or archiving projects; linking repositories; a cross-company project view; pre-filling New task with a project.

Platforms: macOS, iPadOS and iOS. Targets: FabrixCore, FabrixDesign and FabrixFeatures. The `FactoryService` change is additive: one new method, and new optional fields on `WorkItem` and `ActivityEvent` with `nil` defaults.

## Capabilities

### New Capabilities

- `projects`: listing a company's projects, project detail, project task counts, loading/empty/error/unsupported states, the company scope, and the lead from another company.

### Modified Capabilities

- `factory-service`: the service lists a company's projects, tasks carry their project, activity carries its subject, and the demo factory has projects.
- `navigation`: the Projects sidebar group at regular width, the Projects card and More entry in the Factory tab at compact width, and resetting project state on company switch.
- `task-board`: the project filter and the project chip on tasks.

## Impact

- `FabrixCore`: new `Project`, `ProjectStatus`, `ProjectRepository`, `FactoryServiceError.unsupported`; `WorkItem.projectID`; `ActivityEvent.taskID` and `projectID`; `PaperclipFactoryService.projects(companyID:)`, `ProjectDTO` and its mapping; demo projects in `DemoFactoryService`; a sandbox contract test.
- `FabrixDesign`: `ProjectSwatch`, `ProjectChip`, `ProjectStatusPill`, `TaskCountsBar` (proposed on the canvas).
- `FabrixFeatures`: `AppModel` loads and holds project state and the task project filter; new projects list and detail screens; sidebar and Factory tab entries; Tasks filter and chip.
- `docs/paperclip-api.md`: a Projects section.
- Test doubles that conform to `FactoryService` need the new method.
