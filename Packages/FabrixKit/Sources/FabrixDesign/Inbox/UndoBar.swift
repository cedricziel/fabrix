import SwiftUI

/// Where a staged decision is: counting down, going out, delivered, held for sign-in or refused.
public enum UndoPhase: Equatable, Sendable {
    case counting(secondsLeft: Int)
    case sending
    case sent
    /// The factory refused the key, so the action goes out after the next sign-in.
    case held
    case failed(reason: String)

    public enum Kind: Equatable, Sendable {
        case counting, sending, sent, held, failed
    }

    /// The phase without its details, so a ticking countdown is not a new phase.
    public var kind: Kind {
        switch self {
        case .counting: .counting
        case .sending: .sending
        case .sent: .sent
        case .held: .held
        case .failed: .failed
        }
    }
}

/// The bar that follows a decision: the verdict, the title and "Sending in 6 sec" as text, with Undo.
/// It announces each phase to VoiceOver, and "Sent" only in the sent phase. Nothing moves, so Reduce Motion
/// needs no special case. A failed send is not retried: the caller returns the card to the list.
public struct UndoBar: View {
    private let verdict: String
    private let title: String
    private let phase: UndoPhase
    private let onUndo: () -> Void
    private let onSendNow: () -> Void

    public init(
        verdict: String, title: String, phase: UndoPhase, onUndo: @escaping () -> Void,
        onSendNow: @escaping () -> Void
    ) {
        self.verdict = verdict
        self.title = title
        self.phase = phase
        self.onUndo = onUndo
        self.onSendNow = onSendNow
    }

    private nonisolated static func duration(_ secondsLeft: Int, width: Duration.UnitsFormatStyle.UnitWidth, locale: Locale) -> String {
        Duration.seconds(max(0, secondsLeft)).formatted(.units(allowed: [.seconds], width: width).locale(locale))
    }

    nonisolated static func timeLeftText(secondsLeft: Int, locale: Locale = .current) -> String {
        String(localized: "Sending in \(duration(secondsLeft, width: .abbreviated, locale: locale))", bundle: .module)
    }

    nonisolated static func announcement(verdict: String, phase: UndoPhase, locale: Locale = .current) -> String {
        switch phase {
        case let .counting(secondsLeft):
            [verdict, String(localized: "Sending in \(duration(secondsLeft, width: .wide, locale: locale))", bundle: .module)]
                .spokenSentences()
        case .sending: [String(localized: "Sending", bundle: .module)].spokenSentences()
        case .sent: [String(localized: "Sent", bundle: .module)].spokenSentences()
        case .held: [String(localized: "Not sent yet. It goes out when you sign in again.", bundle: .module)].spokenSentences()
        case let .failed(reason): [String(localized: "Not sent: \(reason)", bundle: .module)].spokenSentences()
        }
    }

    public var body: some View {
        AdaptiveStack(spacing: Spacing.m, rowAlignment: .center) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                AdaptiveStack(spacing: Spacing.xs) {
                    Text(verbatim: verdict).font(.fabrix(.headline))
                    Text(verbatim: title).font(.fabrix(.body))
                }
                statusLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            actions
        }
        .foregroundStyle(Palette.onInverse)
        .padding(Spacing.l)
        .background(Palette.inverseSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .onAppear { announce() }
        .onChange(of: phase.kind) { announce() }
    }

    private func announce() {
        AccessibilityNotification.Announcement(Self.announcement(verdict: verdict, phase: phase)).post()
    }

    @ViewBuilder private var statusLine: some View {
        Group {
            switch phase {
            case let .counting(secondsLeft):
                Text(verbatim: Self.timeLeftText(secondsLeft: secondsLeft)).monospacedDigit()
            case .sending:
                Label { Text("Sending…", bundle: .module) } icon: { ProgressView().controlSize(.mini) }
            case .sent:
                Label { Text("Sent", bundle: .module) } icon: { Image(systemName: "checkmark.circle.fill") }
            case .held:
                Label {
                    Text("Not sent yet. It goes out when you sign in again.", bundle: .module)
                } icon: {
                    Image(systemName: "lock.fill")
                }
            case let .failed(reason):
                Label {
                    Text("Not sent: \(reason)", bundle: .module)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
            }
        }
        .font(.fabrix(.caption))
        .foregroundStyle(Palette.onInverseMuted)
    }

    @ViewBuilder private var actions: some View {
        if phase.kind == .counting {
            AdaptiveStack(spacing: Spacing.s, rowAlignment: .center) {
                Button(action: onSendNow) { Text("Send now", bundle: .module).frame(maxWidth: .infinity) }
                    .buttonStyle(.fabrixSecondary)
                Button(action: onUndo) { Text("Undo", bundle: .module).frame(maxWidth: .infinity) }
                    .buttonStyle(.fabrixSignal)
            }
            .controlSize(.small)
        }
    }
}

private struct UndoBarPreview: View {
    var body: some View {
        VStack(spacing: Spacing.m) {
            ForEach(phases, id: \.kind) {
                UndoBar(verdict: "Approved", title: "Hire a Designer agent", phase: $0, onUndo: {}, onSendNow: {})
            }
        }
        .padding()
        .background(Palette.paper)
    }

    private var phases: [UndoPhase] {
        [.counting(secondsLeft: 6), .sending, .sent, .held, .failed(reason: "You're offline")]
    }
}

#Preview("UndoBar") { UndoBarPreview() }

#Preview("UndoBar · dark") { UndoBarPreview().preferredColorScheme(.dark) }

#Preview("UndoBar · accessibility") { ScrollView { UndoBarPreview() }.dynamicTypeSize(.accessibility3) }
