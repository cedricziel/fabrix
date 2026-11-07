@testable import FabrixDesign
import Testing

struct StatusStripTests {
    @Test func everyToneHasItsOwnLook() {
        let tones: [StatusStrip.Tone] = [.stale, .warning, .blocking]
        #expect(Set(tones.map(\.symbol)).count == tones.count)
    }

    @Test func blockingReadsAsAProblemNotJustStaleness() {
        #expect(StatusStrip.Tone.blocking.symbol != StatusStrip.Tone.stale.symbol)
        #expect(StatusStrip.Tone.blocking.tint != StatusStrip.Tone.stale.tint)
    }
}
