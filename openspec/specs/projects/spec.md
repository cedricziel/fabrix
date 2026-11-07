# projects Specification

## Purpose
Seeing a company's Paperclip projects: which exist, how far along each one is, who leads it, and what is happening in it. Projects are read-only in Fabrix and always belong to the selected company.
## Requirements
### Requirement: Projects list

The app SHALL list the selected company's projects that are not archived. Each project SHALL show its name, colour, status, lead, open, blocked and done task counts, target date and number of linked repositories. Projects with status completed or cancelled SHALL be listed separately from active ones.

#### Scenario: Regular width

- **WHEN** the user opens All projects at regular width
- **THEN** a list shows each active project with its status, lead, task counts, target date and repository count
- **AND** a Completed choice shows the completed and cancelled projects instead

#### Scenario: Compact width

- **WHEN** the user opens Projects at compact width
- **THEN** a list shows each active project with its status, task counts and lead, and a Completed choice shows the completed and cancelled ones

#### Scenario: Archived projects

- **WHEN** a project is archived in Paperclip
- **THEN** it appears in neither list

### Requirement: Task counts per project

The app SHALL count a project's tasks from the company's tasks. Open SHALL count backlog, todo, in progress and in review tasks; blocked SHALL count blocked tasks; done SHALL count done tasks. Cancelled tasks SHALL NOT be counted.

#### Scenario: Mixed statuses

- **WHEN** a project has two todo, one in-review, one blocked, three done and one cancelled task
- **THEN** it shows 3 open, 1 blocked and 3 done

#### Scenario: More tasks than were loaded

- **WHEN** the server counts more tasks in a project than the loaded company tasks contain
- **THEN** the counts say how many older tasks weren't loaded and aren't counted

#### Scenario: Task without a project

- **WHEN** a task belongs to no project
- **THEN** it counts toward no project

### Requirement: Project detail

The app SHALL show a project's status, description, lead, goals, target date, task counts, its tasks grouped by status, its linked repositories and its recent activity. Recent activity SHALL contain events about the project itself and events about its tasks, newest first.

#### Scenario: Opening a project

- **WHEN** the user opens a project
- **THEN** its details show the project's tasks by status, its repositories and its recent activity

#### Scenario: Repository kinds

- **WHEN** a project has a Git repository and a local folder linked
- **THEN** the repository shows its owner and name and opens its URL, and the folder shows its path and opens nothing

#### Scenario: Project without repositories

- **WHEN** a project has no linked repository
- **THEN** the repositories area says that none is linked

#### Scenario: Open project disappears

- **WHEN** a refresh no longer contains the open project
- **THEN** the detail says the project is gone and offers a way back to the projects list

### Requirement: Lead from another company

When a project's lead is not one of the selected company's agents, the app SHALL show that the lead is outside this company, or that it is a former agent when the company terminated it, and SHALL NOT offer agent actions such as wake or pause for it. A project without a lead SHALL show no lead.

#### Scenario: Lead is another company's agent

- **WHEN** a project's lead agent is not among the company's agents
- **THEN** the lead is shown as outside this company, without a link to an agent and without wake or pause

#### Scenario: Lead was terminated

- **WHEN** a project's lead is one of the company's terminated agents
- **THEN** the lead is shown as a former agent, without wake or pause

### Requirement: Projects states

Projects SHALL load beside the company, not as part of it. While the first load runs, the Projects area SHALL show placeholders. When a company has no projects, the Projects area SHALL say so. When loading projects fails, only the Projects area SHALL show the error with a way to retry, and the rest of the company SHALL stay usable. When the factory does not support projects, the app SHALL hide projects, the project filter and project chips without showing an error, SHALL leave a projects screen that is open, and SHALL NOT ask that factory again until another factory is opened. When switching company fails, the projects of the company still shown SHALL load again.

#### Scenario: First load

- **WHEN** projects have not loaded yet for the selected company
- **THEN** the Projects area shows placeholders, and later refreshes keep the last list without placeholders

#### Scenario: No projects

- **WHEN** the selected company has no projects
- **THEN** the Projects area says there are no projects and that they are created in Paperclip

#### Scenario: Projects request fails

- **WHEN** the projects request fails while the company loads
- **THEN** the Projects area shows the error and Retry, and overview, tasks, agents and approvals still show
- **AND** when an earlier list is still shown, the error says the projects didn't refresh

#### Scenario: Factory without projects

- **WHEN** the factory reports that it does not support projects
- **THEN** no Projects entry, project filter or project chip is shown, and no error is shown
- **AND** an open projects screen gives way to the overview

### Requirement: Projects follow the selected company

Projects SHALL always belong to the company selected in the title menu. Switching company SHALL replace the projects with the new company's and SHALL leave any open project.

#### Scenario: Switching company with a project open

- **WHEN** the user switches to another company while a project is open
- **THEN** the projects list of the new company is shown and the previous project is no longer open

