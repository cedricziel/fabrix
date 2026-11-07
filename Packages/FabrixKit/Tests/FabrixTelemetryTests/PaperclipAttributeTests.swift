@testable import FabrixTelemetry
import Testing

struct PaperclipAttributeTests {
    @Test func everyAttributeLivesUnderThePaperclipNamespace() {
        #expect(PaperclipAttribute.allCases.allSatisfy { $0.rawValue.hasPrefix("paperclip.") } == true)
    }

    @Test func attributeNamesAreUnique() {
        #expect(Set(PaperclipAttribute.allCases.map(\.rawValue)).count == PaperclipAttribute.allCases.count)
    }

    @Test func everyAttributeIsDescribed() {
        #expect(PaperclipAttribute.allCases.allSatisfy { !$0.summary.isEmpty })
    }

    @Test func theSetMatchesTheSpec() {
        #expect(PaperclipAttribute.allCases.map(\.rawValue).sorted() == [
            "paperclip.agent.status", "paperclip.api.route", "paperclip.approval.kind",
            "paperclip.auth.method", "paperclip.factory.id", "paperclip.run.adapter",
        ])
    }
}
