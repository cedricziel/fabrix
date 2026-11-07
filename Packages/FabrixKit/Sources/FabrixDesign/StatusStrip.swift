import SwiftUI

/// A thin strip under the toolbar that says the shown data may be out of date, or that the
/// connection needs the user. One line with an icon, a title, an optional detail, and an action.
public struct StatusStrip: View {
    public enum Tone: Sendable, Equatable {
        /// Information about freshness, such as offline with old data.
        case stale
        /// Something on the server is wrong; the app keeps trying.
        case warning
        /// Nothing will work until the user acts, such as signing in again.
        case blocking
    }

    private let tone: Tone
    private let title: String
    private let detail: String?
    private let actionTitle: String?
    private let isBusy: Bool
    private let action: (() -> Void)?

    public init(
        _ tone: Tone, title: String, detail: String? = nil,
        actionTitle: String? = nil, isBusy: Bool = false, action: (() -> Void)? = nil
    ) {
        self.tone = tone
        self.title = title
        self.detail = detail
        self.actionTitle = actionTitle
        self.isBusy = isBusy
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .center, spacing: Spacing.s) {
            Image(systemName: tone.symbol)
                .foregroundStyle(tone.ink)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title).font(.fabrix(.label))
                if let detail {
                    Text(detail).font(.fabrix(.caption)).opacity(0.8)
                }
            }
            .foregroundStyle(tone.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            if isBusy {
                ProgressView().controlSize(.small)
            } else if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.fabrixSecondary)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(tone.tint, in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

extension StatusStrip.Tone {
    var symbol: String {
        switch self {
        case .stale: "wifi.slash"
        case .warning: "exclamationmark.triangle.fill"
        case .blocking: "person.crop.circle.badge.exclamationmark"
        }
    }

    var ink: Color {
        switch self {
        case .stale: Palette.neutralInk
        case .warning: Palette.signalInk
        case .blocking: Palette.haltInk
        }
    }

    var tint: Color {
        switch self {
        case .stale: Palette.neutralTint
        case .warning: Palette.signalTint
        case .blocking: Palette.haltTint
        }
    }
}

#Preview("Status strip") {
    VStack(spacing: Spacing.s) {
        StatusStrip(.stale, title: "Can't reach 58lab", detail: "Updated 3 min ago", actionTitle: "Retry") {}
        StatusStrip(.warning, title: "58lab had a problem (502)", detail: "Updated just now", isBusy: true)
        StatusStrip(.blocking, title: "Signed out of 58lab", actionTitle: "Sign in again") {}
    }
    .padding()
    .background(Palette.paper)
}
