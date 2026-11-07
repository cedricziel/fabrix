import FabrixDesign
import SwiftUI

/// Shows why the last refresh or action failed while older data stays on screen.
struct ErrorBanner: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let message = model.lastError {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.halt)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(Palette.graphite)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    withAnimation { model.dismissError() }
                } label: {
                    Image(systemName: "xmark")
                        .frame(minWidth: Self.hitSize, minHeight: Self.hitSize)
                        .contentShape(.rect)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Dismiss")
            }
            .padding(.leading, 14)
            .padding(.trailing, 4)
            .padding(.vertical, Self.verticalPadding)
            .cardSurface()
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .contain)
        }
    }

    #if os(iOS)
    private static let hitSize: CGFloat = 44
    private static let verticalPadding: CGFloat = 0
    #else
    private static let hitSize: CGFloat = 28
    private static let verticalPadding: CGFloat = 6
    #endif
}

/// Reads new errors aloud with VoiceOver; the banner alone would go unnoticed.
struct ErrorAnnouncer: ViewModifier {
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content.onChange(of: model.lastError) { _, message in
            if let message {
                AccessibilityNotification.Announcement(message).post()
            }
        }
    }
}
