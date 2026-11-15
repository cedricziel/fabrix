@testable import FabrixDesign
import Testing
import SwiftUI

struct InboxComponentTests {
    @Test(arguments: [(0, nil), (7, "7"), (140, "99+")])
    func countBadgeText(count: Int, expected: String?) {
        #expect(CountBadge.countBadgeText(count) == expected)
    }

    @Test(arguments: [(1, "1 item"), (7, "7 items"), (140, "140 items")])
    func countBadgeSpeech(count: Int, expected: String) {
        #expect(CountBadge.countBadgeSpeech(count) == expected)
    }

    @Test func decisionBarDisabledReason() {
        #expect(DecisionBar.decisionBarDisabledReason("Complete the required fields first.") == "Complete the required fields first.")
        #expect(DecisionBar.decisionBarDisabledReason(nil) == nil)
    }

    @Test func decisionActionsAndLayout() {
        #expect(DecisionBar.actionsEnabled(disabledReason: nil))
        #expect(!DecisionBar.actionsEnabled(disabledReason: "Offline"))
        #expect(!DecisionBar.stacksAtAccessibilitySize(.large))
        #expect(DecisionBar.stacksAtAccessibilitySize(.accessibility3))
    }

    @Test func visibleStatusesIncludeCriticalAndProblem() {
        #expect(InboxRow.statusText(critical: true, problem: true) == ["Critical.", "Problem."])
        #expect(InboxRow.statusText(critical: false, problem: true) == ["Problem."])
        #expect(InboxRow.statusText(critical: false, problem: false).isEmpty)
    }

    @Test func keyHintChord() {
        #expect(KeyHint.keyHintChord("⌥⌘S") == "Option-Command-S")
    }
}
