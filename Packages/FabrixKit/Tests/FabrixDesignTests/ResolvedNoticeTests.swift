import FabrixDesign
import Testing

@Suite struct ResolvedNoticeTests {
    @Test func personIncludesDecisionAndUnrecordedAction() {
        #expect(ResolvedNotice.resolvedNoticeText(
            resolverKind: .person, resolverName: "Priya", outcome: "approved",
            time: "14:29", unrecordedAction: "rejection"
        ) == "Priya decided: approved at 14:29. Your rejection wasn't recorded.")
    }

    @Test func agentUsesProvidedName() {
        #expect(ResolvedNotice.resolvedNoticeText(
            resolverKind: .agent, resolverName: "Triage agent", outcome: "declined",
            time: "09:05", unrecordedAction: ""
        ) == "Triage agent decided: declined at 09:05.")
    }

    @Test func unknownUsesSomeoneAndActionWording() {
        #expect(ResolvedNotice.resolvedNoticeText(
            resolverKind: .unknown, resolverName: "", outcome: "approved",
            time: "14:29", unrecordedAction: "rejection"
        ) == "Someone decided: approved at 14:29. Your rejection wasn't recorded.")
    }
}
