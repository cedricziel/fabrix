## MODIFIED Requirements

### Requirement: Tasks by status

The app SHALL group tasks by status in the order Backlog, Todo, In progress, In review, Blocked, Done, newest first within a group, and hide cancelled tasks `[D19]`. Each card SHALL show its identifier, title, priority (bars and, where there is room, the word), project chip, assignee and whether it is running. A task with a held or just-sent change SHALL show in its new column.

#### Scenario: Regular width

- **WHEN** Tasks is shown at regular width
- **THEN** every status is a column, even when empty, selecting a card shows its task detail beside the board, and cards can be dragged between columns

#### Scenario: Compact width

- **WHEN** Tasks is shown at compact width
- **THEN** a list shows one section per status that has tasks, and tapping a task pushes its task detail

#### Scenario: Priority on a card

- **WHEN** a task's priority is Critical
- **THEN** its card shows four filled bars, and VoiceOver reads "Critical priority"

#### Scenario: Unknown priority from a newer server

- **WHEN** the server sends a priority this version of Fabrix doesn't know
- **THEN** the task still loads with priority Medium

### Requirement: Task details

Selecting a task on the board SHALL open the task detail described in the `task-detail` capability. When the factory doesn't support task detail, the board SHALL show the task's assignee, last update, whether a run is in progress, and Wake agent when the assignee isn't running, as before.

#### Scenario: Running task

- **WHEN** a task has a live run
- **THEN** its card is marked running and its details show the elapsed time

#### Scenario: Wake from the detail

- **WHEN** a task's assignee isn't running
- **THEN** the detail still offers Wake agent and Open agent
