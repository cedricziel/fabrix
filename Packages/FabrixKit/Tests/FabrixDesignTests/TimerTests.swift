@testable import FabrixDesign
import Foundation
import Testing

struct TimerTests {
    private let now = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test func countsUpFromTheStart() {
        let start = now.addingTimeInterval(-133)
        #expect(ElapsedText.interval(since: start, now: now).lowerBound == start)
    }

    @Test func aStartInTheFutureCountsFromNow() {
        #expect(ElapsedText.interval(since: now.addingTimeInterval(30), now: now).lowerBound == now)
    }
}
