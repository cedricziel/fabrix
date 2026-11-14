## ADDED Requirements

### Requirement: Attention feed

The service SHALL return a company's attention feed for one view (mine, unassigned or company): its cards, its receipts (mine only), the per-view counts when the server sends them, the count of cards for the user, and a cursor for the next page. Each card SHALL carry its source (kind and ID), card type, title, summary, requester, task, project, severity, stale reason, audience, the close modes the server allows, its change fingerprint and its web path. The service SHALL derive what the app can do with each card: answer it as an approval, confirmation, questions or verdicts, or open it in Paperclip. Unknown card types, source kinds and statuses SHALL decode without failing the feed. A malformed card SHALL be skipped. When the factory has no feed, the service SHALL report it as unsupported.

#### Scenario: Feed from a live server

- **WHEN** the app reads the For you view from a Paperclip server
- **THEN** the service requests `GET /api/companies/{id}/attention?view=mine&limit=100` and returns the cards, receipts, view counts and `deskBadgeCount`

#### Scenario: Server without the feed

- **WHEN** the feed request answers `404`
- **THEN** the service reports the feed as unsupported

#### Scenario: Feed without routing

- **WHEN** the feed has no `viewCounts`, `audience` or `closeModes`
- **THEN** the feed reports routing as unsupported, and no card allows closing, claiming or transferring

#### Scenario: Card the app answers in Paperclip

- **WHEN** a card's type is `join_request`, `make_choice`, `suggested_tasks` or a type this version doesn't know
- **THEN** the card is marked to open in Paperclip `[D1]` `[D2]`

#### Scenario: Malformed card

- **WHEN** one card in the feed can't be read
- **THEN** the other cards still load

### Requirement: Decision history

The service SHALL return pages of decision history, newest first, limited to what the user handled or what was handled for them when the server supports that. Each record SHALL carry the outcome, the action's verb and detail, the reason, the task, who resolved it and when.

#### Scenario: History on a routed server

- **WHEN** the app asks for the user's history and the feed reported routing
- **THEN** the service requests `GET /api/companies/{id}/attention/history?limit=50&scope=mine`

#### Scenario: History on a server without routing

- **WHEN** the feed reported no routing
- **THEN** the service requests history without `scope` `[D19]`

### Requirement: Approval detail and comments

The service SHALL return an approval's full payload as labelled fields plus the raw JSON, its decision note, and its comments with author and time. It SHALL post a comment and return it. It SHALL request a revision with a note.

#### Scenario: Approval detail

- **WHEN** the app opens an approval card
- **THEN** the service reads `GET /api/approvals/{id}` and `GET /api/approvals/{id}/comments` and returns both

#### Scenario: Request revision

- **WHEN** the app requests a revision with a note
- **THEN** the service sends `POST /api/approvals/{id}/request-revision` with `decisionNote`

### Requirement: Task-thread requests

The service SHALL read a task-thread request with its prompt and the parts its kind needs: confirmation labels and the reject-reason rule, questions with options, or items with the allowed verdicts and reason rules. It SHALL accept, reject with an optional reason, submit answers, and submit item verdicts.

#### Scenario: Reading a questions request

- **WHEN** the app opens a questions card on task ATL-160
- **THEN** the service reads `GET /api/issues/{issue}/interactions` and returns that request's questions, options, Recommended marks and Other rules

#### Scenario: Submitting verdicts

- **WHEN** the app submits verdicts for three items
- **THEN** the service sends `POST /api/issues/{issue}/interactions/{id}/verdicts` with each item's ID, verdict and reason

### Requirement: Close, claim and transfer

The service SHALL withdraw a card with a reason, archive it, or snooze it until a time, sending the card's fingerprint for archive and snooze. It SHALL claim a task-thread request for the user and transfer one to a person with an optional reason. It SHALL list the company's people by ID, name and email, and dismiss a receipt.

#### Scenario: Snooze

- **WHEN** the app snoozes a card until tomorrow at 9:00
- **THEN** the service sends `POST /api/companies/{id}/attention/{sourceKind}/{sourceId}/close` with mode `snooze`, the time and the card's fingerprint

#### Scenario: People

- **WHEN** the app needs the company's people
- **THEN** the service reads `GET /api/companies/{id}/user-directory` and returns each active member's ID, name and email `[D7]`

#### Scenario: People not available

- **WHEN** the user-directory request answers `403` or `404`
- **THEN** the service reports people as unsupported

### Requirement: Already-closed error

The service SHALL report an action on a card that someone else already answered or closed as already closed, with the status and, when known, the person or agent who resolved it and when. It SHALL do so for the `409 attention_already_closed` body. It SHALL also do so for a `422` "Only pending…" on an approval and for a `409` `interaction_already_resolved`, `interaction_superseded`, `interaction_stale_target` or `interaction_issue_closed` on a task-thread request, after one read of the source to learn who resolved it. It SHALL never retry the action. `[D16]`

#### Scenario: 409 with details

- **WHEN** a close answers `409` with `code: attention_already_closed` and Priya as the resolver
- **THEN** the service reports already closed by Priya with the time from the body

#### Scenario: Approval decided elsewhere

- **WHEN** a reject answers `422` "Only pending or revision requested approvals can be rejected"
- **THEN** the service reads the approval and reports already closed with its status, `decidedByUserId` and `decidedAt`

#### Scenario: Interaction resolved elsewhere

- **WHEN** an accept answers `409` with `code: interaction_already_resolved`
- **THEN** the service reads the request and reports already closed with its `resolvedByUserId` or `resolvedByAgentId` and `resolvedAt`

#### Scenario: Same verdict repeated

- **WHEN** an approve answers `200` because the approval was already approved
- **THEN** the service reports success

### Requirement: Inbox methods are optional

Each inbox method SHALL have a default that reports unsupported, so a `FactoryService` that doesn't implement it keeps working. A `404` on an inbox route SHALL be reported as unsupported.

#### Scenario: Conformer without inbox methods

- **WHEN** a `FactoryService` implements none of the inbox methods
- **THEN** each of them reports unsupported, and the existing methods behave as before

### Requirement: Demo inbox

The demo factory SHALL have an inbox for Atlas. For you SHALL hold an approval with payload and comments, a plan review, a questions request with single choice, multiple choice, Recommended and Other, an item review, a confirmation that requires a reason to reject, a stale card, a transferred card and a critical problem card. Unassigned SHALL hold a claimable request. Company SHALL hold a failed run and a join request. The demo SHALL also have a receipt, history with every outcome, and three people. Actions SHALL change the demo's state.

#### Scenario: Demo inbox on first load

- **WHEN** the demo factory is asked for Atlas's For you view
- **THEN** it returns cards of every kind the app answers in place, a problem card and a receipt

#### Scenario: Demo action

- **WHEN** the app accepts the demo plan review
- **THEN** the next For you read no longer has it, and history has it as accepted
