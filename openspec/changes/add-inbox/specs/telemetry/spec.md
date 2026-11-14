## ADDED Requirements

### Requirement: Inbox content stays out of telemetry

Telemetry for inbox requests SHALL carry only templated routes and the attributes already allowed. It SHALL never carry card titles, summaries, comment text, decision notes, reasons, answers, verdicts, approval payloads, people's names or emails, or the IDs in inbox URL paths.

#### Scenario: Close request span

- **WHEN** the app sends `POST /api/companies/<uuid>/attention/issue_thread_interaction/<uuid>/close`
- **THEN** the exported span's `paperclip.api.route` is `/api/companies/{id}/attention/issue_thread_interaction/{id}/close`

#### Scenario: Failed inbox action

- **WHEN** posting a comment or submitting a decision fails and the app logs the failure
- **THEN** the exported log and span status contain neither the comment text, the note, the answer nor the card title
