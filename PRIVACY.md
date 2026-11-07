# Fabrix privacy policy

Effective date: November 7, 2026

Fabrix has no accounts, no ads and no tracking. No data is sold or shared.

## What Fabrix collects

TestFlight and release builds send diagnostic data (traces, logs and metrics) so I can find crashes, errors and slow requests and improve the app. Builds made without the ingest key, such as local developer builds, send nothing.

The data goes over HTTPS, using the OpenTelemetry protocol (OTLP), to SignalDB, an observability database that I host on my own server. No third-party analytics service receives it.

None of it is linked to your identity. Fabrix does not send an advertising ID, the device vendor ID, or your device or host name.

## What leaves your device

### With every record

| Attribute                               | Example                                                                                                  |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| App name (`service.name`)               | `fabrix`                                                                                                 |
| App version and build number            | The installed build                                                                                      |
| Installation ID (`service.instance.id`) | A random UUID created on first launch and stored on your device. Reinstalling the app creates a new one. |
| Operating system type, name and version | iOS, iPadOS or macOS                                                                                     |
| Hardware model identifier               | `iPhone17,1`, `Mac15,12`                                                                                 |
| Environment                             | `production` or `development`                                                                            |

### On each launch

- A trace span named `app.launch`.
- A log line, "Telemetry started".
- The metric `fabrix.app.launches`, a launch counter with no extra attributes.

### For network requests the app makes

- HTTP method and response status code.
- URL scheme and server port.
- URL path, with identifiers replaced by `{id}`, for example `/api/companies/{id}/agents`.
- Error type and exception details.

The server host name is never sent in readable form (see below). Query strings, fragments, and user names and passwords in URLs are removed.

### Paperclip details

| Attribute                 | What it holds                                                             |
| ------------------------- | ------------------------------------------------------------------------- |
| `paperclip.factory.id`    | The anonymized server token (see below)                                   |
| `paperclip.auth.method`   | `board_key`, `oidc` or `oidc+board_key`                                   |
| `paperclip.approval.kind` | The kind of approval                                                      |
| `paperclip.agent.status`  | An agent's status                                                         |
| `paperclip.run.adapter`   | The adapter a run uses                                                    |
| `paperclip.api.route`     | A route template such as `/api/companies/{id}/agents`, never concrete IDs |

Some of these are reserved for screens that are still being built. They are only sent once that feature records them.

## How server names are anonymized

Before anything leaves your device, Fabrix replaces server host names and factory names with a token. The token is the first 16 hex characters of a SHA-256 hash of a salt plus the name. The salt is 32 random bytes created on first launch and stored only on your device.

So the same server gets the same token on one installation, but nobody can turn a token back into a name or match tokens across installations. This applies everywhere: span names, attributes, events, error messages and log text.

The content of your factories (task titles, agent names, messages, approval text) is not part of this telemetry.

## Storage

The data stays on my own server and is not shared.

## Opting out

There is no in-app switch yet. If you don't want this data sent, don't install the beta builds, or open an issue (see below).

## Connecting your own Paperclip server

You can connect your own Paperclip server. Apart from the diagnostic data described above, Fabrix then talks only to the address you enter and, if you sign in with OIDC, to your identity provider. That traffic goes from your device to servers you chose.

Paperclip API keys and OIDC tokens are stored only in the Keychain on your device. The server address and name, and the OIDC issuer and client ID, are stored in the app's local settings. Forgetting a factory in the app deletes its saved keys and tokens.

Credentials are sent over plain HTTP only to local-network addresses, and never along a redirect to a different origin.

## Contact

Open an issue at https://github.com/cedricziel/fabrix/issues.
