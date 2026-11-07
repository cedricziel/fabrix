## ADDED Requirements

### Requirement: Telemetry export

The app SHALL export traces, logs and metrics over OTLP/HTTP to SignalDB (tenant `apps`, dataset `fabrix`) when the build carries an ingest key, and SHALL export nothing when it does not.

#### Scenario: Release build with a key

- **WHEN** a build made by CI with the OTLP secrets launches
- **THEN** it sends an `app.launch` span, a "Telemetry started" log record and the `fabrix.app.launches` counter

#### Scenario: Local build without a key

- **WHEN** a build without an endpoint or key launches
- **THEN** telemetry stays off and no OTLP request is made

### Requirement: Collected data

Telemetry SHALL contain only the following, named after the OpenTelemetry semantic conventions where they cover the data:

- Resource: `service.name` (`fabrix`), `service.version`, `app.installation.id` and `service.instance.id` (the same installation ID), `app.build`, `deployment.environment.name`, `os.type`, `os.name`, `os.version`, `os.description`, `device.model.identifier`, and the SDK's `telemetry.sdk.*`.
- HTTP client spans: `http.request.method`, `http.response.status_code`, `http.request.body.size`, `http.response.body.size`, `url.scheme`, `url.path` (templated), `url.full` (hashed host, templated path, no query), `server.address` (hashed), `server.port`, and on iOS `network.connection.type` (`wifi`, `cell` or `unavailable`). The SDK's `network.connection.subtype` and `network.carrier.*` attributes SHALL be dropped before export.
- Paperclip attributes, all under `paperclip.*`: `paperclip.factory.id`, `paperclip.auth.method`, `paperclip.approval.kind`, `paperclip.agent.status`, `paperclip.run.adapter`, and `paperclip.api.route` (only on requests to a known factory host).
- Metrics: `fabrix.app.launches`, with no point attributes.

The `paperclip.*` names SHALL be defined once in code (`PaperclipAttribute`).

#### Scenario: Metric attributes

- **WHEN** any metric is recorded with attributes
- **THEN** it is exported without them

#### Scenario: Attribute constants

- **WHEN** code sets a Paperclip-specific attribute
- **THEN** it uses a `PaperclipAttribute` case, and every case is named `paperclip.*` and described

### Requirement: Paperclip servers stay anonymous

Telemetry SHALL NOT contain a Paperclip factory's name or host, any URL's query, fragment, user info or port, or concrete IDs in URL paths. Hosts and factory names are replaced by a 16-hex-character salted SHA-256 token; the 32-byte salt is random per install and never leaves the device.

#### Scenario: Traced request to a factory

- **WHEN** the app requests `https://factory.example:3100/api/companies/<uuid>/agents?key=x`
- **THEN** the exported span has `url.full` `https://<token>/api/companies/{id}/agents`, `server.address` `<token>` and `paperclip.api.route` `/api/companies/{id}/agents`

#### Scenario: Network status on iOS

- **WHEN** an HTTP span carries `network.connection.type`, `network.connection.subtype` and `network.carrier.name`, `.icc`, `.mcc` and `.mnc`
- **THEN** only `network.connection.type` is exported

#### Scenario: Request to another host

- **WHEN** the app requests `/api/…` on a host that is not a saved factory
- **THEN** the span gets no `paperclip.api.route`

#### Scenario: URL inside free text

- **WHEN** a log body or error message contains a URL with any scheme, in any letter case (for example `HTTPS://…` or `wss://…?token=…`)
- **THEN** the URL is exported with a hashed host and no query

#### Scenario: Factory name or host outside a URL

- **WHEN** a factory name or host known to the app appears in a log body, span name, status message or attribute, for example in a TLS error
- **THEN** it is replaced by its token before export

#### Scenario: Custom header value in telemetry

- **WHEN** the value of a custom header saved with a factory, such as a proxy token, appears in an attribute, log body or status message
- **THEN** it is replaced by its token before export

#### Scenario: Factories added at runtime

- **WHEN** the user adds a factory after launch
- **THEN** the exporter reads names and hosts from the app-supplied `SensitiveValueSource` for every batch, so the new factory is scrubbed from the next export

### Requirement: No machine identifiers

The exported resource SHALL NOT include the device's host name, a hardware identifier, or a vendor or advertising identifier. The installation ID (`app.installation.id`, also sent as `service.instance.id`) SHALL be a random UUID generated once and kept as a non-synchronizable Keychain item in the app's shared access group, so it survives reinstalls; it is not linked to the user.

#### Scenario: Installation ID across launches

- **WHEN** the app launches again, or is deleted and reinstalled on the same device
- **THEN** it sends the same installation ID

#### Scenario: Keychain unavailable

- **WHEN** the Keychain can't be read or written at launch
- **THEN** telemetry starts with a random ID for that launch only, without blocking startup

#### Scenario: Resource attributes

- **WHEN** telemetry starts
- **THEN** the resource carries only the attributes listed under Collected data
