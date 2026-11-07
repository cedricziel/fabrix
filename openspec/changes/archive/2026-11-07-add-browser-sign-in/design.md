## Context

`FactoryStore.startSignIn` creates a CLI auth challenge, optionally behind an OIDC front door and with custom headers. `completeSignIn` polls it, then validates and saves the issued key. Re-saving an address that is already saved keeps the factory's ID. Paperclip's challenge response carries `approvalUrl` (built from the request's own host, so it can name an internal host behind a proxy), `approvalPath`, `expiresAt` and `suggestedPollIntervalMs`. `/api/cli-auth/me` returns the `keyId` of the board key in use, and `/api/board-api-keys` lists the user's keys with `expiresAt`.

## Goals / Non-Goals

**Goals:** browser sign-in from the connect form; re-sign-in that replaces only the key; key expiry warnings.

**Non-Goals:** an in-app web view (the user must already be signed in to Paperclip in their own browser); browser sign-in for OIDC-only factories, which use no Paperclip key.

## Decisions

- **Approval URL** (FabrixCore `PaperclipClient`): use `approvalUrl` only when its origin equals the factory's, and otherwise build `baseURL + approvalPath`. A proxy whose upstream reports an internal host still sends the user to the address they typed. `startSignIn` already refuses plain HTTP to a public host.
- **Expiry of the request** (FabrixCore `FactoryStore.completeSignIn`): stop with `signInExpired` once `expiresAt` has passed, even if the server never answers "expired". Transport errors don't end the poll, because returning from the background often drops the first requests; it retries until `expiresAt`.
- **Cancel is server-side too.** Cancel, closing the sheet, or opening another factory calls `POST /api/cli-auth/challenges/{id}/cancel`, so a later approval can't activate an unused key. A run token makes a second start a no-op while one runs, and ignores an approval that lands after Cancel.
- **Decisions while signed out** stay staged instead of failing, and go out once signing in again swaps the new key into the open factory.
- **Re-sign-in** (FabrixCore `FactoryStore.startReauthentication(of:clientName:)`): builds the challenge with the factory's saved headers and OIDC tokens, so there is no second IdP login. `completeSignIn` saves it under the same address, so the ID is kept and only the key changes. Only factories that use a board key can re-sign-in.
- **Key expiry** (FabrixCore): `PaperclipClient.boardKeyExpiry()` reads `keyId` from `/cli-auth/me`, then matches it in `/board-api-keys`. `FactoryService.credentialExpiry()` is a new protocol requirement with a default of nil, so the demo service and tests need no change.
- **Flow state** (FabrixFeatures `AppModel`):
  - `browserSignIn` is either waiting (approval URL, client name, expiry) or failed (message).
  - `connect(_:webAuthenticator:openURL:)` creates the challenge, opens the URL, then awaits a stored polling task. `cancelBrowserSignIn()` cancels that task, and cancellation returns to the form without an error.
  - A refresh that fails with `.unauthorized` on a factory that can re-sign-in sets `needsSignIn`, stops showing the error, and stops `keepFresh` from polling until a sign-in succeeds.
- **Opening the browser** happens in the view through `@Environment(\.openURL)`, which opens the default browser on macOS and Safari on iOS. The model receives it as a closure, so tests can record it.
- **UI** (FabrixFeatures):
  - `BrowserSignInView` shows the waiting and failed states. Onboarding uses it inside the connect card, and the shell shows it in a sheet for re-sign-in.
  - `SignInBanner` in the shell shows "Sign in again" when the key was rejected or expires soon.

FabrixDesign still has no FabrixCore dependency.

## Risks / Trade-offs

- On iOS the app may be suspended while the user approves. The polling task resumes when the app returns to the foreground, and the local `expiresAt` check ends it if the request ran out in the meantime.
- `/board-api-keys` might not be allowed for some keys. In that case Fabrix shows no expiry warning and relies on the 401.
