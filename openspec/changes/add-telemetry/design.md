## Context

The Paperclip server a tester connects to is their own infrastructure. Its name and host must not reach our telemetry backend in readable form.

## Decisions

- **Own target.** `FabrixTelemetry` owns `Telemetry`, `TelemetryConfiguration`, `Anonymizer`, `AttributeScrubber`, `SensitiveValues` and the scrubbing exporters. FabrixDesign still has no FabrixCore dependency, and nothing depends on FabrixTelemetry except the app shells.
- **Scrub at the exporter.** Scrubbing wraps the span and log exporters, so it covers SDK and instrumentation attributes, not only the ones we set. Metrics carry no attributes from user data.
- **Salted hash per install.** A random 32-byte salt in `UserDefaults` keeps tokens stable within one install (so one factory's spans group together) but unlinkable across installs.
- **No disk persistence.** The OTLP exporters re-queue failed batches in memory. The persistence decorator never wrote files in testing, so it is not used.
- **Explicit metric view.** opentelemetry-swift 2.6 drops all measurements unless a view is registered, so the meter provider registers a catch-all view.
- **Key injection.** fastlane writes `Config/Telemetry.secrets.xcconfig` (gitignored) from `OTLP_ENDPOINT` and `OTLP_API_KEY`; `Config/Telemetry.xcconfig` includes it optionally and expands into `FabrixOTLP*` Info.plist keys. Missing or unexpanded values turn telemetry off.
