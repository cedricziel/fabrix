## ADDED Requirements

### Requirement: Approvals screen as fallback

The Approvals screen SHALL be shown only for factories without the attention feed. On factories with the feed, approvals SHALL be answered in the inbox. Overview's waiting approvals SHALL use the inbox's staged decisions, so one approval is never staged twice.

#### Scenario: Factory with the inbox

- **WHEN** the factory supports the attention feed
- **THEN** there is no Approvals section or tab, and approving from Overview stages the decision in the inbox's undo bar

#### Scenario: Factory without the inbox

- **WHEN** the factory doesn't support the attention feed
- **THEN** Approvals works exactly as before, with its waiting and decided lists and its undo window

#### Scenario: Already decided on the fallback screen

- **WHEN** the user's rejection on the Approvals screen reaches an approval someone else already decided
- **THEN** the screen shows "Your decision wasn't sent: This was already decided on the board.", as today
