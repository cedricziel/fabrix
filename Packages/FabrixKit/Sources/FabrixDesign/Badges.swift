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

    public var title: LocalizedStringResource {
        switch self {
        case .hire: LocalizedStringResource("Hire", bundle: .module)
        case .strategy: LocalizedStringResource("Strategy", bundle: .module)
        case .budget: LocalizedStringResource("Budget", bundle: .module)
        }
    }
}

/// The small orange-tinted tag on a decision: HIRE, STRATEGY, BUDGET.
public struct KindTag: View {
    let title: Text
    let tone: Tone

    public init(_ kind: DecisionKind) {
        title = Text(kind.title)
        tone = .signal
    }

    /// - Parameter tone: `.signal` for things waiting on a human; `.neutral` for labels such as PRIMARY.
    public init(title: LocalizedStringResource, tone: Tone = .signal) {
        self.title = Text(title)
        self.tone = tone
    }

    @_disfavoredOverload
    public init(title: String, tone: Tone = .signal) {
        self.title = Text(verbatim: title)
        self.tone = tone
    }

    public var body: some View {
        title
            .textCase(.uppercase)
            .font(.fabrix(.tag))
            .tracking(0.5)
            .foregroundStyle(tone.ink)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tone.tint, in: RoundedRectangle(cornerRadius: Radius.tag, style: .continuous))
            .accessibilityElement(children: .ignore)
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
            KindTag(title: "Primary", tone: .neutral)
        }
    }
    .padding()
    .background(Palette.paper)
}
