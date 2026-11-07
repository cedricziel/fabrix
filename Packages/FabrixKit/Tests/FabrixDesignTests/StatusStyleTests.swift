@testable import FabrixDesign
import Testing

struct StatusStyleTests {
    @Test(arguments: [
        (StatusStyle.running, "Running"),
        (.idle, "Idle"),
        (.paused, "Paused"),
        (.needsYou, "Needs you"),
        (.blocked, "Blocked"),
        (.done, "Done"),
    ])
    func label(style: StatusStyle, expected: String) {
        #expect(style.label == expected)
    }

    @Test func hollowDotsMarkPausedAndNeedsYou() {
        let hollow = StatusStyle.allCases.filter { $0.dot == .hollow }
        #expect(hollow == [.paused, .needsYou])
    }

    @Test func onlyNeedsYouUsesSignal() {
        let signal = StatusStyle.allCases.filter { $0.tone == .signal }
        #expect(signal == [.needsYou])
    }

    @Test(arguments: [
        (StatusStyle.running, Tone.run),
        (.idle, .neutral),
        (.paused, .neutral),
        (.needsYou, .signal),
        (.blocked, .halt),
        (.done, .done),
    ])
    func tone(style: StatusStyle, expected: Tone) {
        #expect(style.tone == expected)
    }
}
