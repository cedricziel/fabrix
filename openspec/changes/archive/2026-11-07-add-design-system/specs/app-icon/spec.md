## Purpose

The app icon each platform ships with, rendered from the Fabrix mark on the design canvas.

## ADDED Requirements

### Requirement: Platform app icons

The iOS app SHALL ship a single 1024 × 1024 opaque icon with no alpha channel. The Mac app SHALL ship every size from 16 to 1024 pixels, drawn inside the macOS icon grid with transparent margins. Both SHALL show the graphite ground, the white looping stroke and the orange dot.

#### Scenario: iPhone and iPad

- **WHEN** the iOS app is archived for TestFlight
- **THEN** the asset catalog provides a 1024-pixel icon without alpha and validation passes

#### Scenario: Mac

- **WHEN** the Mac app is built
- **THEN** the asset catalog provides 16, 32, 128, 256 and 512 point icons at 1x and 2x

#### Scenario: Regenerate

- **WHEN** someone runs `xcrun swift scripts/render-app-icons.swift`
- **THEN** both icon sets and their `Contents.json` files are rewritten from the mark
