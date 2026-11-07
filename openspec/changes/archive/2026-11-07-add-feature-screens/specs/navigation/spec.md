## Purpose

How the user moves between a factory's sections on compact (iPhone) and regular (iPad, Mac) width.

## ADDED Requirements

### Requirement: Section navigation

The app SHALL let the user reach Overview, Tasks, Agents, Org chart, Approvals and Activity for the selected company.

#### Scenario: Regular width

- **WHEN** the app runs at regular width
- **THEN** a sidebar lists the factory, its companies and the six sections, and selecting a section shows it in the detail area

#### Scenario: Compact width

- **WHEN** the app runs at compact width
- **THEN** four tabs are shown: Factory, Tasks, Approvals and Agents, and Org chart and Activity open inside the Factory tab

#### Scenario: Approvals badge

- **WHEN** approvals are waiting on the user
- **THEN** the Approvals sidebar row (regular) or tab (compact) shows the number waiting

### Requirement: Company actions

The app SHALL offer Pause company (or Resume company when paused) and New task from the toolbar.

#### Scenario: Pausing a company

- **WHEN** the user chooses Pause company
- **THEN** the factory is asked to pause the company and the overview shows it as paused

#### Scenario: New task before the service supports it

- **WHEN** the user chooses New task
- **THEN** a sheet explains that creating tasks arrives in a later build and offers no way to submit

### Requirement: Search

The app SHALL filter tasks by identifier, title or assignee name, and agents by name, as the user types.

#### Scenario: Searching tasks

- **WHEN** the user searches for "atl-14"
- **THEN** only tasks whose identifier, title or assignee contains it are shown

### Requirement: Freshness

The app SHALL refresh the shown company while it is in the foreground and on pull to refresh.

#### Scenario: Periodic refresh

- **WHEN** the app is active and connected
- **THEN** it reloads the company about every 20 seconds and stops while in the background
