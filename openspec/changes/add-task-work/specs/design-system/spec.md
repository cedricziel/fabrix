## ADDED Requirements

### Requirement: Task components

FabrixDesign SHALL provide the task components: task status pill, priority mark, task card, board column, parent chain, relation row, field row, run row, work product row, document row, revision row, revision banner, Markdown view, comment composer, pinned action button and task detail placeholder. They SHALL take only plain values, FabrixDesign enums and closures, never FabrixCore types. Each SHALL have light, dark and accessibility-size previews, and SHALL say its state in text, not by color alone.

#### Scenario: Status pill

- **WHEN** a status pill shows Backlog, Todo or Cancelled
- **THEN** its dot is hollow, and for the other four statuses it is filled, and the status word is always shown

#### Scenario: Priority mark without the word

- **WHEN** a priority mark shows bars only on a dense card
- **THEN** VoiceOver reads the priority word

#### Scenario: Board column while dragging

- **WHEN** a card is dragged over a column that refuses it
- **THEN** the column shows the reason in text

### Requirement: Markdown view

FabrixDesign SHALL render read-only block Markdown: headings, paragraphs, ordered and unordered lists, code blocks, block quotes, tables, emphasis, inline code and links, using Foundation's Markdown parser and no third-party package `[D12]`. Text SHALL follow Dynamic Type. Links SHALL go to a closure the caller provides. Images SHALL show as links. A long body SHALL be truncated with "Show all" when the caller asks.

#### Scenario: Heading and list

- **WHEN** the view renders "# Plan" followed by a three-item list
- **THEN** it shows a heading and a three-item list, and VoiceOver reads the heading as a heading

#### Scenario: Image

- **WHEN** the body contains an image
- **THEN** the view shows a link with the image's alt text and loads nothing

#### Scenario: Unparseable input

- **WHEN** the body can't be parsed as Markdown
- **THEN** the view shows the raw text
