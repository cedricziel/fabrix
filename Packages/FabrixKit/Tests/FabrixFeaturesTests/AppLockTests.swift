import FabrixCore
@testable import FabrixFeatures
import Foundation
import Testing

@MainActor
final class StubAuthenticator: Authenticator {
    var availableBiometry: Biometry
    var canAuthenticate = true
    /// Answers in order; the last one repeats.
    var results: [AuthenticationResult]
    private(set) var calls: [AuthenticationPolicy] = []
    /// Runs while the prompt is up.
    var onAuthenticate: (() -> Void)?

    init(biometry: Biometry = .faceID, results: [AuthenticationResult] = [.success]) {
        availableBiometry = biometry
        self.results = results
    }

    func authenticate(_ policy: AuthenticationPolicy, reason _: String) async -> AuthenticationResult {
        calls.append(policy)
        onAuthenticate?()
        return results.count > 1 ? results.removeFirst() : results[0]
    }
}

@MainActor
struct AppLockTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    private func freshDefaults() -> UserDefaults {
        let name = "AppLockTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    /// A lock that is on and unlocked, as after a successful prompt.
    private func enabledLock(
        timeout: LockTimeout = .oneMinute, authenticator: StubAuthenticator = StubAuthenticator()
    ) async -> AppLock {
        let lock = AppLock(defaults: freshDefaults(), authenticator: authenticator)
        lock.timeout = timeout
        await lock.setEnabled(true)
        authenticator.results = [.success]
        return lock
    }

    @Test func offByDefault() {
        let lock = AppLock(defaults: freshDefaults(), authenticator: StubAuthenticator())
        #expect(!lock.settings.isEnabled)
        #expect(!lock.isLocked)
        #expect(lock.timeout == .oneMinute)
        #expect(lock.method == .biometricsOrPasscode)
        #expect(!lock.confirmsApprovals)
    }

    @Test func settingsPersistAcrossInstances() async {
        let defaults = freshDefaults()
        let lock = AppLock(defaults: defaults, authenticator: StubAuthenticator())
        await lock.setEnabled(true)
        lock.timeout = .fifteenMinutes
        lock.method = .biometricsOnly
        lock.confirmsApprovals = true

        let relaunched = AppLock(defaults: defaults, authenticator: StubAuthenticator())
        #expect(relaunched.settings.isEnabled)
        #expect(relaunched.timeout == .fifteenMinutes)
        #expect(relaunched.method == .biometricsOnly)
        #expect(relaunched.confirmsApprovals)
    }

    @Test func coldLaunchLocks() async {
        let defaults = freshDefaults()
        await AppLock(defaults: defaults, authenticator: StubAuthenticator()).setEnabled(true)
        #expect(AppLock(defaults: defaults, authenticator: StubAuthenticator()).isLocked)
    }

    @Test func enablingRequiresAuthentication() async {
        let authenticator = StubAuthenticator(results: [.cancelled])
        let lock = AppLock(defaults: freshDefaults(), authenticator: authenticator)
        #expect(await !lock.setEnabled(true))
        #expect(!lock.settings.isEnabled)

        authenticator.canAuthenticate = false
        authenticator.results = [.success]
        #expect(await !lock.setEnabled(true))

        authenticator.canAuthenticate = true
        #expect(await lock.setEnabled(true))
        #expect(lock.settings.isEnabled)
        #expect(!lock.isLocked)
    }

    @Test func disablingRequiresAuthentication() async {
        let authenticator = StubAuthenticator()
        let lock = await enabledLock(authenticator: authenticator)
        authenticator.results = [.failed]
        #expect(await !lock.setEnabled(false))
        #expect(lock.settings.isEnabled)
    }

    @Test(arguments: LockTimeout.allCases)
    func gracePeriodBoundaries(timeout: LockTimeout) async {
        let lock = await enabledLock(timeout: timeout)
        let grace = TimeInterval(timeout.rawValue)

        if grace > 0 {
            lock.sceneDidEnterBackground(at: start)
            lock.sceneDidBecomeActive(at: start.addingTimeInterval(grace - 1))
            #expect(!lock.isLocked, "back within \(timeout)")
        }

        lock.sceneDidEnterBackground(at: start)
        lock.sceneDidBecomeActive(at: start.addingTimeInterval(grace))
        #expect(lock.isLocked, "back after \(timeout)")
    }

