## Context

See proposal.md for motivation. Paperclip (`~/private/code/paperclip`) is an Express server under `/api`. Board users authenticate in one of three ways:

- implicitly, in `local_trusted` mode;
- with a Better Auth session cookie from the web UI;
- with a board API key (`Authorization: Bearer pcp_board_…`, valid for 30 days).

A key is issued either by `POST /api/board-api-keys` or through the CLI auth challenge (`/api/cli-auth/challenges`), a device-style flow that the user approves in a browser. Paperclip has no OIDC support for board users. A homelab that wants OIDC puts a reverse proxy in front: oauth2-proxy, Pangolin, Cloudflare Access and similar. Behind the proxy, Paperclip runs either in `local_trusted` mode or in `authenticated` mode with its own board keys. `docs/paperclip-api.md` lists every endpoint the client calls.

## Goals / Non-Goals

**Goals:**

- One request pipeline where authentication is a pluggable value, so the client never branches on auth type.
- OIDC that works on iOS, iPadOS and macOS with system frameworks only.
- A small connection API the feature screens can call without seeing HTTP or token details.

**Non-Goals:**

- Cookie sessions. Fabrix does not log in to Better Auth with a password. Browser sign-in is the way to get a key.
- Browser sign-in through an OIDC front door. When the proxy requires OIDC and Paperclip requires a key, the user pastes a board key in this change.
- Live updates over Paperclip's realtime channel. Snapshots are pulled.
- Validating OIDC ID tokens. The app sends only the access token. The proxy and the IdP check it.

## Decisions

### Every new type lives in FabrixCore

`Paperclip/` holds the client, DTOs, mapping and service. `Auth/` holds the providers, OIDC and PKCE. `Connections/` holds `FactoryStore` and the credential stores. `FabrixDesign` still does not depend on `FabrixCore`. Views keep talking to `FactoryService`. The connection screen calls `FactoryStore`, which is a store and not an HTTP client.

### AuthProvider decorates requests and can refresh

```swift
public protocol AuthProvider: Sendable {
    func authorize(_ request: URLRequest) async throws -> URLRequest
    /// After a 401: refresh if possible. True means "retry once".
    func refreshAfterUnauthorized() async throws -> Bool
}
```

`PaperclipClient` calls `authorize` on every request. On a `401` it asks `refreshAfterUnauthorized()` and retries exactly once. These implementations ship:

- `NoAuth`;
- `BearerTokenAuth`, for a board key;
- `OIDCAuthProvider`;
- `ChainedAuth`, which runs its providers in order and retries if any of them refreshed.

Alternatives considered:

- A closure that returns headers. It can't express refresh, and it hides concurrency.
- Putting tokens on the client. That couples the transport to every auth scheme.

### Per-factory auth configuration

```swift
public struct FactoryAuthConfiguration: Codable, Hashable, Sendable {
    public var oidc: OIDCSettings?          // nil = no OIDC layer
    public var usesBoardKey: Bool           // Paperclip board key in Authorization
}
public struct OIDCSettings: Codable, Hashable, Sendable {
    public var issuer: URL
    public var clientID: String
    public var redirectURI: URL             // e.g. com.cedricziel.fabrix:/oauth/callback
    public var scopes: [String]             // default openid, profile, offline_access
    public var tokenHeader: String          // default "Authorization"
}
```

How the fields combine:

| `oidc` | `usesBoardKey` | Meaning                                                        |
| ------ | -------------- | -------------------------------------------------------------- |
| nil    | false          | `local_trusted`                                                |
| nil    | true           | board key                                                      |
| set    | false          | OIDC is the only auth (proxy plus a `local_trusted` Paperclip) |
| set    | true           | chained                                                        |

A chain where `tokenHeader == "Authorization"` and `usesBoardKey` is true is rejected with `PaperclipError.invalidAuthConfiguration`. `FactoryStore` persists `[StoredFactory { factory, auth }]` as JSON in `UserDefaults`. `Factory` in `Models.swift` is unchanged, so telemetry keeps reading `baseURL` and `name` as before.

An enum with one case per combination was considered. It duplicates OIDC settings across cases, and the UI would have to switch over it.

### Secrets go in the Keychain, one item per factory and layer

`CredentialStore` (String in, String out) is reused. The board key is stored under account `<factoryID>`. OIDC tokens are stored under `<factoryID>.oidc` as JSON: access token, refresh token, expiry and token endpoint. Items are generic passwords in the data protection keychain, `AfterFirstUnlock`. The same code runs on iOS and on the sandboxed macOS app. Tests use `InMemoryCredentialStore`.

### OIDC is a flow plus a provider

`OIDCFlow` covers sign-in, which happens once per connect:

1. Discovery: `GET {issuer}/.well-known/openid-configuration`.
2. PKCE: a 32-byte random verifier, an S256 challenge from CryptoKit, and a random `state`.
3. The authorize URL is opened through an injected `WebAuthenticator` (`authenticate(url:callbackScheme:) async throws -> URL`).
4. The callback's `state` is checked and its code is exchanged at the token endpoint.

The feature layer adapts SwiftUI's `@Environment(\.webAuthenticationSession)` to `WebAuthenticator`. That keeps SwiftUI and presentation anchors out of `FabrixCore`, and lets tests fake the browser.

`OIDCAuthProvider` is an actor used for every request. It refreshes when the access token expires within 60 seconds, or after a `401`. Concurrent callers await one in-flight refresh `Task`. A rotated refresh token replaces the stored one; when the response has none, the old one is kept. A rejected refresh (`invalid_grant`) surfaces as `.unauthorized`.

`AppAuth-iOS` was considered and rejected: it is a third-party dependency, and it carries its own UI coupling for one well-specified flow.

### FactoryStore API for the UI

```swift
connect(url:credential:name:)                       // none or board key
connect(url:auth:boardKey:name:webAuthenticator:)   // any configuration, runs OIDC sign-in if needed
startSignIn(url:clientName:) / completeSignIn(_:name:)
remove(_:)
service(for:) -> PaperclipFactoryService
auth(for:) -> FactoryAuthConfiguration
```

`connect` builds the provider chain, validates with `GET /api/cli-auth/me`, and saves the factory only when that call succeeds.

### Stacked delivery

The change ships as a `gh stack`. Each layer builds and passes its tests on its own:

1. client
2. service mapping
3. connection store
4. pluggable auth and OIDC
5. sandbox seeding and contract tests, plus the archive

## Risks / Trade-offs

- [The proxy may not accept bearer tokens.] → The token header is configurable. The docs say the proxy has to accept bearer tokens, for example oauth2-proxy with `--skip-jwt-bearer-tokens`. Proxies that accept only cookies are out of scope.
- [The IdP may not issue refresh tokens.] → Fabrix requests `offline_access` by default. Without a refresh token, the user signs in again when the access token expires, and the error says so.
- [Keychain access groups on macOS.] → The data protection keychain needs a signed app with an application identifier. Unsigned local builds fail at runtime with `errSecMissingEntitlement`. Package tests use the in-memory store, so CI is unaffected.
- [The Paperclip API keeps moving.] → DTOs keep statuses as raw strings and decode only the fields Fabrix reads. The sandbox contract tests catch drift against the current image.
- [Board keys expire after 30 days.] → The resulting `401` surfaces as `.unauthorized`, and the UI offers to reconnect. Fabrix does not renew keys automatically in this change.

## Open Questions

- Which proxy header the owner's homelab expects for the access token. The header is a free-text setting, so this can be answered at connect time.
