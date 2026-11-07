## 1. FabrixTelemetry target

- [x] 1.1 Read OTLP settings from Info.plist; off when any is missing (`TelemetryConfigurationTests`; `Sources/FabrixTelemetry/TelemetryConfiguration.swift`)
- [x] 1.2 Salted per-install hash (`AnonymizerTests`; `Anonymizer.swift`)
- [x] 1.3 Scrub hosts, URL queries and registered values (`AttributeScrubberTests`; `AttributeScrubber.swift`)
- [x] 1.4 Scrub spans and log records before export (`ScrubbingExporterTests`; `ScrubbingExporters.swift`)
- [x] 1.5 Name Paperclip attributes, template ID paths, scrub any URL scheme, read names from an app source, strip metric attributes (`PaperclipAttributeTests`, `AttributeScrubberTests`, `ScrubbingExporterTests`; `PaperclipAttribute.swift`, `SensitiveValueSource.swift`, `AttributeScrubber.swift`, `ScrubbingExporters.swift`)
- [x] 1.6 Start export at launch, resource without machine identifiers, metrics reach the exporter (`TelemetryTests`, `MeterProviderTests`; `Telemetry.swift`)

## 2. App and release wiring

- [x] 2.1 Start telemetry from the app shells and flush on background (no test: app shell; `App/Shared/FabrixApp.swift`, `project.yml`)
- [x] 2.2 Inject the ingest key at build time (no test: build config; `Config/Telemetry.xcconfig`, `fastlane/Fastfile`, workflows, `scripts/`)
