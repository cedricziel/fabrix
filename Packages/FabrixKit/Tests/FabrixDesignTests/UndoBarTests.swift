import Testing
@testable import FabrixDesign

@Test func countdownAnnouncesOnlyPhaseTransitions() {
    var state = UndoAnnouncementState()
    #expect(state.message(phase: .counting, verdict: "Approved", remainingSeconds: 8, failureReason: nil)?.contains("8") == true)
    for seconds in [7, 6] {
        #expect(state.message(phase: .counting, verdict: "Approved", remainingSeconds: seconds, failureReason: nil) == nil)
    }
    #expect(state.message(phase: .sending, verdict: "Approved", remainingSeconds: 0, failureReason: nil)?.contains("sending") == true)
    #expect(state.message(phase: .sent, verdict: "Approved", remainingSeconds: 0, failureReason: nil)?.contains("sent") == true)
    #expect(state.message(phase: .sent, verdict: "Approved", remainingSeconds: 0, failureReason: nil) == nil)
}

@Test func undoBarAnnouncements() {
    let counting = UndoBar.announcement(phase: .counting, verdict: "Approved", remainingSeconds: 8, failureReason: nil)
    #expect(counting.contains("Approved") && counting.contains("8"))
    #expect(UndoBar.announcement(phase: .sending, verdict: "Approved", remainingSeconds: 8, failureReason: nil).contains("sending"))
    #expect(UndoBar.announcement(phase: .sent, verdict: "Approved", remainingSeconds: 0, failureReason: nil).contains("sent"))
    #expect(UndoBar.announcement(phase: .held, verdict: "Approved", remainingSeconds: 0, failureReason: nil).contains("Not sent yet"))
    #expect(UndoBar.announcement(phase: .failed, verdict: "Approved", remainingSeconds: 0, failureReason: "Offline").contains("Not sent: Offline"))
}
