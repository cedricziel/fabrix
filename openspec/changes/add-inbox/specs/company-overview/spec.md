## MODIFIED Requirements

### Requirement: Decisions and activity

The overview SHALL list approvals waiting on the user with Approve and Open, and the latest activity with a link to all of it. On a factory with the inbox, Approve SHALL stage the decision in the inbox and Open SHALL select the approval's card in the inbox. On a factory without the inbox, both SHALL work with the Approvals screen as before.

#### Scenario: Approving from the overview

- **WHEN** the user taps Approve on the overview
- **THEN** the approval leaves the list and is staged with undo, in the inbox's undo bar on a factory with the inbox and as on the Approvals screen otherwise

#### Scenario: Opening an approval

- **WHEN** the user taps Open on a factory with the inbox
- **THEN** the Inbox is shown with that approval's card selected

#### Scenario: Opening an approval without the inbox

- **WHEN** the user taps Open on a factory without the inbox
- **THEN** the Approvals screen is shown