    @Test func nothingLocksWhileOff() {
        let lock = AppLock(defaults: freshDefaults(), authenticator: StubAuthenticator())
        lock.sceneWillResignActive()
        lock.sceneDidEnterBackground(at: start)
        #expect(!lock.isCovered)
        lock.sceneDidBecomeActive(at: start.addingTimeInterval(3600))
        #expect(!lock.isLocked)
    }

    @Test func coverShowsWhileInactive() async {
        let lock = await enabledLock()
        lock.sceneWillResignActive()
        #expect(lock.isCovered)
        lock.sceneDidBecomeActive(at: start)
        #expect(!lock.isCovered)
    }

    @Test func successfulPromptThatDeactivatesTheAppIsNotTimeAway() async {
        let authenticator = StubAuthenticator()
        let lock = await enabledLock(timeout: .immediately, authenticator: authenticator)
        lock.confirmsApprovals = true

        // On a Mac the system prompt makes the app resign active while it is up.
        authenticator.onAuthenticate = { lock.sceneWillResignActive(); lock.sceneDidEnterBackground(at: start) }
        #expect(await lock.confirmDecision())
        lock.sceneDidBecomeActive(at: start.addingTimeInterval(5))

        #expect(!lock.isLocked)
        #expect(!lock.isCovered)
    }

    @Test func backgroundingDuringAPromptLocks() async {
        let authenticator = StubAuthenticator()
        let lock = await enabledLock(authenticator: authenticator)
        lock.confirmsApprovals = true
        authenticator.results = [.cancelled]

        // iOS: the user goes Home while the Face ID prompt for an approval is up.
        authenticator.onAuthenticate = { lock.sceneDidEnterBackground(at: start) }
        #expect(await !lock.confirmDecision())
        #expect(lock.isCovered)
        lock.sceneDidBecomeActive(at: start.addingTimeInterval(2 * 3600))

        #expect(lock.isLocked)
    }

    @Test func cancelledPromptThatDeactivatesTheAppDoesNotPromptAgain() async {
        let authenticator = StubAuthenticator()
        let lock = await enabledLock(timeout: .immediately, authenticator: authenticator)
        lock.sceneDidEnterBackground(at: start)
        lock.sceneDidBecomeActive(at: start)
        authenticator.results = [.cancelled]
        authenticator.onAuthenticate = { lock.sceneWillResignActive(); lock.sceneDidEnterBackground(at: start) }
        let before = authenticator.calls.count

        await lock.promptIfNeeded()
        lock.sceneDidBecomeActive(at: start)
        await lock.promptIfNeeded()

        #expect(authenticator.calls.count == before + 1)
        #expect(lock.isLocked)
    }

    @Test(arguments: [AuthenticationResult.cancelled, .failed])
    func failedOrCancelledUnlockStaysLocked(result: AuthenticationResult) async {
        let authenticator = StubAuthenticator()
        let lock = await enabledLock(timeout: .immediately, authenticator: authenticator)
        lock.sceneDidEnterBackground(at: start)
        lock.sceneDidBecomeActive(at: start)
        authenticator.results = [result]

        #expect(await !lock.unlock())
        #expect(lock.isLocked)
    }

    @Test func autoPromptRunsOncePerForeground() async {
        let authenticator = StubAuthenticator()
        let lock = await enabledLock(timeout: .immediately, authenticator: authenticator)
        lock.sceneDidEnterBackground(at: start)
        lock.sceneDidBecomeActive(at: start)
        authenticator.results = [.cancelled]
        let before = authenticator.calls.count

        await lock.promptIfNeeded()
        // iOS: the Face ID sheet makes the scene inactive, then active again.
        lock.sceneWillResignActive()
        lock.sceneDidBecomeActive(at: start)
        await lock.promptIfNeeded()
        #expect(authenticator.calls.count == before + 1)
        #expect(lock.isLocked)

        // The Unlock button still works.
        authenticator.results = [.success]
        #expect(await lock.unlock())

        // A new foreground prompts again.
        lock.sceneDidEnterBackground(at: start)
        lock.sceneDidBecomeActive(at: start)
        await lock.promptIfNeeded()
        #expect(!lock.isLocked)
        #expect(authenticator.calls.count == before + 3)
    }

