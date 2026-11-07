import Foundation

public enum UnlockMethod: String, CaseIterable, Identifiable, Sendable {
    case biometricsOrPasscode, biometricsOnly
    public var id: Self {
        self
    }
}

public enum LockTimeout: Int, CaseIterable, Identifiable, Sendable {
    case immediately = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900

    public var id: Self {
        self
    }

    var interval: TimeInterval {
        TimeInterval(rawValue)
    }
}

/// None of these are secrets, so they live in UserDefaults.
public struct AppLockSettings: Equatable, Sendable {
    public var isEnabled = false
    public var method = UnlockMethod.biometricsOrPasscode
    public var timeout = LockTimeout.oneMinute
    public var confirmsApprovals = false
    /// The first-connect offer was shown.
    public var wasOffered = false

    private enum Key {
        static let enabled = "fabrix.lock.enabled"
        static let method = "fabrix.lock.method"
        static let timeout = "fabrix.lock.timeout"
        static let confirmsApprovals = "fabrix.lock.confirmsApprovals"
        static let offered = "fabrix.lock.offered"
    }

    public init() {}

    init(defaults: UserDefaults) {
        isEnabled = defaults.bool(forKey: Key.enabled)
        method = defaults.string(forKey: Key.method).flatMap(UnlockMethod.init) ?? method
        timeout = (defaults.object(forKey: Key.timeout) as? Int).flatMap(LockTimeout.init) ?? timeout
        confirmsApprovals = defaults.bool(forKey: Key.confirmsApprovals)
        wasOffered = defaults.bool(forKey: Key.offered)
    }

    func save(to defaults: UserDefaults) {
        defaults.set(isEnabled, forKey: Key.enabled)
        defaults.set(method.rawValue, forKey: Key.method)
        defaults.set(timeout.rawValue, forKey: Key.timeout)
        defaults.set(confirmsApprovals, forKey: Key.confirmsApprovals)
        defaults.set(wasOffered, forKey: Key.offered)
    }
}
