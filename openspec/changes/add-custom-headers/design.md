## Context

`PaperclipClient` asks an `AuthProvider` to decorate each request to the factory. The provider chain already carries the OIDC token and the board key, the client refuses any provider-added header over untrusted plain HTTP, and `SameOriginRedirects` refuses redirects to another origin. OIDC discovery and token requests go through `OIDCFlow`, which never sees the chain.

## Goals / Non-Goals

**Goals:** send custom headers with every request to the factory's origin, keep their values in the Keychain, and validate names up front.

**Non-Goals:** per-request or per-route headers; editing headers of a saved factory outside reconnecting; headers on OIDC requests.

## Decisions

- **Headers are one more `AuthProvider` layer** (`CustomHeadersAuth`, FabrixCore `Auth/`), first in the chain. Every rule that guards credentials then applies to them unchanged: the plain-HTTP refusal in `PaperclipClient.perform`, the same-origin redirect rule, and the absence from `OIDCFlow`. A separate header path in the client would duplicate those checks.
- **`CustomHeader`** (FabrixCore `Connections/`) is a public name/value struct. `CustomHeader.validated(_:for:)` trims, rejects bad or reserved names and duplicates, and checks clashes against a `FactoryAuthConfiguration`. It throws `PaperclipError.invalidAuthConfiguration` with a message for the form.
- **Storage:** the names go into the saved factory record (`StoredFactory.headerNames` in UserDefaults, optional so older records still decode). `FactoryAuthConfiguration` stays the description of sign-in only. The values go into one Keychain item per factory, account `<id>.headers`, as a JSON object from name to value. `remove(_:)` deletes it. Writes join the existing rollback in `validateAndSave`.
- **The form** keeps rows (id, name, value) in `ConnectForm`. It passes non-blank rows on, and FabrixCore validates them. The Advanced section starts collapsed and opens only when rows exist.

FabrixDesign still has no FabrixCore dependency.

## Risks / Trade-offs

- A header value shows up in any future request logging. Fabrix logs no headers today, and the PR asks the telemetry scrubber to add a guard.
- Header names are visible in UserDefaults. This is accepted, because names aren't secret.
