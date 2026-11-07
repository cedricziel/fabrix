import FabrixDesign
import SwiftUI

/// The status strip for the open factory: offline, signed out, no access or a server problem,
/// with when the shown data last arrived and a way to act on it.
struct ConnectionStatusBar: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            if let status = status(now: max(context.date, model.lastRefreshedAt ?? context.date)) {
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
            lastRefreshedAt: model.lastRefreshedAt, canSignIn: model.needsSignIn, now: now
        ) {
            return problem
        }
        return model.keyExpiry.map { ConnectionStatus(keyExpiresAt: $0, factory: factory, now: now) }
    }

    private func isBusy(_ action: ConnectionStatus.Action?) -> Bool {
        switch action {
        case .signIn: model.browserSignIn != nil
        case .reconnect: false
        case .retry, nil: model.isRetrying
        }
    }

    private func perform(_ action: ConnectionStatus.Action?) {
        switch action {
        case .signIn:
            Task { await model.signInAgain() }
        case .reconnect:
            model.reconnectWithNewCredentials()
            navigator.showingAddFactory = true
        case .retry, nil:
            Task { await model.retry() }
        }
    }

    private func title(_ action: ConnectionStatus.Action) -> String {
        switch action {
        case .retry: String(localized: "Retry", bundle: .module)
        case .signIn: String(localized: "Sign in again", bundle: .module)
        case .reconnect: String(localized: "Reconnect", bundle: .module)
        }
    }
}

extension View {
    /// The connection strip and the action error banner above a content column, so they never
    /// cover the sidebar.
    func statusInsets() -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                ConnectionStatusBar()
                ErrorBanner()
            }
        }
    }
}
