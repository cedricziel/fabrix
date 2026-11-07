## ADDED Requirements

### Requirement: Live Paperclip factory

The app SHALL provide a factory service backed by a Paperclip server. It SHALL list the companies the board user can open, and SHALL build a company snapshot from the server's companies, agents, issues, pending approvals, heartbeat runs and activity.

#### Scenario: Snapshot from a live server

- **WHEN** the app loads a company from a Paperclip server
- **THEN** the snapshot contains its agents without terminated ones, its issues as tasks, its pending approvals, its recent runs and its recent activity
- **AND** monthly spend and budget come from the company, with a zero budget shown as no budget

#### Scenario: Unknown status from a newer server

- **WHEN** the server sends an agent status, issue status, approval type or approval status this version of Fabrix does not know
- **THEN** the snapshot still loads
- **AND** the agent is shown as idle, the issue as backlog, the approval's kind as other, and its state as pending

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
