## Purpose

Task editing lets a board user create Paperclip tasks and change a task's status, priority, assignee and project from iPhone, iPad and Mac, with every change that can't be taken back held for an undo window.

## ADDED Requirements

### Requirement: Create a task

New task SHALL open a form with title (required `[D7]`), description, status, priority, assignee and project. Status SHALL default to Todo when an assignee is picked and Backlog without one, and priority to Medium. Create SHALL be disabled until the title has text. When the status is Todo or In progress and the assignee is an agent, the Create button SHALL say that the agent will be woken ("Create and wake {agent}") `[D23]`. Creating SHALL send one request with an idempotency key, so a retried create never makes two tasks. The new task SHALL appear on the board and open in its detail. A refused create SHALL keep the form, say what the server refused, and move focus to the first field the server named. New subtask SHALL open the same form with the parent set and shown.

#### Scenario: Compact width

- **WHEN** the user taps + in the Tasks toolbar on iPhone
- **THEN** the form opens as a sheet `[D14]`

#### Scenario: Regular width

- **WHEN** the user presses Command-N or chooses New task on iPad or Mac
- **THEN** the form opens as a sheet over the board

#### Scenario: Create succeeds

- **WHEN** the server answers `201` with the new task
- **THEN** the sheet closes, the task is on the board in its status column, and its detail opens

#### Scenario: Create retried after a lost answer

- **WHEN** the first create times out and the user taps Create again
- **THEN** the same idempotency key is sent and the server's existing task is shown, not a second one

#### Scenario: Server refuses the create

- **WHEN** the server answers `400` with details for a field
- **THEN** the form stays open, the field shows the server's message, and VoiceOver focus moves to it

#### Scenario: Create wakes an agent

- **WHEN** the user picks an agent as assignee and leaves the status at Todo
- **THEN** the button reads "Create and wake {agent}"

#### Scenario: Server cannot create tasks

- **WHEN** a create answers `404` "API route not found"
- **THEN** the form says this factory doesn't allow creating tasks from Fabrix and keeps the draft, and New task opens that explanation directly for the rest of the factory session

### Requirement: Edit task fields

The user SHALL change a task's status, priority, assignee and project from its detail. Assignee choices SHALL be the company's agents that aren't terminated or waiting for approval, Me when the signed-in user is known, and Unassigned `[D8]`. Project choices SHALL be the company's active projects and No project. Cancelled SHALL be offered in the status menu, not as a board column `[D19]`. A change SHALL show on the card and in the detail at once. Its result SHALL come from the server's answer, without a second read.

#### Scenario: Compact width

- **WHEN** the user taps the status pill or the assignee row on iPhone
- **THEN** a menu lists the choices with the current one checked

#### Scenario: Regular width

- **WHEN** the user clicks a field in the detail on iPad or Mac
- **THEN** a menu or popover lists the choices, and the same choices are in the card's context menu

#### Scenario: Server's answer differs

- **WHEN** the server answers with a state that differs from what the user picked, for example because an agent changed the task meanwhile
- **THEN** the card and detail show the server's state

### Requirement: Undo window for edits

Status and assignee changes SHALL be held for 8 seconds `[D1]` `[D2]` with an undo bar that says what changed, counts down in text and offers Undo and Send now. They SHALL be sent when the window ends, when the user taps Send now, when the app leaves the foreground, or before another factory or company opens. Undo SHALL also be available from Edit ▸ Undo (⌘Z) while the window runs. Priority and project changes SHALL be sent at once, and their undo bar SHALL send the old value back. A held change SHALL survive a refresh: the board keeps showing it until it is sent. A held change rejected because the user was signed out SHALL stay held until they sign in again. Task edits SHALL NOT ask for Face ID `[D17]`.

#### Scenario: Undo a move

- **WHEN** the user moves a task to Done and taps Undo within 8 seconds
- **THEN** nothing is sent and the task is back in its column

#### Scenario: Window ends

- **WHEN** the user moves a task to In review and does nothing
- **THEN** the change is sent after 8 seconds, and the bar says "Moved"

#### Scenario: Priority change

- **WHEN** the user sets priority to High and then taps Undo
- **THEN** High was sent at once, and Undo sends the old priority

#### Scenario: App goes to the background

- **WHEN** a status change is held and the app goes to the background
- **THEN** the change is sent before the app suspends

#### Scenario: Company switch during the window

- **WHEN** a status change is held and the user switches to another company
- **THEN** the change is sent for the original company before the new company shows

#### Scenario: Signed out during the window

- **WHEN** a held change can't be sent because the key was refused
- **THEN** the undo bar says it wasn't sent and to sign in again, and the change is sent after signing in to the same factory

