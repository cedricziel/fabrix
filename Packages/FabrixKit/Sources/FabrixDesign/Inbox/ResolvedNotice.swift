import SwiftUI

public enum ResolverKind: Sendable {
    case person
    case agent
    case unknown
}

/// A completed decision received from the inbox service.
public struct ResolvedNotice: View {
    private let resolverKind: ResolverKind
    private let resolverName: String
    private let outcome: String
    private let time: String
    private let unrecordedAction: String

    public init(
        resolverKind: ResolverKind,
        resolverName: String,
        outcome: String,
        time: String,
        unrecordedAction: String
    ) {
        self.resolverKind = resolverKind
        self.resolverName = resolverName
        self.outcome = outcome
        self.time = time
        self.unrecordedAction = unrecordedAction
    }

    public var body: some View {
        let message = Self.resolvedNoticeText(
            resolverKind: resolverKind,
            resolverName: resolverName,
            outcome: outcome,
            time: time,
            unrecordedAction: unrecordedAction
        )
        Label {
            Text(message)
                .font(.fabrix(.body))
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Palette.doneInk)
                .accessibilityHidden(true)
        }
        .foregroundStyle(Palette.graphite)
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.doneTint, in: RoundedRectangle(cornerRadius: Radius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(message))
        .onAppear {
            AccessibilityNotification.Announcement(message).post()
        }
    }

    public nonisolated static func resolvedNoticeText(
        resolverKind: ResolverKind,
        resolverName: String,
        outcome: String,
        time: String,
        unrecordedAction: String
    ) -> String {
        let name = resolverKind == .unknown
            ? String(localized: "Someone", bundle: .module)
            : resolverName
        let decided = String(
            localized: "\(name) decided: \(outcome) at \(time).",
            bundle: .module
        )
        guard !unrecordedAction.isEmpty else { return decided }
        let notRecorded = String(
            localized: "Your \(unrecordedAction) wasn't recorded.",
            bundle: .module
        )
        return decided + " " + notRecorded
    }
}

#Preview("Resolved notice light") {
    VStack(spacing: 16) {
        ResolvedNotice(resolverKind: .person, resolverName: "Priya", outcome: "approved", time: "14:29", unrecordedAction: "rejection")
        ResolvedNotice(resolverKind: .agent, resolverName: "Review agent", outcome: "declined", time: "14:31", unrecordedAction: "approval")
        ResolvedNotice(resolverKind: .unknown, resolverName: "", outcome: "approved", time: "14:29", unrecordedAction: "")
    }
    .padding()
    .background(Palette.paper)
    .preferredColorScheme(.light)
}

#Preview("Resolved notice dark") { ResolvedNotice(resolverKind: .agent, resolverName: "Review agent", outcome: "approved", time: "14:29", unrecordedAction: "").padding().preferredColorScheme(.dark) }
#Preview("Resolved notice accessibility") { ResolvedNotice(resolverKind: .unknown, resolverName: "", outcome: "approved", time: "14:29", unrecordedAction: "rejection").padding().dynamicTypeSize(.accessibility3) }
