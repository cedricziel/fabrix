## ADDED Requirements

### Requirement: Features compose Design components

Feature screens SHALL build their visuals from FabrixDesign components and tokens. A visual that more than one screen uses, or that does not depend on a FabrixCore model, SHALL live in FabrixDesign. FabrixFeatures SHALL only map its models onto Design styles.

#### Scenario: Card surfaces

- **WHEN** a screen shows a card, a section card, an empty row, a run timer or a labeled text field
- **THEN** it uses the FabrixDesign component, and FabrixFeatures defines no copy of it

#### Scenario: Selected card

- **WHEN** a task card or org chart node is selected
- **THEN** the card draws the Design selection outline

### Requirement: Strings live in the module's string catalog

Every user-facing string SHALL be a key in the string catalog of the module that shows it, and SHALL resolve from that module's bundle. Design components SHALL accept localized resources for copy and plain strings for data such as names, IDs and numbers. Case changes SHALL be applied when text renders, so the system can apply the locale's rules.

#### Scenario: A Features string

- **WHEN** a feature screen shows a label
- **THEN** the text comes from the FabrixFeatures string catalog

#### Scenario: A Design string

- **WHEN** a status pill shows "Running"
- **THEN** the text comes from the FabrixDesign string catalog

#### Scenario: Uppercase tags

- **WHEN** a kind tag or eyebrow header renders
- **THEN** it shows uppercase text and VoiceOver reads the natural-case title

### Requirement: Components ship with previews

Every public FabrixDesign component SHALL have an Xcode preview that shows its states. Components added from this change on SHALL also have a dark-appearance preview.

#### Scenario: New component

- **WHEN** a component is added to FabrixDesign
- **THEN** its file has a preview covering each of its states in light and dark

### Requirement: Run timers

A live run's elapsed time SHALL update every second without the screen re-rendering, and VoiceOver SHALL read it as a duration, not as digits.

#### Scenario: VoiceOver on a timer

- **WHEN** VoiceOver focuses a run timer that started two minutes ago
- **THEN** it reads the time as words, such as "2 minutes ago"

### Requirement: Reduce Motion

Views that slide in SHALL fade in instead when the user turns on Reduce Motion.

#### Scenario: Banner with Reduce Motion

- **WHEN** Reduce Motion is on and the error banner appears
- **THEN** it fades in without moving
