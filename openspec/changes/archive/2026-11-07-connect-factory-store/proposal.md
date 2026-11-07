## Why

The onboarding form collects a factory address and a sign-in method, but the app passed no connector, so Connect stayed disabled and the demo was the only way in. FabrixCore now has `FactoryStore`, which validates credentials against a Paperclip server and keeps them in the Keychain.

## What Changes

- The app connects through `FactoryStore`: Paperclip board key, OIDC, or OIDC in front of a board key. OIDC opens the identity provider's login page in a web authentication session.
- The connected factory reopens on the next launch; Switch factory leaves it without deleting its saved credentials.
- The note that connecting arrives in a later build is gone, because Connect now works.

Platforms: macOS, iPadOS and iOS. Targets: FabrixFeatures and `App/Shared`. `FactoryService` is unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `onboarding`: a connected factory is remembered like the demo, and connecting uses the server's real sign-in.

## Impact

- `FabrixFeatures`: `FactoryConnector` gains `restore(factoryID:)` and a web authenticator parameter; new `StoreConnector` and `SessionAuthenticator`.
- `App/Shared/FabrixApp.swift` creates `AppModel(connector: StoreConnector())`.
