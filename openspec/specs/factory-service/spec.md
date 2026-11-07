# factory-service Specification

## Purpose

`FactoryService` is the only seam between the UI and a Paperclip factory. A demo implementation with the design's sample company lets the app run without a server.
## Requirements
### Requirement: Company snapshot

The service SHALL list companies and return a snapshot of one company with its agents, tasks, approvals, runs, activity and monthly spend.

#### Scenario: Pending approvals and live runs are derived

- **WHEN** a snapshot contains approvals in several states and runs with and without a finish time
- **THEN** `pendingApprovals` contains only approvals in the pending state
- **AND** `liveRuns` contains only runs without a finish time

### Requirement: Decide approvals

The service SHALL approve or reject a pending approval by ID.

#### Scenario: Approving removes the approval from pending

- **WHEN** the user approves a pending approval
- **THEN** the next snapshot shows that approval as approved and no longer pending

### Requirement: Control agents

The service SHALL wake and pause agents by ID, and pause or resume a whole company.

#### Scenario: Pausing a running agent

- **WHEN** the user pauses a running agent
- **THEN** the next snapshot shows the agent as paused

### Requirement: Demo factory

The app SHALL ship an in-memory demo factory with the sample company "Atlas" from the design, used for previews, tests and exploring without a server.

#### Scenario: Demo has data on first load

- **WHEN** the demo factory is asked for companies
- **THEN** it returns "Atlas" with agents, open tasks, pending approvals and live runs

### Requirement: Live Paperclip factory

The app SHALL provide a factory service backed by a Paperclip server. It SHALL list the companies the board user can open, and SHALL build a company snapshot from the server's companies, agents, issues, pending approvals, heartbeat runs and activity.

#### Scenario: Snapshot from a live server

- **WHEN** the app loads a company from a Paperclip server
- **THEN** the snapshot contains its agents without terminated ones, its issues as tasks, its pending approvals, its recent runs and its recent activity
- **AND** monthly spend and budget come from the company, with a zero budget shown as no budget

#### Scenario: Approval changes status while the snapshot loads

- **WHEN** an approval moves from `pending` to `revision_requested` between the two approval requests, so both answers contain it
- **THEN** the snapshot lists it once, as the copy the server updated most recently

#### Scenario: Unknown agent or issue status from a newer server

- **WHEN** the server sends an agent or issue status this version of Fabrix does not know
- **THEN** the snapshot still loads, with the agent shown as idle or the issue as backlog

#### Scenario: Unknown approval type

- **WHEN** the server sends an approval type this version of Fabrix does not know
- **THEN** the approval's kind is other, and its state still follows its status

#### Scenario: Unknown approval status

- **WHEN** the server sends an approval status this version of Fabrix does not know
- **THEN** the approval's state is pending, and its kind still follows its type

### Requirement: Paperclip status mapping

The live factory SHALL map Paperclip agent statuses `pending_approval` to needs-you, `active` and `idle` to idle, and `running`, `paused` and `error` to themselves. Approval types `hire_agent`, `approve_ceo_strategy` and `budget_override_required` SHALL map to hire, strategy and budget. Approvals in `revision_requested` SHALL count as pending, and `cancelled` approvals as rejected. A run SHALL be live while its status is `queued`, `scheduled_retry` or `running`.

#### Scenario: Agent waiting for approval

- **WHEN** an agent has the Paperclip status `pending_approval`
- **THEN** it appears as needing the user

#### Scenario: Failed run without a finish time

- **WHEN** a run has the status `failed` and no finish time
- **THEN** it is not shown as live

### Requirement: Waking a paused agent

Waking an agent on a live factory SHALL resume it first if it is paused, then request a manual heartbeat.

#### Scenario: Wake paused agent

- **WHEN** the user wakes a paused agent
- **THEN** the agent is resumed and a manual heartbeat is requested, in that order

### Requirement: Hidden run telemetry

When the server refuses run telemetry to the board user, the snapshot SHALL load without runs instead of failing.

#### Scenario: Runs forbidden

- **WHEN** the heartbeat-runs request returns `403`
- **THEN** the snapshot loads with an empty run list and all other sections filled

### Requirement: Board key expiry

The live factory SHALL report when the board key it uses expires, from the key's record on the server. It SHALL report no expiry when the server doesn't say, or when the factory uses no board key.

#### Scenario: Key with an expiry

- **WHEN** the factory's board key expires on a known date
- **THEN** the service reports that date

#### Scenario: Unknown expiry

- **WHEN** the key list is unavailable or the key has no expiry
- **THEN** the service reports no expiry and the app relies on the server rejecting the key

### Requirement: Company projects

The service SHALL list a company's projects that are not archived, with each project's name, description, status, lead agent, target date, colour, goals, linked repositories and archived flag. Project statuses `backlog`, `planned`, `in_progress`, `completed` and `cancelled` SHALL map to backlog, planned, in progress, completed and cancelled; an unknown status SHALL map to other, which does not count as active. A malformed project or repository row SHALL be skipped without failing the list. Only `http` and `https` repository URLs SHALL be kept as links. The service SHALL pass on the server's count of a project's tasks when the server sends one. When the factory has no projects endpoint, the service SHALL report projects as unsupported instead of returning an error.

#### Scenario: Projects from a live server

- **WHEN** the app lists the projects of a company on a Paperclip server
- **THEN** each project comes back with its status, lead, target date, colour, goals and repositories, and archived projects are left out

#### Scenario: Repositories from workspaces

- **WHEN** a project has a Git workspace with a repository URL and a default branch, and a local folder workspace
- **THEN** the project lists a repository with that URL, its owner and name and its branch, and a folder with its path, with the primary one marked

#### Scenario: Unknown project status

- **WHEN** the server sends a project status this version of Fabrix does not know
- **THEN** the project still loads, with the status other, and is not listed as active

#### Scenario: Malformed project row

- **WHEN** one row of the projects list can't be read
- **THEN** the other projects still load

#### Scenario: Repository URL that isn't a web link

- **WHEN** a Git workspace's repository URL uses a scheme other than `http` or `https`
- **THEN** the repository is listed without a link

#### Scenario: Server without projects

- **WHEN** the projects list request returns `404`
- **THEN** the service reports projects as unsupported

### Requirement: Task project and activity subject

Each task SHALL carry the project it belongs to, or none. Each activity event SHALL carry the task or project it is about, when it is about one. The snapshot SHALL name the company's terminated agents, which it otherwise leaves out.

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