#### Scenario: Refresh during the window

- **WHEN** a refresh arrives while a move is held
- **THEN** the card stays in its new column

### Requirement: Refused edits

When the server refuses an edit (`400`, `409` or `422`), the card and detail SHALL return to the server's state and SHALL say why in plain words, quoting the server's reason when it has one. When the edit fails because something it names is gone (`404`, such as "Project not found") or isn't allowed (`403`), the card and detail SHALL also return and say so. A refused edit SHALL NOT be retried. A transport failure SHALL return the card and offer Retry.

#### Scenario: In progress without an assignee

- **WHEN** the server answers `422` "in_progress issues require an assignee"
- **THEN** the card returns to its column and the app says the task needs an assignee before it can be in progress

#### Scenario: Assignee can't take work

- **WHEN** the server answers `409` "Cannot assign work to terminated agents"
- **THEN** the assignee returns to the previous one and the app shows the server's reason

#### Scenario: Unresolved blockers

- **WHEN** the server answers `422` "Issue is blocked by unresolved blockers"
- **THEN** the card returns and the app names the blocking tasks the answer lists

### Requirement: Drag and drop on the board

On iPad and Mac the user SHALL drag a card to another column to change its status. While dragging, each column SHALL say what a drop does. In progress SHALL refuse an unassigned task before anything is sent and say why. Blocked SHALL NOT be a drop target; the status menu offers it and the server decides `[D18]`. A drop SHALL follow the undo window. With Reduce Motion, a refused card SHALL fade back instead of flying, and a lifted card SHALL not tilt. Every drag result SHALL also be reachable without dragging.

#### Scenario: Regular width

- **WHEN** the user drags a card from Todo to In review on iPad or Mac
- **THEN** the card moves, and the undo bar shows "Moved to In review"

#### Scenario: Compact width

- **WHEN** the user long-presses a task on iPhone
- **THEN** a menu offers Move to each status, Assign, Set priority, Set project, Comment and New subtask, and there is no drag between sections

#### Scenario: Drop the server would refuse

- **WHEN** the user drags an unassigned task over In progress
- **THEN** the column says "Assign it first" and dropping does nothing

#### Scenario: Blocked column

- **WHEN** the user drags a card over Blocked
- **THEN** the column says Blocked is set from the status menu and dropping does nothing

#### Scenario: VoiceOver

- **WHEN** VoiceOver focuses a card
- **THEN** it reads identifier, title, status, priority, assignee and whether it is running as one element, and its actions include Move to each status, Assign, Set priority, Set project, Comment and Open in new window where available

#### Scenario: Offline

- **WHEN** the factory is offline
- **THEN** columns don't accept drops, menus show the edits disabled with the reason, and nothing is queued

### Requirement: Context menu and keyboard

Every card SHALL have a context menu with the same verbs as its VoiceOver actions. On macOS, and on iPadOS with a hardware keyboard, a Task menu SHALL offer New task (⌘N, replacing New Window on macOS), New subtask (⇧⌘N), Open in new window (⌥⌘O, macOS only), Comment (⌥⌘C), Plan history (⇧⌘H), Assign (⇧⌘A), Set project (⌃⌘P), status (⌃⌘1–7, in the order Backlog, Todo, In progress, In review, Blocked, Done, Cancelled) and priority (⌃⇧1–4, Critical to Low) `[D16]`. Undo inside the window SHALL come from Edit ▸ Undo (⌘Z), not from a Task menu item. No shortcut SHALL be bound twice across the Factory, Inbox and Task menus. A command SHALL be disabled when no task is selected or the factory doesn't allow it.

#### Scenario: Keyboard status change

- **WHEN** a task is selected on Mac and the user presses ⌃⌘6
- **THEN** the task moves to Done through the undo window

#### Scenario: Company switching keeps its keys

- **WHEN** the user presses ⌘2
- **THEN** the second company opens, as before

#### Scenario: New task on macOS

- **WHEN** the user presses ⌘N on Mac
- **THEN** the create form opens and no new window appears

### Requirement: Task in its own window

On macOS a task SHALL open in its own window from the context menu, the Task menu or ⌥⌘O. The window SHALL show the full detail with thread, documents, work products and runs, SHALL follow refreshes, and SHALL close itself with a note when the task's factory or company is no longer open.

#### Scenario: Open in new window

- **WHEN** the user chooses Open in new window on a card
- **THEN** a window titled with the task's identifier and title shows its detail, and the board stays as it was

#### Scenario: Factory switched

- **WHEN** the main window switches to another factory while a task window is open
- **THEN** the task window says the task belongs to a factory that is no longer open, and offers to close
