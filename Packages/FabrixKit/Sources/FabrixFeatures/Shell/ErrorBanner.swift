import FabrixDesign
import SwiftUI

/// Shows why the user's last action failed. Connection problems go to the status strip.
struct ErrorBanner: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let message = model.actionError {
            NoticeBanner(systemImage: "exclamationmark.triangle.fill", tint: Palette.halt, message: message) {
                Button {
                    withAnimation { model.dismissActionError() }
                } label: {
                    Image(systemName: "xmark")
                        .frame(minWidth: NoticeBanner<EmptyView>.hitSize, minHeight: NoticeBanner<EmptyView>.hitSize)
                        .contentShape(.rect)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(.features("Dismiss"))
            }
        }
    }
}

/// A one-line notice above the shell with a trailing action.
struct NoticeBanner<Action: View>: View {
    let systemImage: String
    let tint: Color
    let message: String
    @ViewBuilder var action: Action

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(message)
                .font(.callout)
                .foregroundStyle(Palette.graphite)
                .frame(maxWidth: .infinity, alignment: .leading)
            action
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .padding(.vertical, Self.verticalPadding)
        .fabrixCard()
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .fabrixTransition(.slideIn(from: .top))
        .accessibilityElement(children: .contain)
    }

    #if os(iOS)
    static var hitSize: CGFloat { 44 }
    private static var verticalPadding: CGFloat { 0 }
    #else
    static var hitSize: CGFloat { 28 }
    private static var verticalPadding: CGFloat { 6 }
    #endif
}

/// Reads new errors aloud with VoiceOver; the banner alone would go unnoticed.
struct ErrorAnnouncer: ViewModifier {
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content
            .onChange(of: model.actionError) { _, message in
                if let message { AccessibilityNotification.Announcement(message).post() }
            }
            .onChange(of: model.connectionProblem?.issue) { _, issue in
                if issue != nil, let detail = model.connectionProblem?.detail {
                    AccessibilityNotification.Announcement(detail).post()
                }
            }
    }
}
