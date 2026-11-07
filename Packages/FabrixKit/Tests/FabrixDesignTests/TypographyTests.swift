import CoreText
import SwiftUI
@testable import FabrixDesign
import Testing

struct TypographyTests {
    @Test func registrationSucceeds() {
        #expect(FabrixFonts.register())
    }

    @Test func registrationIsIdempotent() {
        #expect(FabrixFonts.register())
        #expect(FabrixFonts.register())
    }

    @Test(arguments: FabrixFonts.Face.allCases)
    func everyFaceResolvesAfterRegistration(face: FabrixFonts.Face) {
        #expect(FabrixFonts.register())
        let font = CTFontCreateWithName(face.rawValue as CFString, 12, nil)
        #expect(CTFontCopyPostScriptName(font) as String == face.rawValue)
    }

    @Test(arguments: [
        (FabrixTextStyle.largeTitle, FabrixFonts.Face.spaceGroteskBold),
        (.title, .spaceGroteskSemiBold),
        (.metric, .spaceGroteskSemiBold),
        (.headline, .interSemiBold),
        (.body, .interRegular),
        (.subheadline, .interMedium),
        (.caption, .interRegular),
        (.label, .interSemiBold),
        (.link, .interMedium),
        (.eyebrow, .interSemiBold),
        (.tag, .interBold),
        (.mono, .jetBrainsMonoRegular),
        (.monoCaption, .jetBrainsMonoRegular),
    ])
    func faces(style: FabrixTextStyle, face: FabrixFonts.Face) {
        #expect(style.spec.face == face)
    }

    @Test(arguments: [
        (FabrixFonts.Face.jetBrainsMonoRegular, Font.Design.monospaced),
        (.interRegular, .default),
        (.spaceGroteskBold, .default),
    ])
    func fallbackKeepsMonoDesign(face: FabrixFonts.Face, design: Font.Design) {
        #expect(face.design == design)
    }

    @Test func sizesFollowTheFoundationsBoard() {
        #expect(FabrixTextStyle.largeTitle.spec.size == 34)
        #expect(FabrixTextStyle.title.spec.size == 22)
        #expect(FabrixTextStyle.mono.spec.size == 13)
        #if os(macOS)
            #expect(FabrixTextStyle.body.spec.size == 13)
        #else
            #expect(FabrixTextStyle.body.spec.size == 15)
        #endif
    }
}
