## MODIFIED Requirements

### Requirement: Section navigation

The app SHALL let the user reach Inbox, Overview, Tasks, Agents, Org chart and Activity for the selected company when the factory supports the inbox. When it doesn't, Approvals SHALL take Inbox's place, in today's position. The app SHALL lay out from the factory's remembered answer. When the answer is that the inbox is supported and the feed hasn't arrived yet, the Inbox section SHALL show a loading state. When there is no answer yet, or the answer is that it isn't supported, Approvals SHALL be shown. `[D24]`

#### Scenario: Regular width

- **WHEN** the app runs at regular width on a factory with the inbox
- **THEN** the sidebar lists Inbox first, then Overview, Tasks, Agents, Org chart and Activity `[D15]`, and selecting a section shows it in the detail area

#### Scenario: Compact width

- **WHEN** the app runs at compact width on a factory with the inbox
- **THEN** four tabs are shown: Inbox, Factory, Tasks and Agents, Inbox is selected on launch, and Org chart and Activity open inside the Factory tab

#### Scenario: Factory without the inbox

- **WHEN** the factory has no attention feed
- **THEN** the sidebar lists Overview, Tasks, Agents, Org chart, Approvals and Activity, and the tabs are Factory, Tasks, Approvals and Agents, as before

#### Scenario: Inbox badge

- **WHEN** cards are waiting for the user
- **THEN** the Inbox sidebar row (regular) or tab (compact) shows the server's count of cards for the user

#### Scenario: Approvals badge

- **WHEN** the factory has no inbox and approvals are waiting on the user
- **THEN** the Approvals sidebar row (regular) or tab (compact) shows the number waiting
