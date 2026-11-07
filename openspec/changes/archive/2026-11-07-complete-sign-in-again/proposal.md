## Why

Browser sign-in shipped in 0.3.0 with three gaps:

- "Sign in again" only worked for factories with a Paperclip key, and it reused saved OIDC tokens, so an ended proxy session couldn't be fixed.
- The reconnect form, shown when custom header values were lost, forgot the factory's single sign-on settings.
- The connection-health work needed an entry point it could call without passing anything from a view.

## What Changes

- "Sign in again" logs in to the identity provider again when a factory uses OIDC:
  - Before the browser approval, for OIDC in front of a Paperclip key.
  - On its own, for OIDC-only factories.
- An ended identity-provider session (`signInRequired`) counts as signed out, like a rejected key.
- The reconnect form opens with the saved sign-in method, issuer and client ID.
- `AppModel.signInAgain()` is public and uses the web authenticator the views provide.

Platforms: macOS, iPadOS and iOS. Targets: FabrixCore (`Connections/FactoryStore.swift`) and FabrixFeatures (`AppModel`, connector, form). `FactoryService` is unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `factory-connections`: "Sign in again" covers identity-provider logins, and the reconnect form keeps the sign-in settings.

## Impact

- `FabrixCore`: `FactoryStore.startReauthentication(of:clientName:webAuthenticator:)` and `signInAgainToIdentityProvider(of:webAuthenticator:)`.
- `FabrixFeatures`:
  - `FactoryConnector.startReauthentication(factoryID:webAuthenticator:)` and `signInAgainToIdentityProvider(factoryID:webAuthenticator:)`.
  - `FactoryConnection.usesOIDC` and `ReconnectNeeded.auth`.
  - `AppModel.webAuthenticator` and `AppModel.signInAgain()`.
