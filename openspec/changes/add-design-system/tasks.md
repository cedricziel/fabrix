## 1. App icon (PR 1)

- [ ] 1.1 Add `scripts/render-app-icons.swift` that draws the mark with CoreGraphics (no test: build tooling)
- [ ] 1.2 Render `App/iOS/Assets.xcassets/AppIcon.appiconset` (1024, no alpha) and `App/macOS/Assets.xcassets/AppIcon.appiconset` (all sizes) and update both `Contents.json` (no test: assets; verified with `sips -g hasAlpha` and both app builds)

## 2. Tokens and type (PR 2)

- [ ] 2.1 Add light/dark `Palette` tokens, `Spacing`, `Radius` and `minimumTapTarget` in `FabrixDesign` (no test: constant values)
- [ ] 2.2 Bundle the three font families with OFL files, add `FabrixDesignTests`, `FabrixFonts.register()` and `Font.fabrix` (`TypographyTests`: registration succeeds and is idempotent, every face resolves, style→face, fallback design, sizes per platform)

## 3. Components (PR 3)

- [ ] 3.1 Add `StatusStyle`, `StatusDot`, `StatusPill` (`StatusStyleTests`: labels, hollow dots, tone mapping)
- [ ] 3.2 Add `BudgetMeter` and `BudgetBar` (`BudgetMeterTests`: ratio, clamping, no cap, warning threshold, percent)
- [ ] 3.3 Add `AvatarBadge`, `DecisionKind`, `KindTag` (`BadgeTests`: initials, kind titles)
- [ ] 3.4 Add `PrimaryButtonStyle`, `SignalButtonStyle`, `SecondaryButtonStyle` (no test: visual only, checked in previews)
- [ ] 3.5 Add `Card`, `SectionHeader`, `MetricCard` (no test: visual only, checked in previews)
