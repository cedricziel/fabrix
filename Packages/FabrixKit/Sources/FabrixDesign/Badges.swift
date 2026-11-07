import SwiftUI

/// A graphite initials tile standing in for an agent.
public struct AvatarBadge: View {
    private let initials: String
    @ScaledMetric private var size: CGFloat

    /// - Parameters:
    ///   - initials: Up to two letters are shown, uppercased.
    ///   - size: 32 in lists, 60 on an agent header.
    public init(_ initials: String, size: CGFloat = 32) {
        self.initials = Self.displayInitials(initials)
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    nonisolated static func displayInitials(_ raw: String) -> String {
        String(raw.trimmingCharacters(in: .whitespaces).prefix(2)).uppercased()
    }

    public var body: some View {
        Text(initials)
            .font(.fabrix(.interSemiBold, fixedSize: size * 0.36))
            .foregroundStyle(Palette.onGraphite)
            .frame(width: size, height: size)
            .background(Palette.graphite, in: RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// What a decision is about.
public enum DecisionKind: CaseIterable, Sendable {
    case hire, strategy, budget

    public var title: String {
        switch self {
        case .hire: String(localized: "Hire", bundle: .module)
        case .strategy: String(localized: "Strategy", bundle: .module)
        case .budget: String(localized: "Budget", bundle: .module)
        }
    }
}

/// The small orange-tinted tag on a decision: HIRE, STRATEGY, BUDGET.
public struct KindTag: View {
    private let title: String

    public init(_ kind: DecisionKind) {
        title = kind.title.uppercased()
    }

    public init(title: String) {
        self.title = title.uppercased()
    }

    public var body: some View {
        Text(title)
            .font(.fabrix(.tag))
            .tracking(0.5)
            .foregroundStyle(Palette.signalInk)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Palette.signalTint, in: RoundedRectangle(cornerRadius: Radius.tag, style: .continuous))
            .accessibilityLabel(title)
    }
}

#Preview("Badges") {
    VStack(alignment: .leading, spacing: Spacing.m) {
        HStack {
            AvatarBadge("CT")
            AvatarBadge("fe")
            AvatarBadge("FE", size: 60)
        }
        HStack {
            ForEach(DecisionKind.allCases, id: \.self) { KindTag($0) }
        }
    }
    .padding()
    .background(Palette.paper)
}
