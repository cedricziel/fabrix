## ADDED Requirements

### Requirement: Task detail

The service SHALL return one task's detail: identifier, title, description, status, priority, assignee (agent or user), project, goal, labels, parent chain from the root, the tasks that block it and that it blocks with their status and priority, and timestamps. When the server embeds the plan, document summaries, a plan kept in the description, or work products, the detail SHALL carry them, and SHALL say they are absent when the server doesn't send them, so callers can fall back `[D15]`. Unknown statuses SHALL map to backlog and unknown priorities to medium.

#### Scenario: Detail from a live server

- **WHEN** the app opens a task on a Paperclip server
- **THEN** the service reads `GET /api/issues/{id}` once and returns the detail with its embedded plan, documents and work products

#### Scenario: Older server without embedded parts

- **WHEN** the detail response has no `documentSummaries` or `workProducts`
- **THEN** the detail marks them as not embedded, and the app reads them from their own endpoints

#### Scenario: Task gone

- **WHEN** the server answers `404` "Issue not found"
- **THEN** the service reports the task as not found, not as unsupported

### Requirement: Task comments

The service SHALL list a task's comments, newest first, limited to a page size, optionally only those after a given comment. Each comment SHALL carry its author kind (agent, user or system), author ID, body, time and the run that wrote it. The service SHALL post a comment with a client request ID and return the stored comment.

#### Scenario: Reading the thread

- **WHEN** the app loads a thread
- **THEN** the service requests `GET /api/issues/{id}/comments?order=desc&limit=100`

#### Scenario: Posting

- **WHEN** the app posts "Please split this into two PRs"
- **THEN** the service sends `POST /api/issues/{id}/comments` with `body` and `clientRequestId`, and returns the comment from the `201` answer

### Requirement: Task documents and revisions

The service SHALL list a task's documents without system documents, return one document by key with its body and latest revision number, and list a document's revisions newest first with number, author, time, change summary and body.

#### Scenario: Plan revisions

- **WHEN** the app opens the plan's history
- **THEN** the service requests `GET /api/issues/{id}/documents/plan/revisions` and returns the revisions newest first

### Requirement: Work products and their files

The service SHALL list a task's work products with type, provider, title, link, status, health, whether it is primary, and, for a file Paperclip stores, its download path. It SHALL download such a file through the factory connection, with the factory's credentials, to a temporary file, only when the path is on the factory's own origin.

#### Scenario: File on another host

- **WHEN** a work product's download path points at another origin
- **THEN** the service doesn't send the factory's credentials and offers the link for the browser instead

### Requirement: Runs on a task

The service SHALL return a task's active run, or none, and its queued and running runs, each with agent, status and start time. Runs in the company snapshot SHALL carry their outcome (succeeded, failed, timed out, cancelled or interrupted) once finished, mapped from the run's status; an unknown finished status SHALL map to interrupted.

#### Scenario: Finished run outcome

- **WHEN** the snapshot loads a run with status `timed_out`
- **THEN** the run is finished with the outcome timed out

#### Scenario: Nothing running

- **WHEN** `GET /api/issues/{id}/active-run` answers `200` with `null`
- **THEN** the service returns no active run, not an error

### Requirement: Create and update tasks

The service SHALL create a task in a company from a title, optional description, status, priority, assignee, project and parent, with an idempotency key, and return the created task. It SHALL update a task's status, priority, assignee or project, sending only the changed fields, and return the task as the server's answer describes it, without reading it again. A `400`, `409` or `422` answer SHALL be reported as refused with the server's reason and, for create, the fields it names.

#### Scenario: Create

- **WHEN** the app creates "Write release notes" assigned to an agent
- **THEN** the service sends `POST /api/companies/{id}/issues` with `title`, `assigneeAgentId`, `priority` and `idempotencyKey`, and returns the task from the `201` or `200` answer

#### Scenario: Update returns the new state

- **WHEN** the app moves a task to In review
- **THEN** the service sends `PATCH /api/issues/{id}` with `{"status":"in_review"}` and returns the task from that answer, with no second request

#### Scenario: Refused update

- **WHEN** the server answers `422` "in_progress issues require an assignee"
- **THEN** the service reports the update as refused with that reason

### Requirement: Signed-in board user

The service SHALL report the ID of the signed-in board user, so the app can offer Me as an assignee and name the user's own comments. It SHALL read it once per connection. Only a route `404` SHALL mean unsupported; any other failure SHALL be reported as an error, so the next load asks again.

#### Scenario: Board user from a live server

- **WHEN** the app asks who is signed in twice on one connection
- **THEN** the service reads `GET /api/cli-auth/me` once and returns its `userId` both times

#### Scenario: Board user lookup fails

- **WHEN** `GET /api/cli-auth/me` answers `500`
- **THEN** the service reports an error, not unsupported

### Requirement: Task methods are optional

Every task method SHALL have a default that reports it as unsupported, so existing services keep working. A live method SHALL report unsupported when the server answers `404` with "API route not found" or a `404` without a JSON error body, and SHALL report not found for any other `404`.

#### Scenario: Older server

- **WHEN** `GET /api/issues/{id}/work-products` answers `404` with `{"error":"API route not found"}`
- **THEN** the service reports work products as unsupported

#### Scenario: Missing document

- **WHEN** `GET /api/issues/{id}/documents/plan` answers `404` with `{"error":"Document not found"}`
- **THEN** the service reports the document as not found

### Requirement: Demo task work

The demo factory SHALL give its tasks priorities, descriptions, a parent chain, a blocker, labels, threads with agent, user and system comments, a plan with several revisions and a second document, work products of several types including a stored file, and live, queued and finished runs. Creating and editing tasks in the demo SHALL change its state in memory. One demo task SHALL refuse In progress the way the server does, so previews reach the refusal path.

#### Scenario: Demo detail on first load

- **WHEN** the demo factory is asked for ATL-142's detail
- **THEN** it returns a description, a parent, a blocker, comments, a plan with revisions, work products and a live run

#### Scenario: Demo refusal

- **WHEN** the app moves the demo's marked task to In progress
- **THEN** the demo reports the update as refused with "in_progress issues require an assignee"
