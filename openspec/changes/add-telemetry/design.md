## Context

The Paperclip server a tester connects to is their own infrastructure. Its name and host must not reach our telemetry backend in readable form.

## Decisions

- **Own target.** `FabrixTelemetry` owns `Telemetry`, `TelemetryConfiguration`, `Anonymizer`, `AttributeScrubber`, `PaperclipAttribute`, `SensitiveValueSource` and the scrubbing exporters. FabrixDesign still has no FabrixCore dependency, and nothing depends on FabrixTelemetry except the app shells.
- **Scrub at the exporter.** Scrubbing wraps the span and log exporters, so it covers SDK and instrumentation attributes, not only the ones we set. The metric exporter strips all point attributes.
- **Names from the app.** Factory names and hosts come from a `SensitiveValueSource` that the app shell passes to `Telemetry.start`, read once per export batch. The shell adapts FabrixCore's factory store to it, so FabrixCore never depends on FabrixTelemetry.
- **Semantic conventions first.** HTTP spans use the stable conventions. `server.address` and `url.full` carry the hashed host. Paperclip data goes under `paperclip.*`, defined once in `PaperclipAttribute`.
- **Salted hash per install.** A random 32-byte salt in `UserDefaults` keeps tokens stable within one install (so one factory's spans group together) but unlinkable across installs.
- **No disk persistence.** The OTLP exporters re-queue failed batches in memory. The persistence decorator never wrote files in testing, so it is not used.
- **Explicit metric view.** opentelemetry-swift 2.6 drops all measurements unless a view is registered, so the meter provider registers a catch-all view.
- **Key injection.** fastlane writes `Config/Telemetry.secrets.xcconfig` (gitignored) from `OTLP_ENDPOINT` and `OTLP_API_KEY`; `Config/Telemetry.xcconfig` includes it optionally and expands into `FabrixOTLP*` Info.plist keys. Missing or unexpanded values turn telemetry off.
