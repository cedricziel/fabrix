import SwiftUI

/// Lays content out in a row, or in a column at accessibility text sizes, so nothing truncates.
struct AdaptiveStack<Content: View>: View {
    private let spacing: CGFloat
    private let rowAlignment: VerticalAlignment
    private let content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    init(
        spacing: CGFloat = Spacing.s, rowAlignment: VerticalAlignment = .firstTextBaseline,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.rowAlignment = rowAlignment
        self.content = content()
    }

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: rowAlignment, spacing: spacing))
        layout { content }
    }
}

extension [String] {
    /// Joins phrases into sentences for VoiceOver, without doubling a full stop or question mark.
    nonisolated func spokenSentences() -> String {
        map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.last.map(".?!".contains) == true ? $0 : $0 + "." }
            .joined(separator: " ")
    }
}
