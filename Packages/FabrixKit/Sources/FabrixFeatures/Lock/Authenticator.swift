import Foundation
import LocalAuthentication

public enum Biometry: Equatable, Sendable {
    case none, touchID, faceID, opticID

    var name: String? {
        switch self {
        case .none: nil
        case .touchID: "Touch ID"
        case .faceID: "Face ID"
        case .opticID: "Optic ID"
        }
    }
}

public enum AuthenticationPolicy: Equatable, Sendable {
    /// Biometrics, the device passcode or (on a Mac) a paired Apple Watch.
    case biometricsOrPasscode
    case biometricsOnly
}

public enum AuthenticationResult: Equatable, Sendable {
    case success, cancelled, failed, biometryLockout
    /// The device can't authenticate at all, e.g. no passcode is set.
    case unavailable
}

@MainActor
public protocol Authenticator {
    /// The enrolled biometry, also while it is locked out.
    var availableBiometry: Biometry { get }
    /// Whether the device can authenticate the owner at all.
    var canAuthenticate: Bool { get }
    func authenticate(_ policy: AuthenticationPolicy, reason: String) async -> AuthenticationResult
}

/// LocalAuthentication, with a fresh context per call so one success doesn't unlock the next prompt.
public struct DeviceAuthenticator: Authenticator {
    public init() {}

    public var availableBiometry: Biometry {
        let context = LAContext()
        var error: NSError?
        let usable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        guard usable || error?.code == LAError.biometryLockout.rawValue else { return .none }
        return switch context.biometryType {
        case .touchID: .touchID
        case .faceID: .faceID
        case .opticID: .opticID
        default: .none
        }
    }

    public var canAuthenticate: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    public func authenticate(_ policy: AuthenticationPolicy, reason: String) async -> AuthenticationResult {
        let laPolicy: LAPolicy = switch policy {
        case .biometricsOrPasscode: .deviceOwnerAuthentication
        case .biometricsOnly: .deviceOwnerAuthenticationWithBiometrics
        }
        do {
            return try await LAContext().evaluatePolicy(laPolicy, localizedReason: reason) ? .success : .failed
        } catch let error as LAError {
            return switch error.code {
            case .userCancel, .appCancel, .systemCancel, .userFallback: .cancelled
            case .biometryLockout: .biometryLockout
            case .passcodeNotSet, .biometryNotAvailable, .biometryNotEnrolled: .unavailable
            default: .failed
            }
        } catch {
            return .failed
        }
    }
}
