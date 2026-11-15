import Testing
@testable import FabrixDesign

struct VerdictPickerTests {
    @Test func verdictPickerRequiresReason() {
        #expect(VerdictPicker.requiresReason(for: .reject, requiredFor: [.reject]))
        #expect(!VerdictPicker.requiresReason(for: .approve, requiredFor: [.reject]))
        #expect(!VerdictPicker.requiresReason(for: .deferVerdict, requiredFor: [.reject]))
        #expect(!VerdictPicker.requiresReason(for: nil, requiredFor: [.reject]))
        #expect(VerdictChoice.allCases.allSatisfy { VerdictPicker.requiresReason(for: $0, requiredFor: Set(VerdictChoice.allCases)) })
    }
}
