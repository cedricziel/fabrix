## Why

We have no view into how Fabrix behaves on testers' devices. The first TestFlight builds need traces, logs and metrics, without sending anything that identifies a tester's Paperclip servers.

## What Changes

- New `FabrixTelemetry` library target in `Packages/FabrixKit` (depends on opentelemetry-swift). FabrixCore, FabrixDesign and FabrixFeatures do not depend on it.
- The app shells call `Telemetry.start()` at launch and `Telemetry.flush()` when the app moves to the background.
- Exports traces, logs and metrics over OTLP/HTTP to SignalDB (homelab, tenant `apps`, dataset `fabrix`). Outgoing HTTP requests are traced through URLSession instrumentation.
- Before export, every span, log record and resource is scrubbed: hosts become a salted SHA-256 token (per install), URL queries, fragments, user info and ports are dropped, and registered factory names and hosts are replaced wherever they appear.
- CI bakes the ingest-only key into Release builds from GitHub secrets via a gitignored xcconfig, deleted after the build. Debug builds never read it. Builds without the key run with telemetry off.
- A privacy manifest (`PrivacyInfo.xcprivacy`) declares the collected data and the `UserDefaults` use, and `PRIVACY.md` lists exactly what is sent.

Platforms: macOS, iPadOS, iOS. FabrixKit targets: new FabrixTelemetry. The FactoryService protocol does not change.

## Impact

- `Packages/FabrixKit/Package.swift`, `Sources/FabrixTelemetry`, `Tests/FabrixTelemetryTests`
- `App/Shared/FabrixApp.swift`, `App/Shared/PrivacyInfo.xcprivacy`, `project.yml`, `Config/Telemetry.xcconfig`, `Config/Telemetry-Release.xcconfig`, `PRIVACY.md`
- `fastlane/Fastfile`, `.github/workflows/testflight.yml`, `.github/workflows/release-please.yml`, `scripts/`
