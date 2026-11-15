import Testing
@testable import FabrixDesign

@Test func historyRowStartsWithVerb() {
    #expect(HistoryRow.announcement(verb: "Approved", actor: "Alex", context: "Hiring request", time: "2 minutes ago", reason: "Role approved") == "Approved, Alex, Hiring request, 2 minutes ago, Role approved")
}
