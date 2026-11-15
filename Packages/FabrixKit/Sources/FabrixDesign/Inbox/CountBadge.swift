import SwiftUI

/// A signal-orange capsule with a count, for the Inbox tab and sidebar row. Hidden at 0, "99+" above 99.
public struct CountBadge: View {
    private let count: Int

    public init(_ count: Int) {
        self.count = count
    }

    nonisolated static func text(for count: Int) -> String? {
        switch count {
        case ...0: nil
        case 1...99: String(count)
        default: "99+"
        }
    }

    public var body: some View {
        if let text = Self.text(for: count) {
            Text(verbatim: text)
                .font(.fabrix(.label))
                .monospacedDigit()
                .foregroundStyle(Palette.onSignal)
                .padding(.horizontal, 7)
                .frame(minWidth: 20, minHeight: 20)
                .background(Palette.signal, in: Capsule())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(count) waiting", bundle: .module))
        }
    }
}

private struct CountBadgePreview: View {
    var body: some View {
        HStack(spacing: Spacing.m) {
            CountBadge(0)
            CountBadge(1)
            CountBadge(7)
            CountBadge(99)
            CountBadge(140)
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("CountBadge") { CountBadgePreview() }

#Preview("CountBadge · dark") { CountBadgePreview().preferredColorScheme(.dark) }

#Preview("CountBadge · accessibility") { CountBadgePreview().dynamicTypeSize(.accessibility3) }
