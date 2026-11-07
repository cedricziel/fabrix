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
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Dismiss")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .cardSurface()
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .contain)
        }
    }
}
