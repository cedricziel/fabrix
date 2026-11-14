## MODIFIED Requirements

### Requirement: Card detail per width

Selecting a card SHALL show it with its full content and the actions it allows, and with its task context: identifier, title, status, assignee and project, when the card belongs to a task. "Open task" SHALL open the task detail in Fabrix when the factory supports it, and the task in Paperclip otherwise.

#### Scenario: Compact width

- **WHEN** the user taps a card on iPhone
- **THEN** the card opens in its own screen with the decision buttons pinned at the bottom, and Back returns to the list

#### Scenario: Regular width

- **WHEN** the user selects a card on iPad or Mac
- **THEN** the list stays visible, and the card with its task context fills the detail area

#### Scenario: Decision buttons at accessibility sizes

- **WHEN** the text size is an accessibility size
- **THEN** the decision buttons appear after the card's content instead of pinned at the bottom

#### Scenario: Open task

- **WHEN** the user chooses Open task on a card that belongs to a task, on a factory with task detail
- **THEN** the task detail opens: pushed on iPhone, and in the Tasks section beside the board on iPad and Mac

#### Scenario: Open task without task detail

- **WHEN** the factory doesn't support task detail
- **THEN** Open task opens the task in Paperclip, as before
