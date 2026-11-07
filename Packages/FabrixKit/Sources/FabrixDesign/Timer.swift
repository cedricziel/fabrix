import SwiftUI

/// A live run's elapsed time, "2:13", kept current by the system without
/// re-rendering the view. VoiceOver reads it as words: "2 minutes, 13 seconds".
public struct ElapsedText: View {
    private let since: Date
    @Environment(\.timersFrozenAt) private var frozenAt

    public init(since: Date) {
        self.since = since
    }

    /// A start in the future, from clock skew between the factory and the device, counts from now.
    nonisolated static func interval(since: Date, now: Date) -> ClosedRange<Date> {
        min(since, now)...Date.distantFuture
    }

    nonisolated static func accessibilityLabel(since: Date) -> Text {
        Text(since, style: .relative)
    }

    /// A stopped timer reads the time it showed when the data stopped arriving.
    nonisolated static func frozenAccessibilityLabel(since: Date, frozenAt: Date) -> String {
        Duration.seconds(max(0, frozenAt.timeIntervalSince(since)))
            .formatted(.units(allowed: [.hours, .minutes, .seconds], width: .wide))
    }

    public var body: some View {
        Text(timerInterval: Self.interval(since: since, now: frozenAt ?? .now), pauseTime: frozenAt, countsDown: false)
            .monospacedDigit()
            .opacity(frozenAt == nil ? 1 : 0.5)
            .accessibilityLabel(
                frozenAt.map { Text(verbatim: Self.frozenAccessibilityLabel(since: since, frozenAt: $0)) }
                    ?? Self.accessibilityLabel(since: since)
            )
    }
}

public extension EnvironmentValues {
    /// Set while the shown data is stale: every `ElapsedText` below stops at this time.
    @Entry var timersFrozenAt: Date?
}

private struct TimerPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ElapsedText(since: .now)
            ElapsedText(since: .now.addingTimeInterval(-133))
            ElapsedText(since: .now.addingTimeInterval(-3725)).font(.fabrix(.mono))
            ElapsedText(since: .now.addingTimeInterval(60))
        }
        .padding()
        .foregroundStyle(Palette.graphite)
        .background(Palette.paper)
    }
}

#Preview("Timer") { TimerPreview() }

#Preview("Timer · dark") { TimerPreview().preferredColorScheme(.dark) }
