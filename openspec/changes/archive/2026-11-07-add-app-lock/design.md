## Context

Fabrix keeps factory credentials in the Keychain through `FactoryStore` and can approve hires, budgets and strategy. `RootView` already maps `scenePhase` to polling (`ScenePolicy.keepsPolling`) and to committing staged decisions (`ScenePolicy.commitsDecisions`). There is no Settings screen yet. Other sessions are changing the factory switcher (a title menu) and `FabrixApp.swift` (telemetry), so this change keeps its footprint in those places small.

## Goals / Non-Goals

**Goals:**

- An opt-in lock with a testable state machine and no `LAContext` in tests.
- One modifier in `RootView` applies the lock and the privacy cover.
- The lock gates the UI only. Polling and staged decisions are untouched.

**Non-Goals:**

- Protecting the Keychain items with `SecAccessControl` user presence (see Open Questions).
- Per-scene locks. All windows share one lock.

## Decisions

**`Authenticator` protocol (FabrixFeatures).** `@MainActor protocol Authenticator { var availableBiometry: Biometry; var canAuthenticate: Bool; func authenticate(_ policy: AuthenticationPolicy, reason: String) async -> AuthenticationResult }`. `DeviceAuthenticator` wraps a fresh `LAContext` per call and maps `LAError` to `.success`, `.cancelled`, `.failed`, `.biometryLockout`, `.unavailable`. `availableBiometry` reports the biometry type when it is enrolled, including while it is locked out, so "Biometrics only" stays visible and the fallback can run. Tests use a scripted stub. A result enum instead of `throws` keeps the state machine free of error casting.

**`AppLock` model (FabrixFeatures).** `@MainActor @Observable`. It owns `AppLockSettings` (a struct persisted to `UserDefaults` under `fabrix.lock.*`) and exposes `isLocked`, `isCovered`, `sceneWillResignActive()`, `sceneDidEnterBackground(at:)`, `sceneDidBecomeActive(at:)`, `unlock()`, `promptIfNeeded()`, `setEnabled(_:)`, `confirmDecision()`, `shouldOfferLock` and `markOffered()`. Times are passed in, so tests drive boundaries without a clock. The last-background time lives only in memory, which is also why a cold launch always locks.

- `isLocked` starts as `settings.isEnabled`.
- Going to the background always counts, even while a prompt is up, so leaving during an approval prompt still locks. A Mac app resigns active while the system prompt is up, so on macOS any prompt that started while the app was in front forgives the time away it caused, whatever its result; on iOS only a successful prompt does, because leaving the app cancels the prompt. An Immediately lock can't loop. Resign-active alone (the Face ID sheet on iOS) neither covers nor resets the once-per-foreground prompt while a prompt is running.
- `promptIfNeeded()` prompts at most once per foreground. The flag resets on `sceneDidEnterBackground`. The Unlock button calls `unlock()` directly.
- `biometricsOnly` tries `.deviceOwnerAuthenticationWithBiometrics`. On `.biometryLockout` it retries with `.deviceOwnerAuthentication`.
- `.unavailable` (no passcode set, so the device can't authenticate at all) unlocks and turns the lock and approval confirmation off. A device without a passcode has no secret to check against, and keeping the user out would strand their data. The toggle can't be turned on in that state.

Alternative considered: putting the state in `AppModel`. Rejected. `AppModel` is per window and per factory. The lock is per app and survives disconnects.

**One shared lock.** `AppLock.shared` uses `UserDefaults.standard` and `DeviceAuthenticator`. `RootView(factoryStore:)` and the Mac `Settings` scene both use it, so windows lock together and Settings edits apply at once, without threading an object through `FabrixApp.swift`. `RootView(model:lock:)` takes an injected lock for previews.

**Activation mapping.** The lock is app-wide, so it follows app activation, not each scene's phase; otherwise closing one iPad window would cover another. iOS and iPadOS: `UIApplication.willResignActiveNotification` → `sceneWillResignActive`, `didEnterBackgroundNotification` → `sceneDidEnterBackground`, `didBecomeActiveNotification` → `sceneDidBecomeActive`. macOS: `NSApplication.willResignActiveNotification` → resign and background, `didBecomeActiveNotification` → active.

**Applying the lock.** A `.appLock(_:)` modifier in `RootView` swaps the content for `LockScreen` while locked and hides the content from accessibility while covered. It sits inside the `.task` (polling) and `.onChange` (commit) modifiers, so those keep running while locked. The New task and Settings sheets attach inside it, so they close when the content goes away.

Sheets, dialogs and the Mac Settings window render outside that view, so the cover lives above them. iOS: each scene gets an overlay `UIWindow` at `.alert + 1` showing `BrandCover`; it also shows on `UIScene.willDeactivateNotification`, before SwiftUI's next update, so the snapshot never misses it. On `UIScene.didActivateNotification` it follows the app-wide state again, so an iPad window that returns while another window kept the app active doesn't stay covered. macOS: `WindowShield` adds a `BrandCover` view to every app window's frame view (SwiftUI owns the content view's subviews), and the modifier hides the window toolbar, which shows the company name. While locked, the Mac Settings window shows "Unlock Fabrix to change settings" instead of the form.

**Brand visuals (FabrixDesign).** `FabrixMark` draws the app icon's mark in SwiftUI from the same path as `scripts/render-app-icons.swift`, because the package can't load the app's `AppIcon` asset. `BrandCover` puts the mark and name on `Palette.paper` and takes optional content below. The lock screen and the privacy cover both use it. FabrixDesign still has no FabrixCore dependency.

**Approval confirmation.** `AppModel.decide(_:approve:confirmingWith:)` awaits `lock.confirmDecision()` and calls the existing `decide(_:approve:)` only on success. `confirmDecision()` returns true without prompting when the setting is off. The undo window and commit rules are unchanged.

**First-connect offer.** `AppModel` counts successful `connect(_:)` calls (`connectCount`). The demo and restored factories don't count. `RootView` watches it and checks `lock.shouldOfferLock` (lock off, the device can authenticate, never offered). It presents the offer once no other sheet is up, and the sheet calls `markOffered()` when it appears, which records `fabrix.lock.offered`. A connect from inside another sheet doesn't use up the offer.

**Settings entry points.** macOS: a `Settings { SettingsView() }` scene in `FabrixApp.swift`. iPhone: a Settings item in the Factory tab's More menu. iPad: a Settings button at the bottom of the sidebar (`safeAreaInset`), outside the factory list another session is reworking. Both iOS entries set `Navigator.showingSettings`.

## Risks / Trade-offs

- [macOS covers on every app switch] → this is the chosen default for screen sharing. It only applies while the lock is on.
- [No passcode set unlocks] → documented above; the toggle can't be turned on in that state.
- [Shared singleton] → limited to the app entry points; tests construct their own `AppLock`.

## Open Questions

- Follow-up: protect the board keys and OIDC tokens with `SecAccessControl(.userPresence)`. Not in this change, because background refreshes read them and would prompt on every poll. It would need a short-lived `LAContext` reuse window or moving the refreshes to after unlock.
