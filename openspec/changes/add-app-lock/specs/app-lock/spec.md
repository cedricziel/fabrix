## Purpose

An optional Face ID / Touch ID lock that keeps Fabrix's factories, approvals and budgets private on an unlocked device, without changing how the app talks to factories.

## ADDED Requirements

### Requirement: Lock is opt-in

The app lock SHALL be off until the user turns it on. Turning it on, or off, SHALL require a successful authentication.

#### Scenario: Fresh install

- **WHEN** the user opens Fabrix for the first time
- **THEN** no lock screen appears

#### Scenario: Turning the lock on

- **WHEN** the user turns on the lock and authentication succeeds
- **THEN** the lock is on

#### Scenario: Authentication fails while turning it on

- **WHEN** the user turns on the lock and cancels or fails authentication
- **THEN** the lock stays off

### Requirement: First-connect offer

After the first successful connection to a real (non-demo) factory, the app SHALL offer the lock once, on a sheet titled with the device's biometry ("Lock Fabrix with Face ID?"), with Turn On and Not Now. The app SHALL never show the offer again.

#### Scenario: First real factory

- **WHEN** the user connects their first real factory and the device can authenticate
- **THEN** the offer appears

#### Scenario: Not Now

- **WHEN** the user picks Not Now and later connects another factory
- **THEN** the offer does not appear again and the lock stays off

#### Scenario: Demo factory

- **WHEN** the user explores the demo factory
- **THEN** no offer appears

### Requirement: Unlock methods

The app SHALL offer "Biometrics or device passcode" (the default) and "Biometrics only", and SHALL show only the methods the device supports. The biometric method SHALL be named after the device's biometry: Face ID, Touch ID or Optic ID. "Biometrics only" SHALL fall back to the device passcode after a biometric lockout.

#### Scenario: Device with Face ID

- **WHEN** the device has Face ID enrolled
- **THEN** the options are "Face ID or passcode" and "Face ID only"

#### Scenario: Device without enrolled biometrics

- **WHEN** no biometry is enrolled
- **THEN** only the passcode option is shown

#### Scenario: Biometric lockout

- **WHEN** the method is biometrics only and biometry is locked out after too many failed attempts
- **THEN** the app asks for the device passcode instead of keeping the user out

#### Scenario: Mac

- **WHEN** the lock is on on a Mac
- **THEN** Touch ID, the login password or a paired Apple Watch can unlock the app, as the system allows

### Requirement: When the app locks

The app SHALL lock on cold launch while the lock is on. Otherwise it SHALL lock when it returns to the foreground after being away at least the chosen time: Immediately, After 1 minute (the default), After 5 minutes or After 15 minutes. Time away SHALL count from when the app went to the background (iOS, iPadOS) or stopped being the active app (macOS).

#### Scenario: Cold launch

- **WHEN** the lock is on and the app launches
- **THEN** the lock screen shows

#### Scenario: Back within the time

- **WHEN** the setting is After 1 minute and the user returns after 59 seconds
- **THEN** the app is not locked

#### Scenario: Back after the time

- **WHEN** the setting is After 1 minute and the user returns after 60 seconds
- **THEN** the lock screen shows

#### Scenario: Immediately

- **WHEN** the setting is Immediately and the app leaves the foreground
- **THEN** the lock screen shows when it returns

#### Scenario: The authentication prompt itself

- **WHEN** the system authentication prompt makes the app briefly inactive
- **THEN** that does not count as time away

### Requirement: Lock screen

While locked, the app SHALL show only the lock screen (the app mark, "Fabrix is locked" and an Unlock button) and no factory content. It SHALL ask for authentication once each time it comes to the foreground. A failed or cancelled attempt SHALL leave the lock screen up with the Unlock button and SHALL NOT prompt again on its own.

#### Scenario: Prompt on appear

- **WHEN** the lock screen appears in the foreground
- **THEN** the app asks for authentication once

#### Scenario: Cancel

- **WHEN** the user cancels or fails authentication
- **THEN** the lock screen stays and no new prompt appears until the user taps Unlock or the app returns from the background

#### Scenario: Unlock

- **WHEN** authentication succeeds
- **THEN** the app shows where the user left off

#### Scenario: Open sheets

- **WHEN** the app locks while a sheet is open
- **THEN** the sheet closes

### Requirement: Privacy cover

While the lock is on, the app SHALL cover its content with the app mark and name whenever the app is inactive, so the app switcher and screen sharing don't show factory data.

#### Scenario: App switcher on iPhone and iPad

- **WHEN** the lock is on and the user opens the app switcher
- **THEN** the snapshot shows the cover, not the factory

#### Scenario: Mac loses focus

- **WHEN** the lock is on and the user switches to another app on a Mac
- **THEN** the Fabrix window shows the cover until it is active again

#### Scenario: Lock off

- **WHEN** the lock is off
- **THEN** no cover appears

### Requirement: Locking gates the interface only

Locking SHALL NOT stop background refreshes, and decisions already staged SHALL still be sent under the approval rules.

#### Scenario: Staged decision while locked

- **WHEN** the user approves, then the app goes to the background and locks
- **THEN** the decision is sent as usual

### Requirement: Confirm approvals

The app SHALL offer "Confirm approvals with Face ID" (named after the device's biometry), off by default. When on, approving or rejecting SHALL ask for authentication first, and the decision SHALL be staged only if it succeeds.

#### Scenario: Confirmed

- **WHEN** the setting is on and the user approves and authenticates
- **THEN** the decision is staged with its undo window

#### Scenario: Not confirmed

- **WHEN** the setting is on and the user cancels authentication
- **THEN** the approval stays waiting

### Requirement: Security settings

The app SHALL show the lock settings in a Security section of a Settings screen.

#### Scenario: Mac

- **WHEN** the user opens Fabrix > Settings on a Mac
- **THEN** the Security section shows

#### Scenario: iPad

- **WHEN** the user taps Settings at the bottom of the sidebar on an iPad
- **THEN** a Settings sheet with the Security section opens

#### Scenario: iPhone

- **WHEN** the user picks Settings from the More menu on the Factory tab
- **THEN** a Settings sheet with the Security section opens
