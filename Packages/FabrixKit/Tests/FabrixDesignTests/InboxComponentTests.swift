@testable import FabrixDesign
import Foundation
import SwiftUI
import Testing

struct InboxComponentTests {
    @Test(arguments: [
        (-1, nil as String?),
        (0, nil),
        (1, "1"),
        (7, "7"),
        (99, "99"),
        (100, "99+"),
        (140, "99+"),
    ])
    func countBadgeText(count: Int, expected: String?) {
        #expect(CountBadge.text(for: count) == expected)
    }

    @Test func keyHintChord() {
        #expect(KeyHint.spokenChord(key: "S", modifiers: [.option, .command]) == "Option-Command-S")
        #expect(KeyHint.symbols(key: "S", modifiers: [.command, .option]) == "⌥⌘S")
    }

    @Test func keyHintOrdersModifiersLikeMacMenus() {
        #expect(KeyHint.spokenChord(key: "A", modifiers: [.command, .shift, .option, .control])
            == "Control-Option-Shift-Command-A")
    }

    @Test func keyHintSpeaksSpecialKeys() {
        #expect(KeyHint.spokenChord(key: "↩", modifiers: [.command]) == "Command-Return")
        #expect(KeyHint.spokenChord(key: "⌫", modifiers: [.command]) == "Command-Delete")
        #expect(KeyHint.spokenChord(key: "J", modifiers: []) == "J")
    }
}

extension InboxComponentTests {
    @Test func rowAccessibilityLabel() {
        let label = InboxRow.accessibilityLabel(
            kind: "Approval", title: "Hire a Designer agent", requester: "CEO", age: "12 minutes ago", owner: .you,
            isCritical: false, isProblem: false, staleReason: nil
        )
        #expect(label == "Approval. Hire a Designer agent. From CEO, 12 minutes ago. For you.")
    }

    @Test func rowLabelHandlesMissingRequesterAndOtherOwners() {
        #expect(InboxRow.accessibilityLabel(
            kind: "Question", title: "Which push provider?", requester: nil, age: "2 hours ago",
            owner: .unassigned, isCritical: false, isProblem: false, staleReason: nil
        ) == "Question. Which push provider? 2 hours ago. Unassigned.")
        #expect(InboxRow.accessibilityLabel(
            kind: "Approval", title: "Hire", requester: "CEO", age: "now", owner: .person("Priya"),
            isCritical: false, isProblem: false, staleReason: nil
        ).hasSuffix("For Priya."))
        #expect(InboxRow.accessibilityLabel(
            kind: "Approval", title: "Hire", requester: "CEO", age: "now", owner: .transferredToYou(by: "Priya"),
            isCritical: false, isProblem: false, staleReason: nil
        ).hasSuffix("For you, transferred by Priya."))
    }

    @Test func criticalAndProblemAreText() {
        #expect(InboxRow.flagTitles(isCritical: true, isProblem: true) == ["Critical", "Problem"])
        #expect(InboxRow.flagTitles(isCritical: false, isProblem: true) == ["Problem"])
        #expect(InboxRow.flagTitles(isCritical: false, isProblem: false).isEmpty)

        let label = InboxRow.accessibilityLabel(
            kind: "Budget", title: "Over budget", requester: "CFO", age: "1 hour ago", owner: .you,
            isCritical: true, isProblem: true, staleReason: "Task closed"
        )
        #expect(label == "Budget. Critical. Problem. Over budget. From CFO, 1 hour ago. For you. Stale: Task closed.")
    }

    @Test func kindTagTonesMapToPillTones() {
        #expect(KindTag(title: "Approval", tone: InboxRowTone.signal).tone == .signal)
        #expect(KindTag(title: "Approval", tone: InboxRowTone.neutral).tone == .neutral)
        #expect(KindTag(title: "Problem", tone: InboxRowTone.halt).tone == .halt)
    }

    @Test func ownerLabelText() {
        #expect(InboxOwner.you.displayName == "You")
        #expect(InboxOwner.person("Priya").displayName == "Priya")
        #expect(InboxOwner.unassigned.displayName == "Unassigned")
        #expect(InboxOwner.transferredToYou(by: "Priya").displayName == "You, transferred by Priya")
    }
}

extension InboxComponentTests {
    @Test(arguments: [(false, CountedPickerStyle.segmented), (true, .menu)])
    func countedPickerStyle(forAccessibilitySize isAccessibilitySize: Bool, expected: CountedPickerStyle) {
        #expect(CountedPicker<Int>.style(forAccessibilitySize: isAccessibilitySize) == expected)
        #expect(CountedPicker<Int>.style(forAccessibilitySize: DynamicTypeSize.large.isAccessibilitySize) == .segmented)
        #expect(CountedPicker<Int>.style(forAccessibilitySize: DynamicTypeSize.accessibility1.isAccessibilitySize) == .menu)
    }

    @Test func hidesZeroCount() {
        #expect(CountedPicker<Int>.label(title: "Unassigned", count: 0) == "Unassigned")
        #expect(CountedPicker<Int>.label(title: "For you", count: 3) == "For you 3")
        #expect(CountedPicker<Int>.label(title: "Company", count: 140) == "Company 99+")
        #expect(CountedPicker<Int>.spokenLabel(title: "For you", count: 3) == "For you, 3")
        #expect(CountedPicker<Int>.spokenLabel(title: "For you", count: 0) == "For you")
    }

    @Test func historyRowStartsWithVerb() {
        let label = HistoryRow.accessibilityLabel(
            outcome: .approved, title: "Hire a Designer agent", detail: "Budget fits", time: "14:29"
        )
        #expect(label == "Approved. Hire a Designer agent. Budget fits. 14:29.")
        for outcome in HistoryOutcome.allCases {
            let label = HistoryRow.accessibilityLabel(outcome: outcome, title: "X", detail: nil, time: "14:29")
            #expect(label.hasPrefix(outcome.verb))
        }
    }

    @Test func historyVerbsAreWords() {
        #expect(HistoryOutcome.allCases.map(\.verb) == [
            "Approved", "Rejected", "Answered", "Decided", "Withdrawn", "Transferred", "Expired",
        ])
    }

    @Test func keyValueListStacksAtAccessibilitySizes() {
        #expect(KeyValueList.stacks(forAccessibilitySize: DynamicTypeSize.large.isAccessibilitySize) == false)
        #expect(KeyValueList.stacks(forAccessibilitySize: DynamicTypeSize.accessibility3.isAccessibilitySize) == true)
    }

    @Test func commentRowSpeaksItsState() {
        #expect(CommentRow.accessibilityLabel(
            author: "Priya", isAgent: false, age: "3 minutes ago", text: "Looks good", state: .sent
        ) == "Priya, 3 minutes ago. Looks good.")
        #expect(CommentRow.accessibilityLabel(
            author: "CEO", isAgent: true, age: "now", text: "Done", state: .sending
        ) == "CEO, agent, now. Done. Sending.")
        #expect(CommentRow.accessibilityLabel(
            author: "You", isAgent: false, age: "now", text: "Hi", state: .failed
        ) == "You, now. Hi. Not sent.")
    }
}
