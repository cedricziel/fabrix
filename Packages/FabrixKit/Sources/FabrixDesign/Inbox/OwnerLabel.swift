import SwiftUI

/// Who an inbox card is for.
public enum InboxOwner: Equatable, Sendable {
    case you
    case person(String)
    case unassigned
    case transferredToYou(by: String)

    nonisolated var displayName: String {
        switch self {
        case .you: String(localized: "You", bundle: .module)
        case let .person(name): name
        case .unassigned: String(localized: "Unassigned", bundle: .module)
        case let .transferredToYou(name): String(localized: "You, transferred by \(name)", bundle: .module)
        }
    }

    nonisolated var spoken: String {
        switch self {
        case .you: String(localized: "For you", bundle: .module)
        case let .person(name): String(localized: "For \(name)", bundle: .module)
        case .unassigned: String(localized: "Unassigned", bundle: .module)
        case let .transferredToYou(name): String(localized: "For you, transferred by \(name)", bundle: .module)
        }
    }
}

/// The avatar and name of who a card is for. "Unassigned" gets a dashed empty avatar.
public struct OwnerLabel: View {
    private let owner: InboxOwner
    @ScaledMetric private var avatarSize = 20.0

    public init(_ owner: InboxOwner) {
        self.owner = owner
    }

    public var body: some View {
        HStack(spacing: 6) {
            avatar
            Text(verbatim: owner.displayName)
                .font(.fabrix(.caption))
                .foregroundStyle(Palette.steel)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: owner.spoken))
    }

    @ViewBuilder private var avatar: some View {
        switch owner {
        case .unassigned:
            Circle()
                .strokeBorder(Palette.muted, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                .frame(width: avatarSize, height: avatarSize)
        case .you, .transferredToYou:
            Image(systemName: "person.fill")
                .font(.fabrix(.interSemiBold, fixedSize: avatarSize * 0.5))
                .foregroundStyle(Palette.onSignal)
                .frame(width: avatarSize, height: avatarSize)
                .background(Palette.signal, in: Circle())
        case let .person(name):
            AvatarBadge(name, size: avatarSize)
        }
    }
}

private struct OwnerLabelPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            OwnerLabel(.you)
            OwnerLabel(.person("Priya"))
            OwnerLabel(.unassigned)
            OwnerLabel(.transferredToYou(by: "Priya"))
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("OwnerLabel") { OwnerLabelPreview() }

#Preview("OwnerLabel · dark") { OwnerLabelPreview().preferredColorScheme(.dark) }

#Preview("OwnerLabel · accessibility") { OwnerLabelPreview().dynamicTypeSize(.accessibility3) }
