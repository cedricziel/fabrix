## ADDED Requirements

### Requirement: Projects in navigation

The app SHALL let the user reach the selected company's projects without a new top-level tab. Projects SHALL sit under the company: the sidebar keeps at most two levels, and nothing is nested under a project in the sidebar.

#### Scenario: Regular width

- **WHEN** the app runs at regular width and the factory supports projects
- **THEN** the sidebar shows a Projects group below the sections, with All projects and one row per active project showing its open count and, when there are any, its blocked count
- **AND** selecting a project row shows that project's detail

#### Scenario: Compact width

- **WHEN** the app runs at compact width and the factory supports projects
- **THEN** the tab bar still has four tabs, the Factory tab shows a Projects card with up to three active projects and a link to all of them, and its More menu offers Projects

#### Scenario: Company has no projects at regular width

- **WHEN** the selected company has no projects at regular width
- **THEN** the Projects group shows only All projects, which opens the empty projects screen
