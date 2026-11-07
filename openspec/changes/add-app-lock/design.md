## Context

Fabrix keeps factory credentials in the Keychain through `FactoryStore` and can approve hires, budgets and strategy. `RootView` already maps `scenePhase` to polling (`ScenePolicy.keepsPolling`) and to committing staged decisions (`ScenePolicy.commitsDecisions`). There is no Settings screen yet. Other sessions are changing the factory switcher (a title menu) and `FabrixApp.swift` (telemetry), so this change keeps its footprint in those places small.

## Goals / Non-Goals

**Goals:**

- An opt-in lock with a testable state machine and no `LAContext` in tests.
- One modifier in `RootView` applies the lock and the privacy cover.
- The lock gates the UI only. Polling and staged decisions are untouched.

**Non-Goals:**

- Protecting the Keychain items with `SecAccessControl` user presence (see Open Questions).
- Covering sheets with the privacy cover. The cover sits under any open sheet. The only sheets are New task and Settings, and neither shows approvals or budgets.
- Per-scene locks. All windows share one lock.

## Decisions

**`Authenticator` protocol (FabrixFeatures).** `@MainActor protocol Authenticator { var availableBiometry: Biometry; var canAuthenticate: Bool; func authenticate(_ policy: AuthenticationPolicy, reason: String) async -> AuthenticationResult }`. `DeviceAuthenticator` wraps a fresh `LAContext` per call and maps `LAError` to `.success`, `.cancelled`, `.failed`, `.biometryLockout`, `.unavailable`. `availableBiometry` reports the biometry type when it is enrolled, including while it is locked out, so "Biometrics only" stays visible and the fallback can run. Tests use a scripted stub. A result enum instead of `throws` keeps the state machine free of error casting.

**`AppLock` model (FabrixFeatures).** `@MainActor @Observable`. It owns `AppLockSettings` (a struct persisted to `UserDefaults` under `fabrix.lock.*`) and exposes `isLocked`, `isCovered`, `sceneWillResignActive()`, `sceneDidEnterBackground(at:)`, `sceneDidBecomeActive(at:)`, `unlock()`, `promptIfNeeded()`, `setEnabled(_:)`, `confirmDecision()` and `offerAfterConnect()`. Times are passed in, so tests drive boundaries without a clock. The last-background time lives only in memory, which is also why a cold launch always locks.

- `isLocked` starts as `settings.isEnabled`.
- Background events are ignored while an authentication is running, so the system prompt (which makes a Mac app resign active) never counts as time away, and an Immediately lock can't loop.
- `promptIfNeeded()` prompts at most once per foreground. The flag resets on `sceneDidEnterBackground`. The Unlock button calls `unlock()` directly.
- `biometricsOnly` tries `.deviceOwnerAuthenticationWithBiometrics`. On `.biometryLockout` it retries with `.deviceOwnerAuthentication`.
- `.unavailable` (no passcode set, so the device can't authenticate at all) unlocks. A device without a passcode has no secret to check against, and keeping the user out would strand their data. The toggle is disabled in that state, so this only happens if the passcode is removed after turning the lock on.

Alternative considered: putting the state in `AppModel`. Rejected. `AppModel` is per window and per factory. The lock is per app and survives disconnects.

**One shared lock.** `AppLock.shared` uses `UserDefaults.standard` and `DeviceAuthenticator`. `RootView(factoryStore:)` and the Mac `Settings` scene both use it, so windows lock together and Settings edits apply at once, without threading an object through `FabrixApp.swift`. `RootView(model:lock:)` takes an injected lock for previews.

**Scene mapping.** iOS and iPadOS: `scenePhase` `.inactive` → `sceneWillResignActive`, `.background` → `sceneDidEnterBackground`, `.active` → `sceneDidBecomeActive`. macOS: `NSApplication.willResignActiveNotification` → resign and background, `didBecomeActiveNotification` → active. On macOS, `scenePhase` doesn't follow app activation.

**Applying the lock.** A `.appLock(_:)` modifier in `RootView` swaps the content for `LockScreen` while locked and overlays `PrivacyCover` while covered. It sits inside the `.task` (polling) and `.onChange` (commit) modifiers, so those keep running while locked. The New task and Settings sheets attach inside it, so they close when the content goes away.

**Brand visuals (FabrixDesign).** `FabrixMark` draws the app icon's mark in SwiftUI from the same path as `scripts/render-app-icons.swift`, because the package can't load the app's `AppIcon` asset. `BrandCover` puts the mark and name on `Palette.paper` and takes optional content below. The lock screen and the privacy cover both use it. FabrixDesign still has no FabrixCore dependency.

**Approval confirmation.** `AppModel.decide(_:approve:confirmingWith:)` awaits `lock.confirmDecision()` and calls the existing `decide(_:approve:)` only on success. `confirmDecision()` returns true without prompting when the setting is off. The undo window and commit rules are unchanged.

**First-connect offer.** `AppModel` counts successful `connect(_:)` calls (`connectCount`). The demo and restored factories don't count. `RootView` watches it and asks `lock.offerAfterConnect()`, which returns true once (lock off, the device can authenticate, never offered) and records `fabrix.lock.offered`.

**Settings entry points.** macOS: a `Settings { SettingsView() }` scene in `FabrixApp.swift`. iPhone: a Settings item in the Factory tab's More menu. iPad: a Settings button at the bottom of the sidebar (`safeAreaInset`), outside the factory list another session is reworking. Both iOS entries set `Navigator.showingSettings`.

## Risks / Trade-offs

- [Cover under sheets] → no sheet shows sensitive data today; revisit if one does.
- [macOS covers on every app switch] → this is the chosen default for screen sharing. It only applies while the lock is on.
- [No passcode set unlocks] → documented above; the toggle can't be turned on in that state.
- [Shared singleton] → limited to the app entry points; tests construct their own `AppLock`.

## Open Questions

- Follow-up: protect the board keys and OIDC tokens with `SecAccessControl(.userPresence)`. Not in this change, because background refreshes read them and would prompt on every poll. It would need a short-lived `LAContext` reuse window or moving the refreshes to after unlock.
