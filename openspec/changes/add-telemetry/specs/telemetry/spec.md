## ADDED Requirements

### Requirement: Telemetry export

The app SHALL export traces, logs and metrics over OTLP/HTTP to SignalDB when the build carries an ingest key, and SHALL export nothing when it does not.

#### Scenario: Release build with a key

- **WHEN** a build made by CI with the OTLP secrets launches
- **THEN** it sends an `app.launch` span, a log record and the `fabrix.app.launches` metric to tenant `apps`, dataset `fabrix`

#### Scenario: Local build without a key

- **WHEN** a build without an endpoint or key launches
- **THEN** telemetry stays off and no OTLP request is made

### Requirement: Paperclip servers stay anonymous

Telemetry SHALL NOT contain a Paperclip factory's name or host, or the query string of any request URL.

#### Scenario: Traced request to a factory

- **WHEN** the app requests `https://factory.example:3100/api/agents?key=x`
- **THEN** the exported span shows `https://<token>/api/agents`, where `<token>` is a salted SHA-256 of the host, unique to this install

#### Scenario: Factory name in a log message

- **WHEN** a registered factory name appears in a log body, span name or attribute
- **THEN** it is replaced by its token before export

### Requirement: No machine identifiers

The exported resource SHALL NOT include the device's host name or vendor identifier.

#### Scenario: Resource attributes

- **WHEN** telemetry starts
- **THEN** the resource carries only the service name and version, build number, a random per-install instance ID, OS name and version, hardware model and environment
