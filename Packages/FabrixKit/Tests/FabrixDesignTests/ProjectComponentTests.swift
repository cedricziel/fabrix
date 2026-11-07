@testable import FabrixDesign
import Testing

struct ProjectComponentTests {
    @Test(arguments: [("#0F766E", UInt32(0x0F766E)), ("7c3aed", 0x7C3AED), (" #BE185D ", 0xBE185D)])
    func parsesHex(hex: String, expected: UInt32) {
        #expect(ProjectColor.rgb(hex) == expected)
    }

    @Test(arguments: [nil, "", "#12345", "#GGGGGG", "red"] as [String?])
    func invalidHexFallsBack(hex: String?) {
        #expect(ProjectColor.rgb(hex) == nil)
    }

    @Test func countsBarFractions() {
        let parts = TaskCountsBar.fractions(open: 7, blocked: 1, done: 4)
        #expect(abs(parts.done + parts.blocked + parts.open - 1) < 0.000_1)
        #expect(abs(parts.done - 4.0 / 12) < 0.000_1)
    }

    @Test func emptyProjectHasEmptyBar() {
        let parts = TaskCountsBar.fractions(open: 0, blocked: 0, done: 0)
        #expect(parts.done == 0 && parts.blocked == 0 && parts.open == 0)
    }

    @Test(arguments: [
        (ProjectStatusStyle.backlog, StatusStyle.idle, "Backlog"),
        (.planned, .idle, "Planned"),
        (.inProgress, .running, "In progress"),
        (.completed, .done, "Completed"),
        (.cancelled, .idle, "Cancelled"),
        (.other, .idle, "Other"),
    ])
    func statusStyle(style: ProjectStatusStyle, status: StatusStyle, label: String) {
        #expect(style.statusStyle == status)
        #expect(style.label == label)
    }
}