    @Test(arguments: [AuthenticationResult.biometryLockout, .unavailable])
    func biometricsOnlyFallsBackToPasscode(first: AuthenticationResult) async {
        let authenticator = StubAuthenticator()
        let lock = await enabledLock(timeout: .immediately, authenticator: authenticator)
        lock.method = .biometricsOnly
        lock.sceneDidEnterBackground(at: start)
        lock.sceneDidBecomeActive(at: start)
        authenticator.results = [first, .success]
        let before = authenticator.calls.count

        #expect(await lock.unlock())
        #expect(Array(authenticator.calls.dropFirst(before)) == [.biometricsOnly, .biometricsOrPasscode])
    }

    @Test func biometricsOnlyDoesNotFallBackOnCancel() async {
        let authenticator = StubAuthenticator()
        let lock = await enabledLock(timeout: .immediately, authenticator: authenticator)
        lock.method = .biometricsOnly
        lock.sceneDidEnterBackground(at: start)
        lock.sceneDidBecomeActive(at: start)
        authenticator.results = [.cancelled]
        let before = authenticator.calls.count

        #expect(await !lock.unlock())
        #expect(Array(authenticator.calls.dropFirst(before)) == [.biometricsOnly])
    }

    @Test(arguments: [
        (Biometry.none, ["Passcode"]),
        (.touchID, ["Touch ID or passcode", "Touch ID only"]),
        (.faceID, ["Face ID or passcode", "Face ID only"]),
        (.opticID, ["Optic ID or passcode", "Optic ID only"]),
    ])
    func optionsMatchBiometry(biometry: Biometry, labels: [String]) {
        let lock = AppLock(defaults: freshDefaults(), authenticator: StubAuthenticator(biometry: biometry))
        let expected = labels.map {
            #if os(macOS)
                $0.replacingOccurrences(of: "passcode", with: "password").replacingOccurrences(of: "Passcode", with: "Password")
            #else
                $0
            #endif
        }
        #expect(lock.unlockOptions.map(lock.label(for:)) == expected)
    }

    @Test func biometricsOnlyIsIgnoredWithoutBiometry() {
        let authenticator = StubAuthenticator()
        let lock = AppLock(defaults: freshDefaults(), authenticator: authenticator)
        lock.method = .biometricsOnly
        authenticator.availableBiometry = .none
        #expect(lock.method == .biometricsOrPasscode)
    }

    @Test func offerAppearsExactlyOnce() {
        let defaults = freshDefaults()
        let lock = AppLock(defaults: defaults, authenticator: StubAuthenticator())
        #expect(lock.shouldOfferLock)
        // Due until the sheet is actually on screen.
        #expect(lock.shouldOfferLock)
        lock.markOffered()
        #expect(!lock.shouldOfferLock)
        #expect(!AppLock(defaults: defaults, authenticator: StubAuthenticator()).shouldOfferLock)
        #expect(!lock.settings.isEnabled)
    }

    @Test func offerWaitsForADeviceThatCanAuthenticate() {
        let authenticator = StubAuthenticator()
        authenticator.canAuthenticate = false
        let lock = AppLock(defaults: freshDefaults(), authenticator: authenticator)
        #expect(!lock.shouldOfferLock)
        authenticator.canAuthenticate = true
        #expect(lock.shouldOfferLock)
    }

    @Test func confirmationIsSkippedWhileOff() async {
        let authenticator = StubAuthenticator(results: [.failed])
        let lock = AppLock(defaults: freshDefaults(), authenticator: authenticator)
        #expect(await lock.confirmDecision())
        #expect(authenticator.calls.isEmpty)

        lock.confirmsApprovals = true
        #expect(await !lock.confirmDecision())
    }
}
