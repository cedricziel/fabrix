## Why

FabrixCore can already run Paperclip's browser sign-in (the CLI auth challenge), but no screen reaches it. Users have to create a board key somewhere else and paste it, and board keys expire after 30 days. When a key expires, the app keeps polling and shows the same error again and again.

## What Changes

- "Sign in with browser" becomes the default method in the connect form. Fabrix creates a challenge and opens the approval page in the user's own browser, where they are already signed in to Paperclip. It then waits for approval and connects with the issued key. "Paperclip API key" stays for pasting a key.
- Single sign-on in front of Paperclip can get its key the same way: a new "Single sign-on + browser sign-in" method uses the proxy login and then the browser approval.
- The waiting state shows "Approve Fabrix in your browser", the client name, Copy link and Cancel. It ends with a clear message and Try again when the request expires or is cancelled.
- When a saved factory rejects its board key, refreshing stops and the app offers "Sign in again". This runs the browser flow for that factory and replaces only its key. The factory keeps its ID, custom headers and OIDC settings.
- Fabrix reads the board key's expiry and offers "Sign in again" when fewer than 5 days are left.
- The approval page always uses the factory's own origin, under the same transport rule as credentials.

Platforms: macOS, iPadOS and iOS. Targets: FabrixCore (`Paperclip/`, `Connections/`) and FabrixFeatures (connect form, `AppModel`, shell). `FactoryService` gains `credentialExpiry()`, an additive change with a default of nil.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `onboarding`: browser sign-in is the default way to connect.
- `factory-connections`: re-sign-in for a saved factory, the approval URL origin, and expiry of the sign-in request.
- `factory-service`: the live factory reports when its board key expires.

## Impact

- `FabrixCore`:
  - `SignInChallenge.expiresAt`.
  - `FactoryStore.startReauthentication(of:clientName:)`.
  - `completeSignIn` stops at `expiresAt`.
  - `PaperclipClient.boardKeyExpiry()`.
  - `FactoryService.credentialExpiry()`.
- `FabrixFeatures`:
  - `FactoryAuth.browser` and `.oidcWithBrowser`.
  - `FactoryConnector` gains `startBrowserSignIn`, `completeBrowserSignIn` and `startReauthentication`.
  - `AppModel` gains sign-in state and a re-sign-in prompt.
  - New `BrowserSignInView`.
- Secrets: the challenge token and the issued key never appear in logs or error messages.
