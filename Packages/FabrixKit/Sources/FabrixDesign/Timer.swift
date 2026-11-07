import SwiftUI

/// A live run's elapsed time, "02:13", kept current by the system without
/// re-rendering the view. VoiceOver reads it as words: "2 minutes ago".
public struct ElapsedText: View {
    private let since: Date

    public init(since: Date) {
        self.since = since
    }

    /// A start in the future, from clock skew between the factory and the device, counts from now.
    nonisolated static func interval(since: Date, now: Date) -> ClosedRange<Date> {
        min(since, now)...Date.distantFuture
    }

    public var body: some View {
        Text(timerInterval: Self.interval(since: since, now: .now), countsDown: false)
            .monospacedDigit()
            .accessibilityLabel(Text(since, format: .relative(presentation: .numeric, unitsStyle: .wide)))
    }
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
