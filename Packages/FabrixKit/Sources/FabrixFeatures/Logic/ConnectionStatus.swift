import FabrixDesign
import Foundation

/// What the status strip says about a connection problem.
struct ConnectionStatus: Equatable {
    enum Action: Equatable {
        case retry
        case signIn
        /// Signed out where Fabrix can't sign in again by itself: enter credentials again.
        case reconnect
    }

    var tone: StatusStrip.Tone
    var title: String
    var detail: String?
    var action: Action?

    init?(
        _ problem: ConnectionProblem?, factory: String, company: String?, lastRefreshedAt: Date?,
        canSignIn: Bool = true, now: Date = .now, locale: Locale = .current
    ) {
        guard let problem else { return nil }
        switch problem.issue {
        case .unreachable:
            tone = .stale
            title = String(localized: "Can't reach \(factory)", bundle: .module)
            action = .retry
        case .signedOut:
            tone = .blocking
            title = String(localized: "Signed out of \(factory)", bundle: .module)
            action = canSignIn ? .signIn : .reconnect
        case .noAccess:
            tone = .blocking
            title = String(localized: "No access to \(company ?? factory)", bundle: .module)
            action = .retry
        case let .serverProblem(status):
            tone = .warning
            title = status.map { String(localized: "\(factory) had a problem (\($0))", bundle: .module) }
                ?? String(localized: "\(factory) had a problem", bundle: .module)
            action = .retry
        case .unsupported:
            tone = .warning
            title = String(localized: "This server's version isn't supported yet", bundle: .module)
            action = nil
        }
        detail = Self.updated(lastRefreshedAt, now: now, locale: locale)
    }

    /// The board key still works but runs out soon; signing in again now avoids a lockout.
    init(keyExpiresAt expiry: Date, factory: String, now: Date = .now, locale: Locale = .current) {
        tone = .stale
        title = String(localized: "Fabrix's key for \(factory) expires \(Self.relative(expiry, to: now, locale: locale))", bundle: .module)
        detail = nil
        action = .signIn
    }

    private static func relative(_ date: Date, to now: Date, locale: Locale) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: now)
    }

    private static func updated(_ lastRefreshedAt: Date?, now: Date, locale: Locale) -> String? {
        lastRefreshedAt.map { date in
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = locale
            formatter.unitsStyle = .full
            formatter.dateTimeStyle = .named
            return String(localized: "Updated \(formatter.localizedString(for: min(date, now), relativeTo: now))", bundle: .module)
        }
    }
}

/// The sidebar's at-a-glance health of the open factory.
struct FactoryHealth: Equatable {
    var style: StatusStyle
    var label: String

    init(_ problem: ConnectionProblem?) {
        switch problem?.issue {
        case nil:
            style = .running
            label = String(localized: "Online", bundle: .module)
        case .unreachable:
            style = .paused
            label = String(localized: "Offline", bundle: .module)
        case .signedOut:
            style = .blocked
            label = String(localized: "Signed out", bundle: .module)
        case .noAccess:
            style = .blocked
            label = String(localized: "No access", bundle: .module)
        case .serverProblem, .unsupported:
            style = .needsYou
            label = String(localized: "Server problem", bundle: .module)
        }
    }
}
