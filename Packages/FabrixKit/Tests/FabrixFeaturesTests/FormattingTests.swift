import Foundation
@testable import FabrixFeatures
import Testing

struct FormattingTests {
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
