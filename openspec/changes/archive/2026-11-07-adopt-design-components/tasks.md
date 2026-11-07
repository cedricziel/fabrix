## 1. Shared surfaces and pills (PR 1)

- [x] 1.1 Propose and validate this change (`openspec/changes/adopt-design-components`); no test, spec only
- [x] 1.2 `SectionCard`, `EmptyRow`, `fabrixCard(selected:)` in FabrixDesign with previews; Features call sites renamed, `cardSurface`/`selectionOutline` removed (`FabrixDesign/Surfaces.swift`, `FabrixFeatures/Shell/Common.swift`, screens); no test, pure move
- [x] 1.3 `FabrixTextFieldStyle` and `LabeledField` in FabrixDesign; onboarding uses them (`FabrixDesign/Fields.swift`, `FabrixFeatures/Screens/OnboardingView.swift`); no test, pure move
- [x] 1.4 Generic tone `Pill`; `StatusPill` uses it, the task status capsule moves onto it with the tasks token slice (`FabrixDesign/Pill.swift`, `FabrixDesign/Status.swift`); test `ContrastTests.pillInkReadsOnItsTint` for every tone

## 2. Localized initializers, timer and motion (PR 2)

- [x] 2.1 `LocalizedStringResource` overloads on `SectionHeader`, `MetricCard`, `KindTag`, `StatusPill`; `.textCase(.uppercase)` (`FabrixDesign/Containers.swift`, `Badges.swift`, `Status.swift`); test `LocalizedInitTests`, the tag keeps a natural-case accessibility label
- [x] 2.2 `ElapsedText` on `Text(timerInterval:)` in FabrixDesign; Features call sites renamed (`FabrixDesign/Timer.swift`); test `TimerTests` for the interval
- [x] 2.3 `fabrixTransition` helper respecting Reduce Motion; banner and approvals use it (`FabrixDesign/Motion.swift`); test `MotionTests`

## 3. String catalogs and bundle wiring (PR 3)

- [x] 3.1 `Localizable.xcstrings` in FabrixDesign and FabrixFeatures, processed and filled from an Xcode build (`Package.swift`, `Resources/`); no test, resources
- [x] 3.2 Features literals pass `bundle: .module` (every screen); tests `LocalizationBundleTests` in both test targets check that a Features and a Design string look up their own module bundle
- [x] 3.3 `.features("…")` helper for Design components and controls; `scripts/check-feature-strings.sh` in CI rejects literals without a bundle (`FabrixFeatures/Localization.swift`, `.github/workflows/ci.yml`); no test, the script is the check
- [x] 3.4 Keep wordless keys, placeholders and preview copy out of the catalogs; `scripts/sync-string-catalogs.sh` refreshes them (`FabrixDesign/Previews.swift`, screens); test `LocalizationBundleTests` resolves a probe key from each compiled catalog
- [x] 3.5 Fold the model-to-style mappings into `Display.swift` and delete `Shell/Common.swift`; no test, pure move
- [x] 3.6 Archive the change
