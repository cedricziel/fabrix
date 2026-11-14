## ADDED Requirements

### Requirement: Inbox components

FabrixDesign SHALL provide the inbox components: inbox row, counted view picker, count badge, owner label, receipt row, key-value list, comment row, choice row, verdict picker, reason field, decision bar, undo bar, resolved notice, history row, placeholder row and key hint. They SHALL take only plain values, FabrixDesign enums and closures, never FabrixCore types. Each SHALL have light, dark and accessibility-size previews. Each SHALL say its state in text, not by color alone.

#### Scenario: No Core dependency

- **WHEN** the FabrixDesign sources are built
- **THEN** none of them imports FabrixCore

#### Scenario: Count badge

- **WHEN** a count badge gets 0, 7 or 140
- **THEN** it is hidden, shows "7", or shows "99+"

#### Scenario: Rows at accessibility sizes

- **WHEN** an inbox row, key-value list or decision bar is shown at an accessibility text size
- **THEN** its parts stack vertically instead of sitting side by side

#### Scenario: Undo bar countdown

- **WHEN** the undo bar counts down with Reduce Motion on
- **THEN** the time left is shown as text and nothing moves
