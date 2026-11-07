# approvals Specification

## Purpose
Deciding the approvals agents raise, with a chance to undo.
## Requirements
### Requirement: Waiting and decided lists

The app SHALL list approvals waiting on the user and approvals already decided, each with its kind, requester, age, title and detail.

#### Scenario: Waiting list

- **WHEN** the user opens Approvals
- **THEN** pending approvals not yet decided in the app are listed under Waiting with Approve and Reject

#### Scenario: Nothing waiting

- **WHEN** no approval is waiting
- **THEN** the Waiting list says "Nothing waiting"

### Requirement: Undoable decisions

The app SHALL hold a decision for a short undo window before sending it to the factory.

#### Scenario: Undo inside the window

- **WHEN** the user approves or rejects and then taps Undo before the window ends
- **THEN** the approval returns to Waiting and nothing is sent

#### Scenario: Window ends

- **WHEN** the undo window ends
- **THEN** the decision is sent to the factory and Undo is no longer offered

#### Scenario: App leaves the foreground

- **WHEN** the app goes to the background with decisions still in their window
- **THEN** all of them are sent right away

