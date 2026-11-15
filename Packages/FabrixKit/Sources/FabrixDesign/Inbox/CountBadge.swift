import SwiftUI

/// Compact unread or item count badge. Zero counts are omitted.
public struct CountBadge: View {
    private let count: Int

    public init(_ count: Int) { self.count = count }

    nonisolated static func countBadgeText(_ count: Int) -> String? {
        guard count > 0 else { return nil }
        return count > 99 ? "99+" : String(count)
    }

    nonisolated static func countBadgeSpeech(_ count: Int) -> String? {
        guard count > 0 else { return nil }
        if count == 1 { return String(localized: "1 item", bundle: .module) }
        return String(localized: "\(count) items", bundle: .module)
    }

    public var body: some View {
        if let text = Self.countBadgeText(count) {
            Text(verbatim: text)
                .font(.fabrix(.label))
                .foregroundStyle(Palette.onSignal)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Palette.signal, in: Capsule())
                .accessibilityLabel(Text(verbatim: Self.countBadgeSpeech(count)!))
        }
    }
}

#Preview("Count badge light") { HStack { CountBadge(0); CountBadge(7); CountBadge(140) }.padding().background(Palette.paper) }
#Preview("Count badge dark") { HStack { CountBadge(0); CountBadge(7); CountBadge(140) }.padding().background(Palette.paper).preferredColorScheme(.dark) }
#Preview("Count badge accessibility") { HStack { CountBadge(0); CountBadge(7); CountBadge(140) }.padding().background(Palette.paper).dynamicTypeSize(.accessibility3) }

#Preview("Count badge") {
    HStack { CountBadge(0); CountBadge(7); CountBadge(140) }
        .padding().background(Palette.paper)
}
