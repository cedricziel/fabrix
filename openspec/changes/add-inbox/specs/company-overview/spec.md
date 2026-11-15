## MODIFIED Requirements

### Requirement: Decisions and activity

The overview SHALL list approvals waiting on the user with Approve and Open, and the latest activity with a link to all of it. On a factory with the inbox, Approve SHALL stage the decision in the inbox, Open SHALL select the approval's card in the view that holds it (For you, then Unassigned, then Company). When no view holds it, for example because the user snoozed or archived it, Open SHALL show the approval's card on its own, read from the approval itself, marked as hidden from the user's inbox, and "Waiting on you" SHALL show the inbox's count of cards for the user. An approval staged in the inbox SHALL not be listed. On a factory without the inbox, all of these SHALL work with the Approvals screen as before. `[D23]`

#### Scenario: Approving from the overview

- **WHEN** the user taps Approve on the overview
- **THEN** the approval leaves the list and is staged with undo, in the inbox's undo bar on a factory with the inbox and as on the Approvals screen otherwise

#### Scenario: Opening an approval

- **WHEN** the user taps Open on a factory with the inbox
- **THEN** the Inbox is shown with that approval's card selected

#### Scenario: Waiting count with the inbox

- **WHEN** four cards are for the user on a factory with the inbox, one of them an approval
- **THEN** "Waiting on you" shows 4

#### Scenario: Opening an approval in the Company view

- **WHEN** the user taps Open on an approval that is only in the Company view
- **THEN** the Inbox is shown on Company with that card selected

#### Scenario: Opening a snoozed approval

- **WHEN** the user taps Open on an approval whose inbox card they snoozed
- **THEN** the approval's card is shown on its own, can still be decided, and says it is hidden from the inbox

#### Scenario: Opening an approval without the inbox

- **WHEN** the user taps Open on a factory without the inbox
- **THEN** the Approvals screen is shown
