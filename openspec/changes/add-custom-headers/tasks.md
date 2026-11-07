## 1. FabrixCore: custom headers (PR: headers/core)

- [ ] 1.1 `CustomHeader` and `CustomHeader.validated(_:for:)` (`Connections/CustomHeader.swift`); tests `CustomHeaderTests` (reserved, clashing, duplicate, invalid and multi-line names)
- [ ] 1.2 `CustomHeadersAuth` provider layer (`Auth/AuthProvider.swift`); tests `customHeadersAreAddedToRequests`, `customHeadersAreRefusedOverRemoteHTTP`, `customHeadersDoNotFollowRedirectsToAnotherOrigin` in `PaperclipClientTests`
- [ ] 1.3 Store names in `FactoryAuthConfiguration`, values in the Keychain, send them on connect, sign-in and restored services (`Auth/FactoryAuthConfiguration.swift`, `Connections/FactoryStore.swift`); tests in `FactoryStoreTests`: `customHeadersAreSentAndStoredInTheKeychain`, `customHeadersSurviveRelaunch`, `removeDeletesCustomHeaderValues`, `customHeadersAreNotSentToTheIdentityProvider`, `browserSignInSendsCustomHeaders`, `oldRecordsDecodeWithoutHeaderNames`

## 2. FabrixFeatures: connect form (PR: headers/ui)

- [ ] 2.1 Header rows in `ConnectForm` and the `headers` parameter on `FactoryConnector` and `StoreConnector` (`Logic/Connecting.swift`, `Logic/StoreConnector.swift`, `AppModel.swift`); tests `ConnectFormTests.blankHeaderRowsAreDropped`, `AppModelTests.connectingPassesCustomHeaders`
- [ ] 2.2 Advanced section with the Custom headers list (`Screens/OnboardingView.swift`); no test, layout only, checked in both app builds
- [ ] 2.3 Check a board-key connect with a custom header against the `/validate` sandbox
- [ ] 2.4 Archive the change
