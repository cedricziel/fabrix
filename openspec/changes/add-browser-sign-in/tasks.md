## 1. FabrixCore: sign-in requests and key expiry (PR: signin/core)

- [ ] 1.1 Decode `expiresAt` and keep the approval URL on the factory origin (`Paperclip/PaperclipClient.swift`, `Paperclip/PaperclipDTOs.swift`); tests `PaperclipClientTests.approvalURLStaysOnTheFactoryOrigin`, `challengeCarriesItsExpiry`
- [ ] 1.2 Stop waiting once `expiresAt` passes (`Connections/FactoryStore.swift`); test `FactoryStoreTests.browserSignInStopsAtItsExpiry`
- [ ] 1.3 `startReauthentication(of:clientName:)` (`Connections/FactoryStore.swift`); tests `reauthenticationKeepsTheFactoryAndReplacesOnlyTheKey`, `reauthenticationNeedsABoardKeyFactory`
- [ ] 1.4 `boardKeyExpiry()` and `FactoryService.credentialExpiry()` (`Paperclip/PaperclipClient.swift`, `Paperclip/PaperclipFactoryService.swift`, `FactoryService.swift`); tests `PaperclipFactoryServiceTests.reportsBoardKeyExpiry`, `noExpiryWhenTheKeyListIsUnavailable`

## 2. FabrixFeatures: browser sign-in in the app (PR: signin/ui)

- [ ] 2.1 Form methods with browser sign-in as default (`Logic/Connecting.swift`); tests `ConnectFormTests.browserSignInIsTheDefault`, `oidcWithBrowserNeedsNoKey`
- [ ] 2.2 Connector and `StoreConnector` browser sign-in (`Logic/Connecting.swift`, `Logic/StoreConnector.swift`); tests `StoreConnectorTests.browserMethodsMapToSignInFrontDoors`
- [ ] 2.3 Sign-in flow in `AppModel` (`AppModel.swift`); tests `AppModelTests.browserSignInOpensTheApprovalPageThenConnects`, `cancellingBrowserSignInStopsWaiting`, `expiredOrDeclinedSignInShowsItsMessage`
- [ ] 2.4 Re-sign-in on a rejected or expiring key (`AppModel.swift`); tests `rejectedKeyAsksToSignInAgainWithoutRepeatingErrors`, `signingInAgainKeepsTheFactory`, `expiringKeyOffersSignInAgain`
- [ ] 2.5 Waiting view, form wiring, shell banner and sheet (`Screens/BrowserSignInView.swift`, `Screens/OnboardingView.swift`, `Shell/SignInBanner.swift`, `RootView.swift`); no test, layout only, checked in both app builds and a Mac screenshot
- [ ] 2.6 Validate against the `/validate` sandbox, approving through the API
- [ ] 2.7 Archive the change
