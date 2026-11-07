## Why

Feature screens need one shared visual language from the design canvas (graphite, warm paper, one signal orange, three typefaces) so they don't each re-invent colors, type and status markers. TestFlight uploads also fail without an app icon, which blocks the first build.

## What Changes

- Add color tokens with light and dark variants, plus spacing, radius and minimum tap-target constants.
- Bundle Inter, Space Grotesk and JetBrains Mono (SIL OFL 1.1, license files included), register them at runtime, and expose a type scale that follows Dynamic Type and falls back to system fonts.
- Add reusable components: status dot and pill, metric card, budget bar, avatar badge, kind tag, primary/signal/secondary button styles, card container and section header.
- Render the Fabrix mark into the iOS and macOS app icon sets, with a script that regenerates them.

## Capabilities

### New Capabilities

- `design-system`: tokens, type scale and components shared by every screen on macOS, iPadOS and iOS.
- `app-icon`: the app icon each platform ships with.

### Modified Capabilities

None.

## Impact

- Platforms: macOS, iPadOS, iOS.
- Targets: `FabrixDesign` (new resources and test target `FabrixDesignTests`), app asset catalogs in `App/iOS` and `App/macOS`, new `scripts/render-app-icons.swift`.
- `FactoryService` is unchanged. `FabrixDesign` still has no dependency on `FabrixCore`.
- Adds about 2.5 MB of font files to the app bundle.
