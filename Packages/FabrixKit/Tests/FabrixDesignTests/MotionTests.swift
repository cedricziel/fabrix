@testable import FabrixDesign
import Testing

struct MotionTests {
    @Test func slidesWhenMotionIsAllowed() {
        #expect(FabrixTransition.slideIn(from: .top).resolved(reduceMotion: false) == .slideAndFade(.top))
    }

    @Test func fadesWithReduceMotion() {
        #expect(FabrixTransition.slideIn(from: .top).resolved(reduceMotion: true) == .fade)
    }
}
