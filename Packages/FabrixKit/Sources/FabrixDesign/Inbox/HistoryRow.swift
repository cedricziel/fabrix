import SwiftUI

/// How a decision in the history ended. The verb is the first word, so color is never the only signal.
public enum HistoryOutcome: CaseIterable, Sendable {
    case approved, rejected, answered, decided, withdrawn, transferred, expired

    nonisolated var verb: String {
        switch self {
        case .approved: String(localized: "Approved", bundle: .module)
        case .rejected: String(localized: "Rejected", bundle: .module)
        case .answered: String(localized: "Answered", bundle: .module)
        case .decided: String(localized: "Decided", bundle: .module)
        case .withdrawn: String(localized: "Withdrawn", bundle: .module)
        case .transferred: String(localized: "Transferred", bundle: .module)
        case .expired: String(localized: "Expired", bundle: .module)
        }
    }

    var tone: Tone {
        switch self {
        case .approved, .answered, .decided: .done
        case .rejected: .halt
        case .withdrawn, .transferred, .expired: .neutral
        }
    }
}

/// One line of the decision history: the outcome verb, the title, a detail and when it happened.
public struct HistoryRow: View {
    private let outcome: HistoryOutcome
    private let title: String
    private let detail: String?
    private let time: String

    /// - Parameters:
    ///   - detail: a reason, the chosen option or verdict counts.
    ///   - time: already formatted for reading.
    public init(outcome: HistoryOutcome, title: String, detail: String? = nil, time: String) {
        self.outcome = outcome
        self.title = title
        self.detail = detail
        self.time = time
    }

    nonisolated static func accessibilityLabel(outcome: HistoryOutcome, title: String, detail: String?, time: String) -> String {
        [outcome.verb, title, detail, time].compactMap { $0 }.spokenSentences()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            AdaptiveStack(spacing: Spacing.s) {
                Text(verbatim: outcome.verb)
                    .font(.fabrix(.label))
                    .foregroundStyle(outcome.tone.ink)
                    .padding(.horizontal, 7)
                    .background(outcome.tone.tint, in: RoundedRectangle(cornerRadius: Radius.tag, style: .continuous))
                Text(verbatim: title)
                    .font(.fabrix(.headline))
                    .foregroundStyle(Palette.graphite)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(verbatim: time).font(.fabrix(.caption)).foregroundStyle(Palette.muted)
            }
            if let detail {
                Text(verbatim: detail).font(.fabrix(.subheadline)).foregroundStyle(Palette.steel)
            }
        }
        .padding(.vertical, Spacing.m)
        .padding(.horizontal, Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: Self.accessibilityLabel(outcome: outcome, title: title, detail: detail, time: time)))
    }
}

private struct HistoryRowPreview: View {
    var body: some View {
        VStack(spacing: 0) {
            HistoryRow(outcome: .approved, title: "Hire a Designer agent", detail: "Budget fits", time: "14:29")
            HistoryRow(outcome: .rejected, title: "Review the Q4 plan", detail: "Too late for Q4", time: "13:02")
            HistoryRow(outcome: .answered, title: "Which push provider?", detail: "Chose Courier", time: "Yesterday")
            HistoryRow(outcome: .decided, title: "Review release notes", detail: "2 approved, 1 deferred", time: "Mon")
            HistoryRow(outcome: .withdrawn, title: "Raise the budget", time: "Mon")
            HistoryRow(outcome: .transferred, title: "Pick a vendor", detail: "To Priya", time: "Sun")
            HistoryRow(outcome: .expired, title: "Join request", time: "Last week")
        }
        .background(Palette.card)
    }
}

#Preview("HistoryRow") { HistoryRowPreview() }

#Preview("HistoryRow · dark") { HistoryRowPreview().preferredColorScheme(.dark) }

#Preview("HistoryRow · accessibility") { HistoryRowPreview().dynamicTypeSize(.accessibility3) }
