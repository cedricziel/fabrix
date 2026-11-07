## 1. Paperclip client (stack layer 1)

- [x] 1.1 Document the endpoints Fabrix calls. Files: `docs/paperclip-api.md`. No test: documentation only.
- [x] 1.2 Add `PaperclipClient`, the DTOs and `PaperclipError`, with error mapping, the bearer header, URL normalization and browser sign-in requests. Files: `FabrixCore/Paperclip/PaperclipClient.swift`, `PaperclipDTOs.swift`, `PaperclipError.swift`. Tests: `PaperclipClientTests` (`mapsHTTPErrors`, `sendsBearerCredentialOnEveryRequest`, `normalizesServerURLs`, `startsBrowserSignIn`, `pollsBrowserSignIn`).
- [x] 1.3 Add the `StubURLProtocol`/`FakeServer` test support and fixtures shaped after Paperclip's shared types. Files: `FabrixCoreTests/Support/`. No test of its own: test infrastructure.

## 2. Live factory service (stack layer 2)

- [x] 2.1 Map Paperclip statuses and DTOs onto the domain models. Files: `FabrixCore/Paperclip/PaperclipMapping.swift`. Tests: `PaperclipFactoryServiceTests.mapsAgentStatus`, `mapsTaskStatus`, `mapsApprovalKind`, `mapsApprovalState`, `finishedRunWithoutFinishTimeIsNotLive`.
- [x] 2.2 Add `PaperclipFactoryService`: snapshot, decide, wake (resume first), pause, company pause, and an empty run list on 403. Files: `FabrixCore/Paperclip/PaperclipFactoryService.swift`. Tests: `PaperclipFactoryServiceTests.snapshot*`, `wakesPausedAgentByResumingFirst`, `snapshotToleratesHiddenRunTelemetry`, `setsCompanyPaused`.

## 3. Connection store (stack layer 3)

- [x] 3.1 Add `CredentialStore` with a Keychain implementation and an in-memory implementation. Files: `FabrixCore/Connections/CredentialStore.swift`. Test: covered through `FactoryStoreTests`; the Keychain item itself needs a signed app (design.md, Risks).
- [x] 3.2 Add `FactoryStore`: validate-then-save, persistence, reconnecting in place, remove, `service(for:)` and browser sign-in. Files: `FabrixCore/Connections/FactoryStore.swift`. Tests: `FactoryStoreTests` (`connectValidatesThenPersistsFactoryAndCredential`, `rejectedCredentialPersistsNothing`, `factoriesSurviveRelaunch`, `removeForgetsFactoryAndCredential`, `browserSignInPollsUntilApprovedThenConnects`).

## 4. Pluggable auth and OIDC (stack layer 4)

- [x] 4.1 Add the `AuthProvider` protocol with `NoAuth`, `BearerTokenAuth` and `ChainedAuth`, and route every `PaperclipClient` request through it, retrying once after a refresh on 401. Files: `FabrixCore/Auth/AuthProvider.swift`, `PaperclipClient.swift`. Tests: `AuthProviderTests.chainAppliesProvidersInOrder`, `PaperclipClientTests.retriesOnceAfterRefreshOn401`, `doesNotRetryWhenNothingRefreshed`.
- [x] 4.2 Add PKCE and OIDC discovery. Files: `FabrixCore/Auth/PKCE.swift`, `OIDCFlow.swift`. Tests: `OIDCFlowTests.pkceChallengeIsS256OfVerifier` (RFC 7636 appendix B vector), `discoversEndpoints`.
- [x] 4.3 Add the OIDC sign-in flow: authorize URL, `WebAuthenticator`, state check, error callback, code exchange. Files: `FabrixCore/Auth/OIDCFlow.swift`. Tests: `OIDCFlowTests.signInExchangesCodeWithVerifier`, `rejectsMismatchedState`, `surfacesProviderError`.
- [x] 4.4 Add `OIDCAuthProvider`: token placement header, refresh before expiry, refresh after 401, rotation, single-flight refresh, and `unauthorized` on `invalid_grant`. Files: `FabrixCore/Auth/OIDCAuthProvider.swift`. Tests: `OIDCAuthProviderTests.refreshesExpiringTokenAndStoresRotation`, `concurrentRequestsShareOneRefresh`, `rejectedRefreshIsUnauthorized`, `placesTokenInConfiguredHeader`.
- [x] 4.5 Store `FactoryAuthConfiguration` per factory in `FactoryStore`, add `connect(url:auth:boardKey:name:webAuthenticator:)` and `auth(for:)`, reject conflicting headers, and delete OIDC tokens on remove. Files: `FabrixCore/Connections/FactoryStore.swift`, `FabrixCore/Auth/FactoryAuthConfiguration.swift`. Tests: `FactoryStoreTests.connectsWithOIDCFrontDoorAndBoardKey`, `rejectsConflictingAuthorizationHeaders`, `oidcOnlyConnectionSendsNoBoardKey`, `removeDeletesOIDCTokens`, `authConfigurationSurvivesRelaunch`.

- [x] 4.6 Apply review fixes:
  - an OIDC refresh is scoped to the failing layer and token (`UnauthorizedResponse`);
  - rotated tokens are cached before saving;
  - browser sign-in works behind a front door;
  - discovery network errors map to `.transport`;
  - connect rolls back a partial secret write;
  - every waiter gets the `invalid_grant` mapping;
  - stale providers don't overwrite a newer sign-in (compare-and-swap);
  - a proxy 401 is recognized by `WWW-Authenticate`;
  - a failed save after a refresh still returns the fresh tokens.

  Files: `FabrixCore/Auth/`, `FabrixCore/Connections/FactoryStore.swift`, `PaperclipClient.swift`. Tests: `OIDCAuthProviderTests.paperclip401DoesNotRefreshOIDC`, `staleTokenRetriesWithoutAnotherRefresh`, `keepsRotatedTokensWhenSavingFails`, `OIDCFlowTests.discoveryNetworkFailureIsTransportError`, `FactoryStoreTests.failedSecondSecretWriteRollsBackTheFirst`, `browserSignInWorksBehindOIDCFrontDoor`, `OIDCAuthProviderTests.concurrentRequestsAllSeeRejectedRefreshAsUnauthorized`, `refreshAfterRemovalDoesNotRecreateTokens`, `refreshAfterReconnectKeepsTheNewSignIn`, `jsonProxy401StillRefreshes`.

## 5. Sandbox validation and archive (stack layer 5)

- [ ] 5.1 Add `scripts/paperclip-sandbox-seed.sh`: bootstrap a board user, create a board key, a company, agents, issues and an approval, and print `FABRIX_SANDBOX_URL`/`FABRIX_SANDBOX_KEY`. Files: `scripts/`. No Swift test: it is exercised by 5.2.
- [ ] 5.2 Add sandbox-gated contract tests that skip unless `FABRIX_SANDBOX_URL` is set: connect, snapshot, approve, pause and wake against the seeded server. Files: `FabrixCoreTests/SandboxContractTests.swift`. Test: `SandboxContractTests` (red against a stale client, green against the sandbox).
- [ ] 5.3 Update the seed section of the `validate` skill to match the script. Files: `.claude/skills/validate/SKILL.md`. No test: documentation.
- [ ] 5.4 Run the validate loop end to end, then archive this change as the last commit. Files: `openspec/`. No test: process.
