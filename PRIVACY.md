# Fabrix privacy policy

Effective date: November 7, 2026

## What Fabrix connects to

Fabrix talks only to the Paperclip servers you add. Server addresses and credentials (board API keys and OIDC tokens) stay on your device in the Keychain. They are never sent to the developer.

Fabrix has no accounts, no ads and no tracking. No data is sold or shared.

## Diagnostics

Release builds send anonymous technical telemetry to the developer's self-hosted observability backend: OpenTelemetry traces, logs and metrics about app performance and errors.

Before anything leaves your device, Paperclip server names and hostnames are replaced with a salted one-way hash. The salt is generated per install. Telemetry never includes the names of companies, agents or tasks, credentials, or personal data.

Builds without a telemetry key send nothing.

## Contact

Open an issue at https://github.com/cedricziel/fabrix/issues.
