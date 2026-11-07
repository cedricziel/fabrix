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

