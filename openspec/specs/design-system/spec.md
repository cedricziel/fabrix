# design-system Specification

## Purpose
Shared tokens, typography and components that give every Fabrix screen the same look on macOS, iPadOS and iOS.
## Requirements
### Requirement: Light and dark appearance

Every color token SHALL have a light and a dark variant. Dark mode SHALL use a graphite ground with paper-colored text, and the signal orange SHALL stay the same in both modes.

#### Scenario: System switches to dark mode

- **WHEN** the device appearance is dark
- **THEN** backgrounds render near-black, primary text renders near-white, and signal orange is unchanged

### Requirement: Brand typefaces with Dynamic Type

The app SHALL render titles and numbers in Space Grotesk, interface text in Inter, and IDs, adapters, timers and money in JetBrains Mono. Text SHALL scale with the user's Dynamic Type setting. If the bundled fonts cannot be registered, text SHALL fall back to the system font with the same weight, and monospaced text SHALL stay monospaced.

#### Scenario: Fonts register

- **WHEN** the app first renders text
- **THEN** all bundled faces are registered for the process and resolve by name

#### Scenario: Registration fails

- **WHEN** a bundled font cannot be registered
- **THEN** text renders in the system font at the matching text style, and mono styles use the monospaced system design

#### Scenario: Body size per platform

- **WHEN** body text renders on the Mac
- **THEN** it uses 13 points, and on iPhone and iPad it uses 15 points, before Dynamic Type scaling

### Requirement: Status never by color alone

An agent status SHALL show a dot and a text label. Paused and needs-you SHALL use a hollow dot; running, idle, blocked and done SHALL use a filled dot. Only needs-you SHALL use signal orange.

#### Scenario: Agent needs a decision

- **WHEN** a status pill shows needs-you
- **THEN** it reads "Needs you" with a hollow orange dot on an orange tint

#### Scenario: VoiceOver reads a status

- **WHEN** VoiceOver focuses a status pill
- **THEN** it speaks the label and any detail, not the dot

### Requirement: Budget meter

A budget bar SHALL show spend as a share of the cap, clamped between empty and full. A missing or non-positive cap SHALL show an empty bar. From 90 % of the cap the bar SHALL turn signal orange.

#### Scenario: Over the cap

- **WHEN** spend is $250 against a $200 cap
- **THEN** the bar is full and orange

#### Scenario: No cap

- **WHEN** the cap is 0
- **THEN** the bar is empty

### Requirement: Touch targets

On iPhone and iPad every button style SHALL keep a hit area of at least 44 points. On the Mac, small buttons MAY be 30 points tall.

#### Scenario: Compact width

- **WHEN** a small button renders on iPhone
- **THEN** its hit area is at least 44 points tall

#### Scenario: Regular width on Mac

- **WHEN** a small button renders in a Mac toolbar
- **THEN** it is 30 points tall

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
- **THEN** it reads the time as words that keep counting, such as "2 minutes, 13 seconds"

### Requirement: Reduce Motion

Views that slide in SHALL fade in instead when the user turns on Reduce Motion.

#### Scenario: Banner with Reduce Motion

- **WHEN** Reduce Motion is on and the error banner appears
- **THEN** it fades in without moving

