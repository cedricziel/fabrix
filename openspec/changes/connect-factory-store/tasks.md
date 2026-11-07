## 1. Connect through FactoryStore

- [x] 1.1 Map the form's sign-in methods to `FactoryAuthConfiguration` (`Logic/StoreConnector.swift`); tests `StoreConnectorTests`
- [x] 1.2 Remember and reopen the connected factory (`AppModel.swift`, `Logic/Connecting.swift`); tests `connectedFactoryReopensOnNextLaunch`, `forgottenFactoryFallsBackToOnboarding`, `connectingReplacesTheDemoOnRelaunch`, `leavingAConnectedFactoryShowsOnboardingNextLaunch`
- [x] 1.3 Show OIDC login pages and pass the connector from the app (`Shell/SessionAuthenticator.swift`, `Screens/OnboardingView.swift`, `App/Shared/FabrixApp.swift`); no test, needs a real identity provider, checked in both app builds
- [x] 1.4 Archive the change
