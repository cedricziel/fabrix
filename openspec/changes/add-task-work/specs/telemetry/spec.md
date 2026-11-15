## ADDED Requirements

### Requirement: Task content stays out of telemetry

Telemetry for task requests SHALL carry only templated routes and the attributes already allowed. It SHALL never carry task titles, descriptions, comment text, document bodies, document titles, change summaries, work product titles or links, labels, or the IDs and document keys in task URL paths.

#### Scenario: Document request span

- **WHEN** the app requests `GET /api/issues/<uuid>/documents/launch-plan/revisions`
- **THEN** the exported span's `paperclip.api.route` is `/api/issues/{id}/documents/{key}/revisions`

#### Scenario: Failed comment

- **WHEN** posting a comment fails and the app logs the failure
- **THEN** the exported log and span status contain neither the comment text nor the task title

#### Scenario: Refused edit

- **WHEN** an edit is refused and the app logs the server's reason
- **THEN** the exported log carries the status code and the templated route, and not the task's title
