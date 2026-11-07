## MODIFIED Requirements

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

## ADDED Requirements

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
