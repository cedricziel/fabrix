import Foundation
import Observation

/// The optional app lock. It gates the interface only: polling and staged decisions carry on.
@MainActor
@Observable
public final class AppLock {
    /// Shared by every window and the Mac Settings scene.
    public static let shared = AppLock()

    public private(set) var settings: AppLockSettings {
        didSet { settings.save(to: defaults) }
    }

    public private(set) var isLocked: Bool
    /// The privacy cover hides content while the app is inactive.
    public private(set) var isCovered = false
    public private(set) var isAuthenticating = false

    private let defaults: UserDefaults
    private let authenticator: any Authenticator
    /// In memory only, so a cold launch always locks.
    private var backgroundedAt: Date?
    private var promptedThisForeground = false

    public init(defaults: UserDefaults = .standard, authenticator: any Authenticator = DeviceAuthenticator()) {
        self.defaults = defaults
        self.authenticator = authenticator
        let settings = AppLockSettings(defaults: defaults)
        self.settings = settings
        isLocked = settings.isEnabled
    }

    // MARK: Settings

    public var method: UnlockMethod {
        get { biometry == .none ? .biometricsOrPasscode : settings.method }
        set { settings.method = newValue }
    }

    public var timeout: LockTimeout {
        get { settings.timeout }
        set { settings.timeout = newValue }
    }

    public var confirmsApprovals: Bool {
        get { settings.confirmsApprovals }
        set { settings.confirmsApprovals = newValue }
    }

    public var biometry: Biometry {
        authenticator.availableBiometry
    }

    public var canAuthenticate: Bool {
        authenticator.canAuthenticate
    }

    /// "Biometrics only" needs enrolled biometry.
    public var unlockOptions: [UnlockMethod] {
        biometry == .none ? [.biometricsOrPasscode] : UnlockMethod.allCases
    }

    public func label(for method: UnlockMethod) -> String {
        guard let name = biometry.name else { return Self.secretName.capitalized }
        return switch method {
        case .biometricsOrPasscode: String(localized: "\(name) or \(Self.secretName)")
        case .biometricsOnly: String(localized: "\(name) only")
        }
    }

    /// Face ID, or the passcode on a device without biometrics.
    public var factorName: String {
        biometry.name ?? Self.secretName
    }

    private static var secretName: String {
        #if os(macOS)
            String(localized: "password")
        #else
            String(localized: "passcode")
        #endif
    }

    /// Turning the lock on or off needs the owner.
    @discardableResult
    public func setEnabled(_ enabled: Bool) async -> Bool {
        guard enabled != settings.isEnabled else { return true }
        if enabled, !canAuthenticate {
            return false
        }
        let reason = enabled ? String(localized: "Turn on the Fabrix lock") : String(localized: "Turn off the Fabrix lock")
        let result = await authenticate(reason: reason)
        guard result == .success || (!enabled && result == .unavailable) else { return false }
        settings.isEnabled = enabled
        if !enabled {
            isLocked = false
            isCovered = false
        }
        return true
    }

    /// The first-connect offer: true once, while the lock is off and the device can authenticate.
    public func offerAfterConnect() -> Bool {
        guard !settings.wasOffered, !settings.isEnabled, canAuthenticate else { return false }
        settings.wasOffered = true
        return true
    }

    // MARK: Scene

    public func sceneWillResignActive() {
        guard !isAuthenticating else { return }
        isCovered = settings.isEnabled
    }

    /// iOS: the scene reached the background. macOS: the app resigned active.
    public func sceneDidEnterBackground(at date: Date) {
        // The system prompt deactivates the app; that isn't time away.
        guard !isAuthenticating else { return }
        isCovered = settings.isEnabled
        promptedThisForeground = false
        if backgroundedAt == nil {
            backgroundedAt = date
        }
    }

    public func sceneDidBecomeActive(at date: Date) {
        isCovered = false
        guard let since = backgroundedAt else { return }
        backgroundedAt = nil
        if settings.isEnabled, date.timeIntervalSince(since) >= timeout.interval {
            isLocked = true
        }
    }

    // MARK: Unlocking

    /// Asks once per foreground; after a cancel the user taps Unlock.
    public func promptIfNeeded() async {
        guard isLocked, !promptedThisForeground, !isAuthenticating else { return }
        promptedThisForeground = true
        await unlock()
    }

    @discardableResult
    public func unlock() async -> Bool {
        guard isLocked else { return true }
        let result = await authenticate(reason: String(localized: "Unlock Fabrix"))
        guard result == .success || result == .unavailable else { return false }
        isLocked = false
        backgroundedAt = nil
        return true
    }

    /// Re-authenticates before an approval decision when the user asked for it.
    public func confirmDecision() async -> Bool {
        guard settings.confirmsApprovals else { return true }
        let result = await authenticate(reason: String(localized: "Confirm your decision"))
        return result == .success || result == .unavailable
    }

    /// `.unavailable` means the device has no passcode: nothing to check against.
    private func authenticate(reason: String) async -> AuthenticationResult {
        guard !isAuthenticating else { return .cancelled }
        isAuthenticating = true
        defer { isAuthenticating = false }
        guard method == .biometricsOnly else {
            return await authenticator.authenticate(.biometricsOrPasscode, reason: reason)
        }
        let result = await authenticator.authenticate(.biometricsOnly, reason: reason)
        guard result == .biometryLockout || result == .unavailable else { return result }
        return await authenticator.authenticate(.biometricsOrPasscode, reason: reason)
    }
}
