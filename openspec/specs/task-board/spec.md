# task-board Specification

## Purpose
Seeing a company's tasks grouped by where they are in the workflow.
## Requirements
### Requirement: Tasks by status

The app SHALL group tasks by status in the order Backlog, Todo, In progress, In review, Blocked, Done, newest first within a group, and hide cancelled tasks.

#### Scenario: Regular width

- **WHEN** Tasks is shown at regular width
- **THEN** every status is a column, even when empty, and selecting a card shows its details beside the board

#### Scenario: Compact width

- **WHEN** Tasks is shown at compact width
- **THEN** a list shows one section per status that has tasks, and tapping a task opens its details

### Requirement: Task details

Task details SHALL show the assignee, last update, whether a run is in progress, and offer Wake agent when the assignee is not running.

#### Scenario: Running task

- **WHEN** a task has a live run
- **THEN** its card is marked running and its details show the elapsed time

### Requirement: Project filter

The task board SHALL offer a project filter with All projects, each of the company's projects, and No project. A filtered board SHALL show only the matching tasks and SHALL show the active filter with a way to clear it. While the board shows all projects, each task that belongs to a project SHALL show a project chip with the project's name and colour. Switching company SHALL reset the filter to All projects.

#### Scenario: Regular width

- **WHEN** the user filters the board to one project at regular width
- **THEN** every column shows only that project's tasks, the toolbar shows the project as the active filter, and a token above the board clears it

#### Scenario: Compact width

- **WHEN** the user filters the task list to one project at compact width
- **THEN** only that project's tasks are listed and a token under the title clears the filter

#### Scenario: Tasks without a project

- **WHEN** the user picks No project
- **THEN** only tasks that belong to no project are shown

#### Scenario: Project chip

- **WHEN** the board shows all projects
- **THEN** each task in a project shows that project's chip, and tasks without a project show none
- **AND** when the board is filtered to one project, no chips are shown

#### Scenario: Opening a project from the board

- **WHEN** the board is filtered to one project
- **THEN** it offers a way to open that project's detail

#### Scenario: Filtered project goes away

- **WHEN** the board is filtered to a project that a refresh no longer contains
- **THEN** the board shows all projects

#### Scenario: Filter after company switch

- **WHEN** the user switches company while the board is filtered to a project
- **THEN** the board shows all projects of the new company

