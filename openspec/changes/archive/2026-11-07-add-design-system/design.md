## Context

`FabrixDesign` held only a light-mode `Palette`. Feature screens are being built in parallel and need tokens and components now. `FabrixDesign` must not depend on `FabrixCore`, so it cannot use `AgentStatus` or `ApprovalKind`.

## Goals / Non-Goals

**Goals:**
- One place for colors, type, spacing and the components the boards repeat.
- Every new type lives in `FabrixDesign`; `FabrixFeatures` maps Core models onto them.

**Non-Goals:**
- Screen layouts, navigation and Core-to-Design mapping (owned by `FabrixFeatures`).
- Increase Contrast color variants, tinted and dark iOS icon variants, Icon Composer `.icon` files.

## Decisions

- **Colors in code, not an asset catalog.** `Color(light:dark:)` wraps a dynamic `UIColor`/`NSColor` with both variants built once. Alternative: color sets in a package asset catalog; rejected for now because hex values in one Swift file are easier to review and diff. Revisit if Increase Contrast variants are needed.
- **Own status and kind enums.** `StatusStyle` (running, idle, paused, needs you, blocked, done) and `DecisionKind` (hire, strategy, budget) live in Design. `KindTag(title:)` covers kinds Design does not know.
- **Static font files.** Inter and JetBrains Mono ship static TTFs from their official releases. Space Grotesk 2.0.0 ships no static SemiBold, so `SpaceGrotesk-SemiBold.ttf` is instanced from the official variable font at `wght=600` with fontTools (allowed by the OFL; the font has no Reserved Font Name). Static faces map each type-scale style to one PostScript name, which avoids relying on variable-axis behavior in `Font.custom`.
- **Lazy, cached registration.** `FabrixFonts.register()` registers all faces once (a `static let`) and returns whether every face succeeded; `Font.fabrix` calls it, so apps need no setup. Each `Face` carries its weight and design, so the system fallback keeps weight and stays monospaced for mono.
- **Button size from `controlSize`.** Small 30, regular 44, large 50; on touch devices the hit area is never under 44.
- **Icon rendered by a Swift script with CoreGraphics.** No extra tooling; the iOS bitmap is created without alpha.

## Risks / Trade-offs

- [The instanced Space Grotesk SemiBold drifts from upstream] → It is generated from the 2.0.0 variable font; regenerate if upstream ships a static SemiBold.
- [First text render registers nine fonts on the main thread] → A few milliseconds once per launch; apps may call `FabrixFonts.register()` earlier.
- [Icon hex values duplicate `Palette`] → The script notes the link; the mark rarely changes.
