@testable import FabrixDesign
import Foundation
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
