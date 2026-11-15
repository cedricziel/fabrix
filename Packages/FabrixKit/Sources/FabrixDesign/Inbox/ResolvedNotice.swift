import SwiftUI

/// Who closed a card before you did.
public enum ResolverKind: Equatable, Sendable {
    case person(String)
    case agent(String)
    /// You, with an earlier answer.
    case you
    case unknown
}

/// What someone did, or what you tried to do. Each kind has its words here, so callers never build sentences.
public enum ResolutionKind: CaseIterable, Sendable {
    case approved, rejected, accepted, declined, answered, decided, closed

    nonisolated var pastTense: String {
        switch self {
        case .approved: String(localized: "approved", bundle: .module)
        case .rejected: String(localized: "rejected", bundle: .module)
        case .accepted: String(localized: "accepted", bundle: .module)
        case .declined: String(localized: "declined", bundle: .module)
        case .answered: String(localized: "answered", bundle: .module)
        case .decided: String(localized: "decided", bundle: .module)
        case .closed: String(localized: "closed", bundle: .module)
        }
    }

    nonisolated var noun: String {
        switch self {
        case .approved: String(localized: "approval", bundle: .module)
        case .rejected: String(localized: "rejection", bundle: .module)
        case .accepted: String(localized: "acceptance", bundle: .module)
        case .declined: String(localized: "refusal", bundle: .module)
        case .answered: String(localized: "answer", bundle: .module)
        case .decided: String(localized: "decision", bundle: .module)
        case .closed: String(localized: "closing", bundle: .module)
        }
    }
}

/// "Priya approved this at 14:29. Your rejection wasn't recorded." for a card someone else already closed.
/// It is announced when it appears.
public struct ResolvedNotice: View {
    private let text: String

    /// - Parameters:
    ///   - outcome: what the resolver did.
    ///   - time: when it happened, already formatted.
    ///   - attempted: what you tried to do.
    public init(resolver: ResolverKind, outcome: ResolutionKind, time: String?, attempted: ResolutionKind) {
        text = Self.text(resolver: resolver, outcome: outcome, time: time, attempted: attempted)
    }

    nonisolated static func text(resolver: ResolverKind, outcome: ResolutionKind, time: String?, attempted: ResolutionKind) -> String {
        let notRecorded = String(localized: "Your \(attempted.noun) wasn't recorded.", bundle: .module)
        func at(_ sentence: String, _ withTime: (String) -> String) -> String {
            time.map(withTime) ?? sentence
        }
        let what = switch resolver {
        case let .person(name):
            at(String(localized: "\(name) \(outcome.pastTense) this.", bundle: .module)) {
                String(localized: "\(name) \(outcome.pastTense) this at \($0).", bundle: .module)
            }
        case let .agent(name):
            at(String(localized: "The \(name) agent \(outcome.pastTense) this.", bundle: .module)) {
                String(localized: "The \(name) agent \(outcome.pastTense) this at \($0).", bundle: .module)
            }
        case .you:
            at(String(localized: "You already answered this.", bundle: .module)) {
                String(localized: "You already answered this at \($0).", bundle: .module)
            }
        case .unknown:
            String(localized: "Someone already answered this.", bundle: .module)
        }
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
            ResolvedNotice(resolver: .person("Priya"), outcome: .approved, time: "14:29", attempted: .rejected)
            ResolvedNotice(resolver: .agent("CEO"), outcome: .rejected, time: "14:29", attempted: .approved)
            ResolvedNotice(resolver: .you, outcome: .answered, time: "14:29", attempted: .answered)
            ResolvedNotice(resolver: .unknown, outcome: .approved, time: nil, attempted: .rejected)
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("ResolvedNotice") { ResolvedNoticePreview() }

#Preview("ResolvedNotice · dark") { ResolvedNoticePreview().preferredColorScheme(.dark) }

#Preview("ResolvedNotice · accessibility") { ResolvedNoticePreview().dynamicTypeSize(.accessibility3) }
