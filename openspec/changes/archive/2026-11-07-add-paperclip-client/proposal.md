## Why

Fabrix only runs against the in-memory demo factory, so it can't show anyone's real agents yet. The first TestFlight build needs to connect to a real Paperclip server. Some of those servers, including the owner's homelab, sit behind an OIDC-protected reverse proxy, so a single hard-coded credential type isn't enough.

## What Changes

- Add a Paperclip HTTP client that acts as a board user. It sends typed requests, maps errors to typed errors, and lets the caller plug in authentication.
- Add a live `FactoryService` implementation that maps Paperclip companies, agents, issues, approvals, heartbeat runs and activity onto the existing domain models, and drives approve/reject, wake, pause and company pause.
- Add pluggable authentication. A provider decorates each request and can refresh after a `401`. Three kinds of provider ship:
  - none, for `local_trusted` servers;
  - a Paperclip board API key, typed in by the user or issued through Paperclip's browser sign-in challenge;
  - OIDC Authorization Code + PKCE, with discovery, Keychain-stored tokens and refresh-token rotation.

  Providers can be chained, so an OIDC token can satisfy a reverse proxy while a board key authenticates to Paperclip.

- Add a factory connection store. It validates a connection against the server before saving it, persists factories and their auth configuration, keeps secrets in the Keychain, and hands out a ready `FactoryService` per factory.
- Add a sandbox seed script and sandbox-gated contract tests that run the client against a throwaway Paperclip in Docker.
- The `FactoryService` protocol and the domain models stay unchanged.

## Capabilities

### New Capabilities

- `factory-connections`: connecting to a Paperclip server, validating it, saving and removing factories, and getting a live service for a saved factory.
- `factory-auth`: how Fabrix authenticates to a factory: no auth, board API key, browser sign-in, OIDC with refresh, and chained front-door plus Paperclip auth.

### Modified Capabilities

- `factory-service`: adds the live Paperclip implementation's behavior: status mapping, wake resuming paused agents, and tolerating hidden run telemetry.

## Impact

- Platforms: macOS, iPadOS and iOS. All code is shared and lives in `FabrixCore`. The macOS app keeps its sandbox with `network.client` and uses the data protection keychain.
- Targets: `FabrixCore` (new `Paperclip/`, `Auth/` and `Connections/` folders) and `FabrixCoreTests`. `FabrixDesign` and `FabrixFeatures` are untouched; the feature-screens work will call the new connection API.
- `FactoryService` protocol: unchanged. `Models.swift`: unchanged.
- New system frameworks: `Security` (Keychain) and `CryptoKit` (PKCE). There are no third-party dependencies. The browser step of OIDC sign-in is injected by the caller, so `FabrixCore` does not depend on SwiftUI.
- Tooling: `scripts/paperclip-sandbox-seed.sh`, and an update to the seed section of the `validate` skill.
- Reference: `docs/paperclip-api.md` lists every endpoint the client calls.
