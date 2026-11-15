import SwiftUI

public struct HistoryRow: View {
    private let verb, actor, context, time: String
    private let reason: String?

    public init(verb: String, actor: String, context: String, time: String, reason: String? = nil) {
        self.verb = verb
        self.actor = actor
        self.context = context
        self.time = time
        self.reason = reason
    }

    nonisolated static func announcement(verb: String, actor: String, context: String, time: String, reason: String?) -> String {
        ([verb, actor, context, time] + (reason.map { [$0] } ?? [])).joined(separator: ", ")
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public var body: some View {
        Group {
            if dynamicTypeSize >= .accessibility1 {
                VStack(alignment: .leading, spacing: Spacing.s) { content }
            } else {
                VStack(alignment: .leading, spacing: Spacing.xs) { content }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: Self.announcement(verb: verb, actor: actor, context: context, time: time, reason: reason)))
    }

    @ViewBuilder private var content: some View {
        Text(verbatim: verb).font(.fabrix(.headline)).foregroundStyle(Palette.graphite)
        Text(verbatim: actor).font(.fabrix(.subheadline)).foregroundStyle(Palette.muted)
        Text(verbatim: context).font(.fabrix(.body)).foregroundStyle(Palette.muted)
        Text(verbatim: time).font(.fabrix(.caption)).foregroundStyle(Palette.muted)
        if let reason { Text(verbatim: reason).font(.fabrix(.subheadline)).foregroundStyle(Palette.signalInk) }
    }
}

#Preview("History row light") { HistoryRow(verb: "Approved", actor: "Alex", context: "Hiring request", time: "2 minutes ago", reason: "Role approved").padding().background(Palette.paper).preferredColorScheme(.light) }
#Preview("History row dark") { HistoryRow(verb: "Approved", actor: "Alex", context: "Hiring request", time: "2 minutes ago", reason: "Role approved").padding().background(Palette.paper).preferredColorScheme(.dark) }
#Preview("History row accessibility") { HistoryRow(verb: "Approved", actor: "Alex", context: "Hiring request", time: "2 minutes ago", reason: "Role approved").padding().dynamicTypeSize(.accessibility3) }
