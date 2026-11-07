## ADDED Requirements

### Requirement: Company projects

The service SHALL list a company's projects that are not archived, with each project's name, description, status, lead agent, target date, colour, goals, linked repositories and archived flag. Project statuses `backlog`, `planned`, `in_progress`, `completed` and `cancelled` SHALL map to backlog, planned, in progress, completed and cancelled; an unknown status SHALL map to backlog. When the factory has no projects endpoint, the service SHALL report projects as unsupported instead of returning an error.

#### Scenario: Projects from a live server

- **WHEN** the app lists the projects of a company on a Paperclip server
- **THEN** each project comes back with its status, lead, target date, colour, goals and repositories, and archived projects are left out

#### Scenario: Repositories from workspaces

- **WHEN** a project has a Git workspace with a repository URL and a default branch, and a local folder workspace
- **THEN** the project lists a repository with that URL, its owner and name and its branch, and a folder with its path, with the primary one marked

#### Scenario: Unknown project status

- **WHEN** the server sends a project status this version of Fabrix does not know
- **THEN** the project still loads, with the status backlog

#### Scenario: Server without projects

- **WHEN** the projects list request returns `404`
- **THEN** the service reports projects as unsupported

### Requirement: Task project and activity subject

Each task SHALL carry the project it belongs to, or none. Each activity event SHALL carry the task or project it is about, when it is about one.

#### Scenario: Task in a project

- **WHEN** an issue on the server has a project
- **THEN** its task carries that project

#### Scenario: Activity about a task

- **WHEN** an activity event is about an issue
- **THEN** the event carries that task

#### Scenario: Activity about a project

- **WHEN** an activity event is about a project
- **THEN** the event carries that project

### Requirement: Demo projects

The demo factory SHALL include projects for Atlas: some active with tasks in several statuses, at least one with a blocked task, one with a lead from the company, one without a lead, one without repositories, and one completed project.

#### Scenario: Demo projects on first load

- **WHEN** the demo factory is asked for Atlas's projects
- **THEN** it returns active and completed projects, and some Atlas tasks belong to them
