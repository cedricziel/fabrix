# navigation Specification

## Purpose
How the user moves between a factory's sections on compact (iPhone) and regular (iPad, Mac) width.
## Requirements
### Requirement: Section navigation

The app SHALL let the user reach Overview, Tasks, Agents, Org chart, Approvals and Activity for the selected company.

#### Scenario: Regular width

- **WHEN** the app runs at regular width
- **THEN** a sidebar lists only the six sections of the selected company, and selecting a section shows it in the detail area

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

### Requirement: Factory and company switching

The navigation title SHALL show the selected company, with its factory where space allows, and its title menu SHALL let the user switch factory and company, add a factory, and remove the open one.

#### Scenario: Title menu contents

- **WHEN** the user opens the title menu
- **THEN** it lists every saved factory and the demo, the open factory's companies with a checkmark on the selected one, then "Add Factory…" and "Remove Factory…"

#### Scenario: Switching company

- **WHEN** the user picks another company of the open factory
- **THEN** that company's data is shown

#### Scenario: Switching factory

- **WHEN** the user picks another saved factory or the demo
- **THEN** it opens on its first company and reopens on the next launch

#### Scenario: Sidebar hidden

- **WHEN** the sidebar is hidden or the app runs at compact width
- **THEN** switching still works from the title menu

#### Scenario: Menu bar on macOS

- **WHEN** the app runs on macOS
- **THEN** a Factory menu in the menu bar offers the same commands as the title menu, and Command-1 to Command-9 select the open factory's first nine companies

### Requirement: Projects in navigation

The app SHALL let the user reach the selected company's projects without a new top-level tab. Projects SHALL sit under the company: the sidebar keeps at most two levels, and nothing is nested under a project in the sidebar.

#### Scenario: Regular width

- **WHEN** the app runs at regular width and the factory supports projects
- **THEN** the sidebar shows a Projects group below the sections, with All projects (badged with the number of active projects) and one row per active project showing its open count and, when there are any, its blocked count
- **AND** selecting a project row shows that project's detail

#### Scenario: Compact width

- **WHEN** the app runs at compact width and the factory supports projects
- **THEN** the tab bar still has four tabs, the Factory tab shows a Projects card with up to three active projects and a link to all of them, and its More menu offers Projects

#### Scenario: Company has no projects at regular width

- **WHEN** the selected company has no projects at regular width
- **THEN** the Projects group shows only All projects, which opens the empty projects screen

