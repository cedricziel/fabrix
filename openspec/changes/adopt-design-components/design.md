## Context

The audit (component audit, slices 1–3) lists five feature-local visuals and four Design components that take `String`. Swift packages don't pick a module bundle by default: `Text("…")`, `Button("…")` and a `LocalizedStringResource` literal all resolve against `Bundle.main`. Design already passes `bundle: .module`; Features does not.

## Goals / Non-Goals

**Goals:** one home for each reusable visual; strings that resolve from the module that owns them; no visible change to any screen.

**Non-Goals:** adopting the type and spacing tokens on each screen (audit slices 4–7), new languages, plural rules.

## Decisions

- **Design owns every new type.** `SectionCard`, `EmptyRow`, `ElapsedText`, `Pill`, `FabrixTextFieldStyle`, `LabeledField` and the `fabrixCard` and `fabrixTransition` modifiers live in FabrixDesign. Model mappings such as `AgentStatus.style` and `BudgetBar(_ budget:)` stay in Features because they need FabrixCore.
- **`LocalizedStringResource` for copy, `String` for data.** Design components take `LocalizedStringResource` for titles and keep `String` initializers, marked `@_disfavoredOverload`, for names and numbers. A resource resolves in whatever bundle the caller gave it, so Design never has to know about Features' catalog.
- **Explicit bundles in Features.** Features writes `Text("…", bundle: .module)` and `LocalizedStringResource("…", bundle: .module)` instead of a wrapper type, so Xcode's string extraction still finds every literal. Shadowing SwiftUI initializers was rejected because overload resolution against imported initializers is fragile.
- **System timer text.** `ElapsedText` uses `Text(timerInterval:countsDown:)`, which the system redraws without a body pass and formats per locale. Its accessibility label is a relative date, read as words.
- **Reduce Motion in one modifier.** `fabrixTransition(_:)` reads `accessibilityReduceMotion` and falls back to `.opacity`.

## Risks / Trade-offs

- Every literal in Features changes, which conflicts with sessions editing screens. Mitigation: the change is mechanical and lands as its own PR at the top of the stack.
- `swift build` doesn't extract strings; the catalogs are filled by an Xcode build, so a string added without building stays missing from the catalog until the next Xcode build. It still shows in English because the key is the English text.
