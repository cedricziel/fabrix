import Foundation
@testable import FabrixFeatures
import Testing

struct FormattingTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test(arguments: [
        (0, "00:00"),
        (62, "01:02"),
        (724.9, "12:04"),
        (3599, "59:59"),
        (3600, "1:00:00"),
        (7509, "2:05:09"),
    ] as [(TimeInterval, String)])
    func elapsedUsesMinutesAndSecondsUnderAnHour(seconds: TimeInterval, expected: String) {
        #expect(Elapsed.string(from: start, to: start + seconds) == expected)
    }

    @Test func elapsedNeverGoesNegative() {
        #expect(Elapsed.string(from: start, to: start - 30) == "00:00")
    }

    @Test func moneyRoundsBudgetsToWholeDollars() {
        let locale = Locale(identifier: "en_US")
        #expect(Money.dollars(41_249, locale: locale) == "$412")
        #expect(Money.dollars(100_000, locale: locale) == "$1,000")
    }

    @Test func moneyUsesTheDollarSignOutsideTheUS() {
        let text = Money.dollars(41_200, locale: Locale(identifier: "de_DE"))
        #expect(text.hasPrefix("412") && text.hasSuffix("$") && !text.contains("US"))
    }

    @Test func moneyShowsCentsForRunCosts() {
        #expect(Money.exact(192, locale: Locale(identifier: "en_US")) == "$1.92")
    }
}
