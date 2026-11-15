import SwiftUI

/// One card in the inbox list: kind tag, requester and task, age, title, one-line summary and owner.
/// It reads as one VoiceOver element. Actions are the caller's to add, as custom actions.
public struct InboxRow: View {
    private let kind: String
    private let tone: Tone
    private let requester: String?
    private let identifier: String?
    private let age: String
    private let title: String
    private let summary: String?
    private let owner: InboxOwner
    private let staleReason: String?
    private let isCritical: Bool
    private let isProblem: Bool
    private let isSelected: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    /// - Parameters:
    ///   - age: already phrased for reading, such as "12 minutes ago".
    public init(
        kind: String, tone: Tone, requester: String? = nil, identifier: String? = nil, age: String,
        title: String, summary: String? = nil, owner: InboxOwner, staleReason: String? = nil,
        isCritical: Bool = false, isProblem: Bool = false, isSelected: Bool = false
    ) {
        self.kind = kind
        self.tone = tone
        self.requester = requester
        self.identifier = identifier
        self.age = age
        self.title = title
        self.summary = summary
        self.owner = owner
        self.staleReason = staleReason
        self.isCritical = isCritical
        self.isProblem = isProblem
        self.isSelected = isSelected
    }

    nonisolated static func flagTitles(isCritical: Bool, isProblem: Bool) -> [String] {
        (isCritical ? [String(localized: "Critical", bundle: .module)] : [])
            + (isProblem ? [String(localized: "Problem", bundle: .module)] : [])
    }

    nonisolated static func accessibilityLabel(
        kind: String, title: String, requester: String?, age: String, owner: InboxOwner,
        isCritical: Bool, isProblem: Bool, staleReason: String?, identifier: String? = nil, summary: String? = nil
    ) -> String {
        let from = requester.map { String(localized: "From \($0), \(age)", bundle: .module) } ?? age
        let stale = staleReason.map { String(localized: "Stale: \($0)", bundle: .module) }
        return ([kind] + flagTitles(isCritical: isCritical, isProblem: isProblem) + [title, from, owner.spoken, identifier, summary, stale].compactMap { $0 }).spokenSentences()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            AdaptiveStack(spacing: Spacing.s, rowAlignment: .center) {
                HStack(spacing: Spacing.xs) {
                    KindTag(title: kind, tone: tone)
                    ForEach(Self.flagTitles(isCritical: isCritical, isProblem: isProblem), id: \.self) {
                        KindTag(title: $0, tone: Tone.halt)
                    }
                }
                if requester != nil || identifier != nil {
                    Text(verbatim: [requester, identifier].compactMap { $0 }.joined(separator: " · "))
                        .font(.fabrix(.caption))
                        .foregroundStyle(Palette.steel)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                }
                if !typeSize.isAccessibilitySize {
                    Spacer(minLength: Spacing.s)
                }
                Text(verbatim: age)
                    .font(.fabrix(.caption))
                    .foregroundStyle(Palette.muted)
            }
            Text(verbatim: title)
                .font(.fabrix(.headline))
                .foregroundStyle(Palette.graphite)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
            if let summary {
                Text(verbatim: summary)
                    .font(.fabrix(.subheadline))
                    .foregroundStyle(Palette.steel)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            }
            if let staleReason {
                Label {
                    Text("Stale: \(staleReason)", bundle: .module)
                } icon: {
                    Image(systemName: "clock.badge.exclamationmark")
                }
                .font(.fabrix(.caption))
                .foregroundStyle(Palette.muted)
            }
            OwnerLabel(owner).padding(.top, Spacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.m)
        .padding(.horizontal, Spacing.l)
        .background(isSelected ? Palette.selection : Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: Self.accessibilityLabel(
            kind: kind, title: title, requester: requester, age: age, owner: owner,
            isCritical: isCritical, isProblem: isProblem, staleReason: staleReason,
            identifier: identifier, summary: summary
        )))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct InboxRowPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                InboxRow(
                    kind: "Approval", tone: .signal, requester: "CEO", identifier: "ATL-148", age: "12 minutes ago",
                    title: "Hire a Designer agent", summary: "Needs a $40 monthly budget.", owner: .you
                )
                Divider()
                InboxRow(
                    kind: "Question", tone: .neutral, requester: "CTO", identifier: "ATL-160", age: "2 hours ago",
                    title: "Which push provider?", summary: "Two options with different pricing.",
                    owner: .person("Priya"), isSelected: true
                )
                Divider()
                InboxRow(
                    kind: "Review", tone: .signal, requester: "CMO", age: "Yesterday", title: "Review release notes",
                    owner: .unassigned, staleReason: "The task was closed"
                )
                Divider()
                InboxRow(
                    kind: "Budget", tone: .halt, requester: "CFO", identifier: "ATL-101", age: "1 hour ago",
                    title: "Budget stop on Mobile app", owner: .transferredToYou(by: "Priya"),
                    isCritical: true, isProblem: true
                )
            }
        }
        .background(Palette.card)
    }
}

#Preview("InboxRow") { InboxRowPreview() }

#Preview("InboxRow · dark") { InboxRowPreview().preferredColorScheme(.dark) }

#Preview("InboxRow · accessibility") { InboxRowPreview().dynamicTypeSize(.accessibility3) }
