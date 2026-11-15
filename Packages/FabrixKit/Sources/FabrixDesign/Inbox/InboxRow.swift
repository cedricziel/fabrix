import SwiftUI

public struct InboxRow: View {
    private let kind, requester, taskIdentifier, age, title, summary, owner: String
    private let tone: Tone
    private let staleReason: String?
    private let isCritical, isProblem: Bool

    public init(kind: String, tone: Tone, requester: String, taskIdentifier: String, age: String, title: String, summary: String, owner: String, staleReason: String? = nil, isCritical: Bool = false, isProblem: Bool = false) {
        self.kind = kind; self.tone = tone; self.requester = requester; self.taskIdentifier = taskIdentifier
        self.age = age; self.title = title; self.summary = summary; self.owner = owner
        self.staleReason = staleReason; self.isCritical = isCritical; self.isProblem = isProblem
    }

    nonisolated static func announcement(kind: String, title: String, requester: String, age: String, owner: String, staleReason: String?, isCritical: Bool, isProblem: Bool) -> String {
        var parts = [String(localized: "inbox.row.accessibility", defaultValue: "\(kind). \(title). From \(requester), \(age). \(owner).", bundle: .module)]
        if let staleReason { parts.append(String(localized: "inbox.row.stale", defaultValue: "Stale: \(staleReason).", bundle: .module)) }
        if isCritical { parts.append(String(localized: "inbox.row.critical", defaultValue: "Critical.", bundle: .module)) }
        if isProblem { parts.append(String(localized: "inbox.row.problem", defaultValue: "Problem.", bundle: .module)) }
        return parts.joined(separator: " ")
    }

    nonisolated static func statusText(critical: Bool, problem: Bool) -> [String] {
        (critical ? [String(localized: "inbox.row.critical", defaultValue: "Critical.", bundle: .module)] : []) +
        (problem ? [String(localized: "inbox.row.problem", defaultValue: "Problem.", bundle: .module)] : [])
    }

    public nonisolated static func stacksMetadata(forAccessibilitySize value: Bool) -> Bool { value }

    public var body: some View {
        Group { if isAccessibilitySize { VStack(alignment: .leading, spacing: Spacing.s) { content } } else { HStack(alignment: .top, spacing: Spacing.m) { content } } }
        .padding(Spacing.l)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: Self.announcement(kind: kind, title: title, requester: requester, age: age, owner: owner, staleReason: staleReason, isCritical: isCritical, isProblem: isProblem)))
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var isAccessibilitySize: Bool { Self.stacksMetadata(forAccessibilitySize: dynamicTypeSize >= .accessibility1) }

    @ViewBuilder private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack { KindTag(title: kind, tone: tone); Text(verbatim: taskIdentifier).font(.fabrix(.monoCaption)); Spacer(minLength: 0) }
            Text(verbatim: title).font(.fabrix(.headline)).foregroundStyle(Palette.graphite)
            Text(verbatim: summary).font(.fabrix(.body)).foregroundStyle(Palette.muted)
            (isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs)) : AnyLayout(HStackLayout(spacing: Spacing.s))) { Text(verbatim: requester).font(.fabrix(.caption)); Text(verbatim: age).font(.fabrix(.caption)); OwnerLabel(owner); ForEach(Array(Self.statusText(critical: isCritical, problem: isProblem).enumerated()), id: \.offset) { index, text in HStack(spacing: 3) { if isCritical && index == 0 { Image(systemName: "exclamationmark.triangle.fill").accessibilityHidden(true) }; Text(verbatim: text) }.font(.fabrix(.label)).foregroundStyle(Palette.haltInk) } }
            if let staleReason { Text(verbatim: staleReason).font(.fabrix(.subheadline)).foregroundStyle(Palette.signalInk) }
        }
    }
}

#Preview("Inbox row light") { InboxRow(kind: "Approval", tone: .signal, requester: "CEO", taskIdentifier: "T-1", age: "12 minutes ago", title: "Hire a Designer agent", summary: "Review candidate", owner: "For you").padding().background(Palette.paper).preferredColorScheme(.light) }
#Preview("Inbox row dark") { InboxRow(kind: "Approval", tone: .signal, requester: "CEO", taskIdentifier: "T-1", age: "12 minutes ago", title: "Hire a Designer agent", summary: "Review candidate", owner: "For you").padding().background(Palette.paper).preferredColorScheme(.dark) }
#Preview("Inbox row accessibility") { InboxRow(kind: "Approval", tone: .signal, requester: "CEO", taskIdentifier: "T-1", age: "12 minutes ago", title: "Hire a Designer agent", summary: "Review candidate", owner: "For you").padding().dynamicTypeSize(.accessibility3) }
