import SwiftUI

/// Where a staged decision is: counting down, going out, delivered or refused.
public enum UndoPhase: Equatable, Sendable {
    case counting(secondsLeft: Int)
    case sending
    case sent
    case failed(reason: String)

    public enum Kind: Equatable, Sendable {
        case counting, sending, sent, failed
    }

    /// The phase without its details, so a ticking countdown is not a new phase.
    public var kind: Kind {
        switch self {
        case .counting: .counting
        case .sending: .sending
        case .sent: .sent
        case .failed: .failed
        }
    }
}

/// The bar that follows a decision: the verdict, the title and "Sending in 6 sec" as text, with Undo.
/// It announces each phase to VoiceOver. Nothing moves, so Reduce Motion needs no special case.
public struct UndoBar: View {
    private let verdict: String
    private let title: String
    private let phase: UndoPhase
    private let onUndo: () -> Void
    private let onSendNow: () -> Void
    private let onRetry: (() -> Void)?

    public init(
        verdict: String, title: String, phase: UndoPhase, onUndo: @escaping () -> Void,
        onSendNow: @escaping () -> Void, onRetry: (() -> Void)? = nil
    ) {
        self.verdict = verdict
        self.title = title
        self.phase = phase
        self.onUndo = onUndo
        self.onSendNow = onSendNow
        self.onRetry = onRetry
    }

    nonisolated static func timeLeftText(secondsLeft: Int, locale: Locale = .current) -> String {
        let time = Duration.seconds(max(0, secondsLeft)).formatted(.units(allowed: [.seconds], width: .abbreviated).locale(locale))
        return String(localized: "Sending in \(time)", bundle: .module)
    }

    nonisolated static func announcement(verdict: String, phase: UndoPhase, locale: Locale = .current) -> String {
        switch phase {
        case let .counting(secondsLeft):
            let time = Duration.seconds(max(0, secondsLeft)).formatted(.units(allowed: [.seconds], width: .wide).locale(locale))
            return [verdict, String(localized: "Sending in \(time)", bundle: .module)].spokenSentences()
        case .sending: return [String(localized: "Sending", bundle: .module)].spokenSentences()
        case .sent: return [String(localized: "Sent", bundle: .module)].spokenSentences()
        case let .failed(reason): return [String(localized: "Not sent", bundle: .module), reason].spokenSentences()
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            AdaptiveStack(spacing: Spacing.m, rowAlignment: .center) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(verbatim: verdict).font(.fabrix(.headline))
                        Text(verbatim: title).font(.fabrix(.body)).lineLimit(1)
                    }
                    statusLine
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                actions
            }
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
            case let .failed(reason):
                Label {
                    Text("Not sent. \(reason)", bundle: .module)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
            }
        }
        .font(.fabrix(.caption))
        .foregroundStyle(Palette.onInverseMuted)
    }

    @ViewBuilder private var actions: some View {
        switch phase {
        case .counting:
            HStack(spacing: Spacing.s) {
                Button(action: onSendNow) { Text("Send now", bundle: .module) }
                    .buttonStyle(.fabrixSecondary)
                Button(action: onUndo) { Text("Undo", bundle: .module) }
                    .buttonStyle(.fabrixSignal)
            }
            .controlSize(.small)
        case .failed:
            if let onRetry {
                Button(action: onRetry) { Text("Retry", bundle: .module) }
                    .buttonStyle(.fabrixSignal)
                    .controlSize(.small)
            }
        case .sending, .sent:
            EmptyView()
        }
    }
}

private struct UndoBarPreview: View {
    var body: some View {
        VStack(spacing: Spacing.m) {
            UndoBar(verdict: "Approved", title: "Hire a Designer agent", phase: .counting(secondsLeft: 6), onUndo: {}, onSendNow: {})
            UndoBar(verdict: "Approved", title: "Hire a Designer agent", phase: .sending, onUndo: {}, onSendNow: {})
            UndoBar(verdict: "Approved", title: "Hire a Designer agent", phase: .sent, onUndo: {}, onSendNow: {})
            UndoBar(
                verdict: "Approved", title: "Hire a Designer agent", phase: .failed(reason: "You're offline"),
                onUndo: {}, onSendNow: {}, onRetry: {}
            )
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("UndoBar") { UndoBarPreview() }

#Preview("UndoBar · dark") { UndoBarPreview().preferredColorScheme(.dark) }

#Preview("UndoBar · accessibility") { ScrollView { UndoBarPreview() }.dynamicTypeSize(.accessibility3) }
