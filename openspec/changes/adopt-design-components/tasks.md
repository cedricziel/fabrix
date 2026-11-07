## 1. Shared surfaces and pills (PR 1)

- [x] 1.1 Propose and validate this change (`openspec/changes/adopt-design-components`); no test, spec only
- [x] 1.2 `SectionCard`, `EmptyRow`, `fabrixCard(selected:)` in FabrixDesign with previews; Features call sites renamed, `cardSurface`/`selectionOutline` removed (`FabrixDesign/Surfaces.swift`, `FabrixFeatures/Shell/Common.swift`, screens); no test, pure move
- [x] 1.3 `FabrixTextFieldStyle` and `LabeledField` in FabrixDesign; onboarding uses them (`FabrixDesign/Fields.swift`, `FabrixFeatures/Screens/OnboardingView.swift`); no test, pure move
- [x] 1.4 Generic tone `Pill`; `StatusPill` uses it, the task status capsule moves onto it with the tasks token slice (`FabrixDesign/Pill.swift`, `FabrixDesign/Status.swift`); test `ContrastTests.pillInkReadsOnItsTint` for every tone

## 2. Localized initializers, timer and motion (PR 2)

- [ ] 2.1 `LocalizedStringResource` overloads on `SectionHeader`, `MetricCard`, `KindTag`, `StatusPill`; `.textCase(.uppercase)` (`FabrixDesign/Containers.swift`, `Badges.swift`, `Status.swift`); test `LocalizedInitTests`, the tag keeps a natural-case accessibility label
- [ ] 2.2 `ElapsedText` on `Text(timerInterval:)` in FabrixDesign; Features call sites renamed (`FabrixDesign/Timer.swift`); test `ElapsedTextTests` for the interval
- [ ] 2.3 `fabrixTransition` helper respecting Reduce Motion; banner and approvals use it (`FabrixDesign/Motion.swift`); test `MotionTests`

## 3. String catalogs and bundle wiring (PR 3)

- [ ] 3.1 `Localizable.xcstrings` in FabrixDesign and FabrixFeatures, processed (`Package.swift`, `Resources/`); test `LocalizationBundleTests` resolves a string from each module bundle
- [ ] 3.2 Features literals pass `bundle: .module` (every screen); no new test, covered by 3.1
- [ ] 3.3 Archive the change
