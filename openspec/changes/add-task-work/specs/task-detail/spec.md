## Purpose

Task detail lets a board user read one Paperclip task in full on iPhone, iPad and Mac: what it is, where it sits, what its agent said and produced, which runs worked on it, and lets them steer the agent through the thread.

## ADDED Requirements

### Requirement: Task detail content

Opening a task SHALL show its identifier, title, status, priority, assignee, project, goal, labels, the description rendered as Markdown, its parent chain from the root down, the tasks that block it with their status, and the tasks it blocks. Parent chain entries and related tasks SHALL open that task's detail. Description, labels, goal, parent and blockers SHALL be read-only `[D11]`. While the detail loads for the first time, static placeholders SHALL show where its parts will be.

#### Scenario: Compact width

- **WHEN** the user taps a task on iPhone
- **THEN** the detail pushes onto the navigation stack, with a Comment button pinned at the bottom

#### Scenario: Regular width

- **WHEN** the user selects a card on iPad or Mac
- **THEN** the detail opens beside the board and the board stays visible

#### Scenario: Parent chain

- **WHEN** a task has a parent, which has a parent of its own
- **THEN** the chain shows the root first and the direct parent last, and more than three ancestors collapse into "…"

#### Scenario: Blocked task

- **WHEN** a task is blocked by a task that isn't done
- **THEN** the blocker is listed with its identifier, title and status, and is marked as unresolved in text

#### Scenario: Task removed meanwhile

- **WHEN** the server answers `404` "Issue not found" for an open task
- **THEN** the detail says the task was deleted or moved and offers a way back

#### Scenario: Detail fails to load

- **WHEN** the detail request fails for another reason
- **THEN** the detail shows the board's copy of the task with an error and Retry, and the rest of the app stays usable

### Requirement: Task thread

The detail SHALL show the task's comments, oldest first, each with its author (an agent's name, "You", a person's name or "Board member" `[D21]`, or "System"), its time, and its body rendered as Markdown. It SHALL load the newest 100 comments and, when there are more, link to the full thread in Paperclip `[D22]`. Refreshing the detail SHALL add new comments without reloading the old ones.

#### Scenario: Agent comment

- **WHEN** an agent posted a comment
- **THEN** the thread shows the agent's name and avatar initials, and the body as Markdown

#### Scenario: Own comment

- **WHEN** the signed-in board user posted a comment
- **THEN** its author reads "You"

#### Scenario: More than 100 comments

- **WHEN** the task has more comments than were loaded
- **THEN** the top of the thread says earlier comments are in Paperclip and offers to open the task there

### Requirement: Comment composer

The composer SHALL name who will read the comment (the assignee, or "the board" when unassigned) and SHALL be reachable in one tap from anywhere in the detail. Sending SHALL post the comment at once `[D6]`, show it as sending, and keep its text with Retry when posting fails. The composer SHALL be disabled with a reason while the factory is offline or the user is signed out. Unsent text SHALL survive leaving and reopening the task while the app runs `[D13]`. Fabrix SHALL NOT offer to interrupt the active run `[D4]`.

#### Scenario: Compact width

- **WHEN** the user taps Comment on iPhone
- **THEN** the composer opens with the keyboard, above the thread

#### Scenario: Regular width

- **WHEN** the detail shows on iPad or Mac
- **THEN** the composer sits at the bottom of the thread, always visible

#### Scenario: Comment fails

- **WHEN** posting a comment fails
- **THEN** the comment stays in the thread marked as not sent, with Retry, Edit and Delete draft, and nothing is retried on its own

#### Scenario: Retrying a comment

- **WHEN** the user taps Retry
- **THEN** the comment is sent again with the same client request ID, so the server never stores it twice

#### Scenario: Commenting on a closed task

- **WHEN** the task is Done, Cancelled, or Blocked with no unresolved blocker, is assigned to an agent, and the user taps Send
- **THEN** the app says "Sending reopens this task and wakes {agent}" and sends only after the user confirms `[D5]`

### Requirement: Task documents

The detail SHALL list the task's documents, the plan first, each with its title, revision number, author and age. Opening a document SHALL show its body as rendered Markdown, read-only. A plan kept in the task's description SHALL show as the plan. System documents SHALL be hidden. A document's history SHALL list its revisions newest first, with number, author, time and change summary, and opening an older revision SHALL show it with a banner that names it and offers the current one.

#### Scenario: Compact width

- **WHEN** the user opens a document on iPhone
- **THEN** it pushes onto the stack, with History in the toolbar

#### Scenario: Regular width

- **WHEN** the user opens a document on iPad or Mac
- **THEN** it replaces the detail column with a back button, and History opens beside it as a list

#### Scenario: Older revision

- **WHEN** the user opens revision 2 of 4
- **THEN** the banner reads "Revision 2 of 4" with its date, and "Show current" returns to revision 4

#### Scenario: Images in a document

- **WHEN** a document contains an image
- **THEN** it shows as a link to the image, not as the image `[D12]`

### Requirement: Work products

The detail SHALL list the task's work products, the primary one first, each with its type, title, status and host, and a sign of how it opens. A work product with an `http` or `https` link SHALL open in the browser. A file that Paperclip stores SHALL be downloaded through the factory connection and shown in Quick Look `[D20]`. A work product with neither SHALL show without an action. An unhealthy one SHALL say so in text.

#### Scenario: Pull request

- **WHEN** the user opens a pull request work product
- **THEN** its link opens in the browser

#### Scenario: Stored file

- **WHEN** the user opens an artifact that Paperclip stores
- **THEN** the app downloads it with the factory's credentials and shows it in Quick Look, and shows the download's progress and any failure

### Requirement: Runs on a task

The detail SHALL show the task's live run on top with its agent and elapsed time, then its queued runs, then the finished runs of this task among the company's recent runs, each with agent, outcome and duration. When finished runs may be missing, the list SHALL say that older runs aren't shown `[D3]`.

#### Scenario: Live run

- **WHEN** an agent is running the task
- **THEN** its run is first, marked live, with a timer

#### Scenario: Nothing running

- **WHEN** the active-run request answers `null` and no run is queued
- **THEN** no live run is shown, and the finished runs follow

### Requirement: Detail parts follow the server

Each part of the detail SHALL load and fail on its own. When the factory doesn't support a part (comments, documents, revisions, work products or runs), that part SHALL be hidden without an error, and SHALL NOT be asked for again until another factory opens. When the task detail itself is unsupported, opening a task SHALL show the board's copy of the task as today.

#### Scenario: Server without work products

- **WHEN** the work products request answers `404` "API route not found"
- **THEN** the detail has no work products section and shows no error

#### Scenario: Comments fail, the rest loads

- **WHEN** the comments request fails with a server error
- **THEN** the thread shows the error with Retry, and documents, work products and runs still show

### Requirement: Task detail accessibility

The detail SHALL work with VoiceOver, Dynamic Type and Reduce Motion. Status SHALL show a dot shape and a word, priority bars and a word. At accessibility text sizes, field rows SHALL put the label above the value, and the composer's send arrow SHALL become a labelled Send button. With Reduce Motion, placeholders SHALL not shimmer and new comments SHALL fade in.

#### Scenario: VoiceOver on a comment

- **WHEN** VoiceOver focuses a comment
- **THEN** it reads the author, the time and the text as one element

#### Scenario: Accessibility text size on iPhone

- **WHEN** the text size is an accessibility size on iPhone
- **THEN** field labels sit above their values and Send is a labelled button
