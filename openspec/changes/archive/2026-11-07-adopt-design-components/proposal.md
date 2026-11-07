## Why

The SwiftUI component audit found card surfaces, empty rows, the run timer and the connect form's text field defined inside FabrixFeatures, so they drift from the design system. Design components take plain `String`s, which forces every caller to localize first and loses the difference between copy and data. There is no string catalog, and Design and Features look up strings in different bundles, so adding a second language would break one of them.

## What Changes

- FabrixDesign gains the shared surfaces: `SectionCard`, `EmptyRow`, the `.fabrixCard(selected:)` modifier, `FabrixTextFieldStyle` with `LabeledField`, a generic tone `Pill` that `StatusPill` builds on, and `ElapsedText`. Each ships with a light and dark preview. `FabrixFeatures/Shell/Common.swift` loses them and the feature screens call the Design versions without changing how they look.
- `SectionHeader`, `MetricCard`, `KindTag` and `StatusPill` take `LocalizedStringResource`; the `String` initializers stay for data. Uppercase labels use `.textCase(.uppercase)` instead of uppercased strings.
- `ElapsedText` uses the system timer text, so it updates without re-rendering and VoiceOver reads a duration.
- A `fabrixTransition` helper swaps slide-in transitions for a fade when Reduce Motion is on.
- FabrixDesign and FabrixFeatures each get a `Localizable.xcstrings`, and Features looks up its strings in its own bundle. English only for now.

Platforms: macOS, iPadOS and iOS. Targets: FabrixDesign and FabrixFeatures. `FactoryService` is unchanged, and FabrixDesign still has no FabrixCore dependency.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `design-system`: features compose Design components, user-facing strings live in their module's string catalog, new components ship with previews, the timer reads as a duration, and motion respects Reduce Motion.

## Impact

- `FabrixDesign`: new `Surfaces.swift`, `Fields.swift`, `Pill.swift`, `Timer.swift`, `Motion.swift`; localized overloads in `Containers.swift`, `Badges.swift`, `Status.swift`; `Resources/Localizable.xcstrings`.
- `FabrixFeatures`: `Shell/Common.swift` removed; screens call Design components and pass `bundle: .module`; `Resources/Localizable.xcstrings`.
- `Package.swift`: both targets process their string catalogs.
