## Why

Fabrix holds factory credentials and can approve hires, budgets and strategy or pause agents. Anyone holding an unlocked phone or an unattended Mac can do the same. An optional Face ID / Touch ID lock keeps the control room private without making the user sign in to every factory again.

## What Changes

- Add an optional app lock, off by default. Fabrix offers it once, on a sheet, after the user connects their first real (non-demo) factory: "Lock Fabrix with Face ID?", with Turn On and Not Now.
- Unlock method: "Biometrics or device passcode" (default) or "Biometrics only". Biometrics only falls back to the device passcode after a biometric lockout. The app shows only the methods the device supports and names the biometry correctly (Face ID, Touch ID, Optic ID).
- Lock timing: Immediately, After 1 minute (default), After 5 minutes, After 15 minutes. The time counts from when the app leaves the foreground. The app always locks on cold launch.
- A lock screen with the app mark, "Fabrix is locked" and an Unlock button. It prompts once each time the app comes to the foreground. No app content renders behind it.
- A privacy cover (the app mark and name on the paper background) hides the content while the app is inactive and the lock is on, so app-switcher snapshots and screen sharing don't show approvals or budgets.
- An optional "Confirm approvals with Face ID" setting, off by default. When it's on, approving or rejecting asks for authentication before the decision is staged.
- A Security section in a new Settings screen: the Settings scene on macOS, and a Settings sheet on iPhone and iPad.
- Background polling and staged decisions keep running while the app is locked. The lock gates the UI only.
- Add `NSFaceIDUsageDescription` to the iOS app.

Platforms: macOS, iPadOS, iOS. Targets: FabrixFeatures (lock model, screens, settings), FabrixDesign (brand mark and cover), app shells (Info.plist key through `project.yml`, the macOS Settings scene in `FabrixApp.swift`). The `FactoryService` protocol does not change.

## Capabilities

### New Capabilities

- `app-lock`: the optional biometric lock: settings, timing, the lock screen, the privacy cover, the first-connect offer and the approval confirmation.

### Modified Capabilities

None. Approvals keep their undo window and commit rules. The confirmation step is specified in `app-lock`.

## Impact

- New code in `Packages/FabrixKit/Sources/FabrixFeatures/Lock/` and a brand mark in FabrixDesign.
- `RootView` applies the lock with one modifier. The approval buttons go through the confirmation gate.
- `project.yml` gets `NSFaceIDUsageDescription`. `App/Shared/FabrixApp.swift` gets a macOS `Settings` scene (three lines).
- Links against LocalAuthentication. No new package dependencies.
- Credentials in the Keychain are unchanged.
