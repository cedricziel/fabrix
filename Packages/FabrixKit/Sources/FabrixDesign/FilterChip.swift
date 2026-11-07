import SwiftUI

/// An active filter shown as a capsule with a button that clears it.
public struct FilterChip<Leading: View>: View {
    private let title: String
    private let clearLabel: String
    private let onClear: () -> Void
    private let leading: Leading

    /// - Parameters:
    ///   - clearLabel: what the clear button says to VoiceOver, e.g. "Show all projects".
    public init(_ title: String, clearLabel: String, onClear: @escaping () -> Void, @ViewBuilder leading: () -> Leading) {
        self.title = title
        self.clearLabel = clearLabel
        self.onClear = onClear
        self.leading = leading()
    }

    public var body: some View {
        HStack(spacing: 6) {
            leading
            Text(title).lineLimit(1)
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Palette.steel)
                    .frame(width: 28, height: 28)
                    .contentShape(.rect.inset(by: -(minimumTapTarget - 28) / 2))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(clearLabel)
        }
        .font(.fabrix(.subheadline))
        .foregroundStyle(Palette.graphite)
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .background(Palette.card, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.hairline))
    }
}

extension FilterChip where Leading == EmptyView {
    public init(_ title: String, clearLabel: String, onClear: @escaping () -> Void) {
        self.init(title, clearLabel: clearLabel, onClear: onClear) { EmptyView() }
    }
}

#Preview("FilterChip") {
    VStack(alignment: .leading, spacing: Spacing.m) {
        FilterChip("Mobile app", clearLabel: "Show all projects", onClear: {}) {
            ProjectSwatch(colorHex: "#0F766E")
        }
        FilterChip("No project", clearLabel: "Show all projects", onClear: {})
    }
    .padding()
    .background(Palette.paper)
}
