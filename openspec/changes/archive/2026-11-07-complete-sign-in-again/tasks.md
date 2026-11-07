## 1. Sign in again everywhere (PR: fix/signin-followups)

- [x] 1.1 Log in to the identity provider again from `startReauthentication`, and add `signInAgainToIdentityProvider` (`Connections/FactoryStore.swift`); tests `FactoryStoreTests.reauthenticationWithABrowserLogsInToTheIdentityProviderAgain`, `oidcOnlyFactorySignsInToTheIdentityProviderAgain`, `identityProviderSignInAgainNeedsOIDC`
- [x] 1.2 Public `AppModel.signInAgain()`; an ended proxy session counts as signed out; OIDC-only factories sign in again through the identity provider (`AppModel.swift`, `Logic/Connecting.swift`, `Logic/StoreConnector.swift`, `RootView.swift`, `Screens/BrowserSignInView.swift`); tests `BrowserSignInTests.publicSignInAgainUsesTheAuthenticatorTheViewsProvide`, `oidcOnlyFactorySignsInAgainThroughTheIdentityProvider`, `expiredProxySessionOnABoardKeyFactoryAsksToSignInAgain`
- [x] 1.3 Reconnect form keeps the saved sign-in method, issuer and client ID (`Logic/Connecting.swift`); test `reconnectFormKeepsTheSingleSignOnSettings`
- [x] 1.4 Archive the change
