## Why

Some factories sit behind a reverse proxy, such as Pangolin, that wants its own access token in a request header before it forwards anything to Paperclip. Fabrix sends only a board key or an OIDC token today, so these factories can't be reached.

## What Changes

- A factory can have zero or more custom request headers: name/value pairs sent with every request to that factory, including browser sign-in.
- Header values are secrets. They live in the Keychain, next to the board key. Only the names go into the saved factory record.
- Custom headers follow the same transport rules as the board key: HTTPS or a local network only, never across a redirect to another origin, and never to the OIDC issuer.
- The connect form gets a collapsed "Advanced" section with a "Custom headers" list.
- Header names are checked: valid HTTP tokens, no reserved names (`Host`, `Content-Length`, `Transfer-Encoding`, `Connection`), no duplicates, and no clash with the header the board key or the OIDC token uses.

Platforms: macOS, iPadOS and iOS. Targets: FabrixCore (`Connections/`, `Auth/`) and FabrixFeatures (connect form, `StoreConnector`). `FactoryService` is unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `factory-connections`: factories carry custom request headers, stored and sent like other credentials.
- `onboarding`: the connect form can add custom headers.

## Impact

- `FabrixCore`: new `CustomHeader`; `FactoryStore.connect`, `startSignIn` and `completeSignIn` take headers; `FactoryStore.customHeaders(for:)`.
- `FabrixFeatures`: `FactoryConnector.connect` gains a `headers` parameter; `ConnectForm` gains header rows; `OnboardingView` gets the Advanced section.
- Telemetry: header values are never logged. Fabrix adds no logging of request headers, and the telemetry scrubber can add a guard later.
