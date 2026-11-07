## 1. Lock core and settings (PR 1)

- [x] 1.1 Add `Biometry`, `AuthenticationPolicy`, `AuthenticationResult`, the `Authenticator` protocol and `DeviceAuthenticator` over `LAContext` (FabrixFeatures `Lock/Authenticator.swift`). No test: a thin system wrapper; the stub covers callers.
- [x] 1.2 Add `AppLockSettings` (unlock method, timeout, confirm approvals, enabled, offered) persisted to UserDefaults (`Lock/AppLockSettings.swift`). Test: `AppLockTests.settingsPersistAcrossInstances`.
- [x] 1.3 Add `AppLock` timing: cold launch lock, grace-period boundaries per option, ignoring background while authenticating (`Lock/AppLock.swift`). Tests: `AppLockTests.coldLaunchLocks`, `gracePeriodBoundaries` (parameterized over every timeout), `authenticationPromptIsNotTimeAway`.
- [x] 1.4 Add unlock and the once-per-foreground prompt. Tests: `failedOrCancelledUnlockStaysLocked`, `autoPromptRunsOncePerForeground`, `biometricsOnlyFallsBackToPasscode`.
- [x] 1.5 Add unlock options from the device biometry and their names. Tests: `optionsMatchBiometry` (parameterized: none, Touch ID, Face ID, Optic ID).
- [x] 1.6 Add `setEnabled(_:)` behind authentication, `confirmDecision()` and `offerAfterConnect()`. Tests: `enablingRequiresAuthentication`, `offerAppearsExactlyOnce`.
- [x] 1.7 Add `NSFaceIDUsageDescription` to the iOS Info.plist (`project.yml`). No test: config.

## 2. Lock UI (PR 2)

- [ ] 2.1 Add `FabrixMark` and `BrandCover` (FabrixDesign `Brand.swift`). No test: visual only.
- [ ] 2.2 Add `AppModel.connectCount` and `decide(_:approve:confirmingWith:)` (FabrixFeatures `AppModel.swift`, `Lock/AppLock+Approvals.swift`). Tests: `AppLockTests.approvalGateBlocksDecisionWhenAuthenticationFails`, `AppModelTests.connectingCountsOnlyRealFactories`.
- [ ] 2.3 Add `LockScreen`, `PrivacyCover` and the `.appLock(_:)` modifier with scene mapping; apply it in `RootView` (`Lock/LockViews.swift`, `RootView.swift`). No test: view wiring; the state machine is covered in 1.3–1.4.
- [ ] 2.4 Route Approve and Reject in `ApprovalsView` and `OverviewView` through the gate. Covered by 2.2.
- [ ] 2.5 Add `SettingsView` with the Security section, the first-connect offer sheet, the iPhone More menu item, the iPad sidebar button and the macOS `Settings` scene (`Lock/SettingsView.swift`, `Shell/`, `App/Shared/FabrixApp.swift`). No test: view wiring.
- [ ] 2.6 Archive the OpenSpec change.
