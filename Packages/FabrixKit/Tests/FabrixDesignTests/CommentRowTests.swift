import Testing
@testable import FabrixDesign

@Test func commentRowStatePresentation() {
    #expect(CommentRow.presentation(state: .normal, failureText: nil).isEmpty)
    #expect(CommentRow.presentation(state: .sending, failureText: nil) == ["Sending…"])
    #expect(CommentRow.presentation(state: .failed, failureText: "Try again later") == ["Failed", "Try again later"])
    #expect(CommentRow.presentation(state: .failed, failureText: nil) == ["Failed"])
}
