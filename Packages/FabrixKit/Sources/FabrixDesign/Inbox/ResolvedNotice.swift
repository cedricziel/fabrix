import SwiftUI

/// Who closed a card before you did.
public enum ResolverKind: Equatable, Sendable {
    case person(String)
    case agent(String)
    case unknown
}

/// "Priya approved this at 14:29. Your rejection wasn't recorded." for a card someone else already closed.
/// It is announced when it appears.
public struct ResolvedNotice: View {
    private let text: String

    /// - Parameters:
    ///   - outcome: the past-tense verb, such as "approved".
    ///   - time: when it happened, already formatted.
    ///   - attempted: what you tried, such as "rejection".
    public init(resolver: ResolverKind, outcome: String, time: String?, attempted: String) {
        text = Self.text(resolver: resolver, outcome: outcome, time: time, attempted: attempted)
    }

    nonisolated static func text(resolver: ResolverKind, outcome: String, time: String?, attempted: String) -> String {
        let notRecorded = String(localized: "Your \(attempted) wasn't recorded.", bundle: .module)
        let name: String
        switch resolver {
        case let .person(person): name = person
        case let .agent(agent): name = String(localized: "The \(agent) agent", bundle: .module)
        case .unknown: return "\(String(localized: "This was already decided.", bundle: .module)) \(notRecorded)"
        }
        let what = time.map { String(localized: "\(name) \(outcome) this at \($0).", bundle: .module) }
            ?? String(localized: "\(name) \(outcome) this.", bundle: .module)
        return "\(what) \(notRecorded)"
    }

    public var body: some View {
        Label {
            Text(verbatim: text).frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: "info.circle.fill")
        }
        .font(.fabrix(.subheadline))
        .foregroundStyle(Palette.neutralInk)
        .padding(Spacing.m)
        .background(Palette.neutralTint, in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
        .accessibilityElement(children: .combine)
        .onAppear { AccessibilityNotification.Announcement(text).post() }
    }
}

private struct ResolvedNoticePreview: View {
    var body: some View {
        VStack(spacing: Spacing.m) {
            ResolvedNotice(resolver: .person("Priya"), outcome: "approved", time: "14:29", attempted: "rejection")
            ResolvedNotice(resolver: .agent("CEO"), outcome: "rejected", time: "14:29", attempted: "approval")
            ResolvedNotice(resolver: .unknown, outcome: "approved", time: nil, attempted: "rejection")
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("ResolvedNotice") { ResolvedNoticePreview() }

#Preview("ResolvedNotice · dark") { ResolvedNoticePreview().preferredColorScheme(.dark) }

#Preview("ResolvedNotice · accessibility") { ResolvedNoticePreview().dynamicTypeSize(.accessibility3) }
