@testable import FabrixDesign
import SwiftUI
import Testing

@MainActor
struct LocalizedInitTests {
    @Test func kindTagKeepsNaturalCaseForVoiceOver() {
        #expect(KindTag(title: "Hire").title == Text(verbatim: "Hire"))
    }

    @Test func kindTagsWaitOnYouUnlessToldOtherwise() {
        #expect(KindTag(.hire).tone == .signal)
        #expect(KindTag(title: "Primary", tone: .neutral).tone == .neutral)
    }

    @Test func eyebrowHeaderKeepsNaturalCase() {
        #expect(SectionHeader("Factories", style: .eyebrow).title == Text(verbatim: "Factories"))
    }

    @Test func localizedTitlesStayResources() {
        let title: LocalizedStringResource = "Live runs"
        #expect(SectionHeader(title).title == Text(title))
    }
}
