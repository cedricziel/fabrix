@testable import FabrixCore
import Foundation
import Testing

struct PaperclipErrorMessageTests {
    @Test(arguments: [
        (PaperclipError.unauthorized("Agent token did not verify; obtain fresh credentials and retry"),
         "Your sign-in expired or was revoked. Sign in again to continue."),
        (.forbidden("Board access required"), "You don't have access to this on the Paperclip board."),
        (.conflict("Company is not active"), "The company is paused. Resume it to wake agents."),
        (.conflict("Agent is not invokable in its current state"), "This agent can't be woken right now."),
        (.invalidRequest("Only pending or revision requested approvals can be rejected"),
         "This was already decided on the board."),
        (.notFound("Approval not found"), "This was removed or moved on the board."),
        (.server(status: 502, message: "Bad Gateway"), "The factory had a problem (502). Fabrix keeps trying."),
    ])
    func showsHumanTextInsteadOfServerJargon(error: PaperclipError, message: String) {
        #expect(error.localizedDescription == message)
    }

    @Test func keepsTheServerTextAsTheReason() {
        let error = PaperclipError.forbidden("Board access required")
        #expect(error.failureReason == "Board access required")
        #expect(PaperclipError.decoding("x").failureReason == nil)
    }

    @Test func keychainErrorsReadAsSentences() {
        #expect(!KeychainError(status: -25308).localizedDescription.contains("FabrixCore.KeychainError"))
    }
}
