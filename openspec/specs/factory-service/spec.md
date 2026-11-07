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
