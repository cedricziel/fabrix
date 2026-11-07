## Purpose

The overview of one company: how it is doing and what needs the user.

## ADDED Requirements

### Requirement: Company metrics

The overview SHALL show agents working out of total (with idle and paused counts), open tasks (with blocked and in-review counts), approvals waiting on the user (by kind) and spend this month against the company cap.

#### Scenario: Demo company

- **WHEN** the demo company is shown
- **THEN** it reads 4 of 7 agents working, 8 open tasks, 3 waiting and $412 of $1,000 spent

### Requirement: Live runs

The overview SHALL list running agents with their task and a timer that counts up every second.

#### Scenario: Elapsed time

- **WHEN** a run has been going for 12 minutes 4 seconds
- **THEN** its timer reads 12:04, and switches to hours (1:00:00) after an hour

### Requirement: Decisions and activity

The overview SHALL list approvals waiting on the user with Approve and Open, and the latest activity with a link to all of it.

#### Scenario: Approving from the overview

- **WHEN** the user taps Approve on the overview
- **THEN** the approval leaves the list and is staged with undo as on the Approvals screen

#### Scenario: Opening an approval

- **WHEN** the user taps Open
- **THEN** the Approvals screen is shown
