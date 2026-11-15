import Testing
@testable import FabrixDesign

@Suite("reasonFieldValidation")
struct ReasonFieldTests {
    @Test func emptyOptionalIsValid() { #expect(ReasonFieldValidation.validate("", required: false) == .valid) }
    @Test func whitespaceRequiredIsInvalid() { #expect(ReasonFieldValidation.validate(" \n\t", required: true) == .required) }
    @Test func fourThousandIsValid() { #expect(ReasonFieldValidation.validate(String(repeating: "a", count: 4_000), required: false) == .valid) }
    @Test func fourThousandOneIsTooLong() { #expect(ReasonFieldValidation.validate(String(repeating: "a", count: 4_001), required: false) == .tooLong) }
    @Test func validRequiredIsValid() { #expect(ReasonFieldValidation.validate("Because this matters", required: true) == .valid) }
}
