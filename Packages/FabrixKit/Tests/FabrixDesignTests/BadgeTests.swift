@testable import FabrixDesign
import Testing

struct BadgeTests {
    @Test(arguments: [
        ("fe", "FE"),
        ("CTO", "CT"),
        ("q", "Q"),
        ("  qa ", "QA"),
    ])
    func avatarShowsAtMostTwoUppercaseLetters(input: String, expected: String) {
        #expect(AvatarBadge.displayInitials(input) == expected)
    }

    @Test(arguments: [
        (DecisionKind.hire, "Hire"),
        (.strategy, "Strategy"),
        (.budget, "Budget"),
    ])
    func kindTitles(kind: DecisionKind, expected: String) {
        #expect(kind.title == expected)
    }
}
