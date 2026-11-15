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

extension InboxComponentTests {
    @Test func reasonFieldValidation() {
        #expect(ReasonField.validate("", isRequired: true) == .missing)
        #expect(ReasonField.validate("  \n ", isRequired: true) == .missing)
        #expect(ReasonField.validate("", isRequired: false) == .valid)
        #expect(ReasonField.validate("Too late", isRequired: true) == .valid)
        #expect(ReasonField.validate(String(repeating: "a", count: 4000), isRequired: true) == .valid)
        #expect(ReasonField.validate(String(repeating: "a", count: 4001), isRequired: false) == .tooLong(excess: 1))
        #expect(ReasonField.limit == 4000)
    }

    @Test func reasonFieldSaysWhoReadsItAndIfRequired() {
        #expect(ReasonField.hint(reader: "the CEO agent") == "the CEO agent will read this.")
        #expect(ReasonField.requirementText(isRequired: true) == "Required")
        #expect(ReasonField.requirementText(isRequired: false) == "Optional")
        #expect(ReasonValidation.missing.message == "Add a reason.")
        #expect(ReasonValidation.tooLong(excess: 12).message == "12 characters too long.")
        #expect(ReasonValidation.valid.message == nil)
    }

    @Test func verdictPickerRequiresReason() {
        let required: Set<VerdictChoice> = [.reject]
        #expect(VerdictPicker.requiresReason(.reject, in: required))
        #expect(!VerdictPicker.requiresReason(.approve, in: required))
        #expect(!VerdictPicker.requiresReason(nil, in: required))

        #expect(!VerdictPicker.isComplete(verdict: nil, reason: "", requiredFor: required))
        #expect(VerdictPicker.isComplete(verdict: .approve, reason: "", requiredFor: required))
        #expect(!VerdictPicker.isComplete(verdict: .reject, reason: " ", requiredFor: required))
        #expect(VerdictPicker.isComplete(verdict: .reject, reason: "Wrong scope", requiredFor: required))
        #expect(!VerdictPicker.isComplete(
            verdict: .reject, reason: String(repeating: "a", count: 4001), requiredFor: required
        ))
    }

    @Test func verdictsSayTheirNames() {
        #expect(VerdictChoice.allCases.map(\.title) == ["Approve", "Reject", "Defer"])
    }

    @Test func choiceRowSpeaksItsState() {
        #expect(ChoiceRow.accessibilityLabel(label: "Courier", description: "Cheaper", isRecommended: true)
            == "Courier. Cheaper. Recommended.")
        #expect(ChoiceRow.accessibilityLabel(label: "Other", description: nil, isRecommended: false) == "Other.")
    }

    @Test func decisionBarDisabledReason() {
        #expect(DecisionBar.statusLine(status: "Waiting on you", disabledReason: "You're offline", isSending: false)
            == "You're offline")
        #expect(DecisionBar.statusLine(status: "Waiting on you", disabledReason: nil, isSending: false)
            == "Waiting on you")
        #expect(DecisionBar.statusLine(status: nil, disabledReason: nil, isSending: true) == "Sending…")
        #expect(DecisionBar.statusLine(status: nil, disabledReason: nil, isSending: false) == nil)
        #expect(DecisionBar.isDisabled(disabledReason: "You're offline", isSending: false))
        #expect(DecisionBar.isDisabled(disabledReason: nil, isSending: true))
        #expect(!DecisionBar.isDisabled(disabledReason: nil, isSending: false))
    }

    @Test func undoBarAnnouncements() {
        let en = Locale(identifier: "en_US")
        #expect(UndoBar.announcement(verdict: "Approved", phase: .counting(secondsLeft: 8), locale: en)
            == "Approved. Sending in 8 seconds.")
        #expect(UndoBar.announcement(verdict: "Approved", phase: .counting(secondsLeft: 1), locale: en)
            == "Approved. Sending in 1 second.")
        #expect(UndoBar.announcement(verdict: "Approved", phase: .sending, locale: en) == "Sending.")
        #expect(UndoBar.announcement(verdict: "Approved", phase: .sent, locale: en) == "Sent.")
        #expect(UndoBar.announcement(verdict: "Approved", phase: .failed(reason: "You're offline"), locale: en)
            == "Not sent. You're offline.")
    }

    @Test func undoBarShowsTimeLeftAsText() {
        let en = Locale(identifier: "en_US")
        #expect(UndoBar.timeLeftText(secondsLeft: 6, locale: en) == "Sending in 6 sec")
        #expect(UndoBar.timeLeftText(secondsLeft: -2, locale: en) == "Sending in 0 sec")
    }

    @Test func undoBarCountdownOnlyAnnouncesOncePerPhase() {
        #expect(UndoPhase.counting(secondsLeft: 8).kind == UndoPhase.counting(secondsLeft: 3).kind)
        #expect(UndoPhase.counting(secondsLeft: 8).kind != UndoPhase.sending.kind)
        #expect(UndoPhase.failed(reason: "a").kind == UndoPhase.failed(reason: "b").kind)
    }

    @Test func resolvedNoticeText() {
        #expect(ResolvedNotice.text(resolver: .person("Priya"), outcome: "approved", time: "14:29", attempted: "rejection")
            == "Priya approved this at 14:29. Your rejection wasn't recorded.")
        #expect(ResolvedNotice.text(resolver: .agent("CEO"), outcome: "approved", time: "14:29", attempted: "rejection")
            == "The CEO agent approved this at 14:29. Your rejection wasn't recorded.")
        #expect(ResolvedNotice.text(resolver: .person("Priya"), outcome: "rejected", time: nil, attempted: "approval")
            == "Priya rejected this. Your approval wasn't recorded.")
        #expect(ResolvedNotice.text(resolver: .unknown, outcome: "approved", time: "14:29", attempted: "rejection")
            == "This was already decided. Your rejection wasn't recorded.")
    }
}
