## 1. FabrixTelemetry target

- [x] 1.1 Read OTLP settings from Info.plist; off when any is missing (`TelemetryConfigurationTests`; `Sources/FabrixTelemetry/TelemetryConfiguration.swift`)
- [x] 1.2 Salted per-install hash (`AnonymizerTests`; `Anonymizer.swift`)
- [x] 1.3 Scrub hosts, URL queries and registered values (`AttributeScrubberTests`; `AttributeScrubber.swift`)
- [x] 1.4 Scrub spans and log records before export (`ScrubbingExporterTests`; `ScrubbingExporters.swift`)
- [x] 1.5 Name Paperclip attributes, template ID paths, scrub any URL scheme, read names from an app source, strip metric attributes (`PaperclipAttributeTests`, `AttributeScrubberTests`, `ScrubbingExporterTests`; `PaperclipAttribute.swift`, `SensitiveValueSource.swift`, `AttributeScrubber.swift`, `ScrubbingExporters.swift`)
- [x] 1.6 Start export at launch, resource without machine identifiers, metrics reach the exporter (`TelemetryTests`, `MeterProviderTests`; `Telemetry.swift`)

## 2. App and release wiring

- [x] 2.1 Start telemetry from the app shells and flush on background (no test: app shell; `App/Shared/FabrixApp.swift`, `project.yml`)
- [x] 2.2 Declare collected data and the UserDefaults reason (no test: manifest; `App/Shared/PrivacyInfo.xcprivacy`)
- [x] 2.3 Read the secrets xcconfig only in Release (no test: build config; `Config/Telemetry-Release.xcconfig`, `project.yml`)

## 3. Release key injection

- [x] 3.1 Write, escape and delete the secrets xcconfig in fastlane; pass the OTLP secrets in both workflows (no test: build config; `fastlane/Fastfile`, workflows, `scripts/`)
- [x] 3.2 Describe the telemetry in the privacy policy (no test: docs; `PRIVACY.md`)
