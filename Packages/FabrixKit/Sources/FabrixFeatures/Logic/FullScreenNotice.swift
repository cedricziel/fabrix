import Foundation

extension AppModel {
    /// The server may have answered (401, 403), so "can't reach" is only one of the titles.
    var failedTitle: String {
        ConnectionStatus(
            connectionProblem, factory: factory?.name ?? String(localized: "the factory", bundle: .module),
            company: nil, lastRefreshedAt: nil
        )?.title ?? String(localized: "Can't reach the factory", bundle: .module)
    }

    /// What VoiceOver says when a full-screen problem replaces the app.
    var fullScreenAnnouncement: String? {
        if needsSignIn, loadState != .loaded {
            let reason = (signedOutReason ?? .boardKeyRejected).message(for: factory?.name)
            return String(localized: "\(reason) Sign in again.", bundle: .module)
        }
        guard case let .failed(message) = loadState else { return nil }
        return "\(failedTitle). \(message)"
    }
}
