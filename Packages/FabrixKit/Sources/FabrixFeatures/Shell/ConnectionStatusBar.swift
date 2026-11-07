import FabrixDesign
import SwiftUI

/// The status strip for the open factory: offline, signed out, no access or a server problem,
/// with when the shown data last arrived and a way to act on it.
struct ConnectionStatusBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            if let status = status(now: context.date) {
                StatusStrip(
                    status.tone, title: status.title, detail: status.detail,
                    actionTitle: status.action.map(title), isBusy: isBusy(status.action)
                ) {
                    perform(status.action)
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    /// A connection problem first; otherwise a board key that runs out soon.
    private func status(now: Date) -> ConnectionStatus? {
        let factory = model.factory?.name ?? "Fabrix"
        if let problem = ConnectionStatus(
            model.connectionProblem, factory: factory, company: model.snapshot?.company.name,
            lastRefreshedAt: model.lastRefreshedAt, canSignIn: model.canSignInAgain, now: now
        ) {
            return problem
        }
        return model.keyExpiry.map { ConnectionStatus(keyExpiresAt: $0, factory: factory, now: now) }
    }

    private func isBusy(_ action: ConnectionStatus.Action?) -> Bool {
        action == .signIn ? model.browserSignIn != nil : model.isRefreshing
    }

    private func perform(_ action: ConnectionStatus.Action?) {
        switch action {
        case .signIn:
            Task { await model.signInAgain() }
        case .retry, nil:
            Task { await model.refresh() }
        }
    }

    private func title(_ action: ConnectionStatus.Action) -> String {
        switch action {
        case .retry: String(localized: "Retry", bundle: .module)
        case .signIn: String(localized: "Sign in again", bundle: .module)
        }
    }
}
