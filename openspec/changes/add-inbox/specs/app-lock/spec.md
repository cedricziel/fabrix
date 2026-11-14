## MODIFIED Requirements

### Requirement: Confirm approvals

The app SHALL offer "Confirm approvals with Face ID" (named after the device's biometry), off by default. When it is on, these actions SHALL ask for authentication first, and SHALL go ahead only if it succeeds: approving or rejecting, requesting a revision, accepting or declining a request, submitting answers, submitting item verdicts, and withdrawing. Snooze, archive, claim, transfer, comments and dismissing a receipt SHALL not ask. `[D3]` `[D4]`

#### Scenario: Confirmed

- **WHEN** the setting is on and the user approves and authenticates
- **THEN** the decision is staged with its undo window

#### Scenario: Not confirmed

- **WHEN** the setting is on and the user cancels authentication
- **THEN** the approval stays waiting

#### Scenario: Answering questions

- **WHEN** the setting is on and the user submits answers to a questions request and authenticates
- **THEN** the answers are staged with their undo window

#### Scenario: Withdraw not confirmed

- **WHEN** the setting is on and the user confirms a withdraw but cancels authentication
- **THEN** nothing is sent and the card stays

#### Scenario: Snooze does not ask

- **WHEN** the setting is on and the user snoozes a card
- **THEN** no authentication is asked and the snooze is staged
