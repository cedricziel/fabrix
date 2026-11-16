import Foundation
import Testing
@testable import FabrixCore

struct AttentionEvidenceTests {
    private func item(_ id: String, lead: String? = nil) -> AttentionItem {
        AttentionItem(
            id: id,
            source: AttentionSource(kind: "approval", id: id),
            cardType: .boardApproval,
            title: id,
            createdAt: Date(timeIntervalSince1970: 0),
            activityAt: Date(timeIntervalSince1970: 0),
            obligationLeadID: lead
        )
    }

    @Test func foldsEvidenceInInputOrderAndKeepsTopLevelOrder() {
        let result = foldAttentionEvidence([item("lead", lead: "lead"), item("e1", lead: "lead"), item("other"), item("e2", lead: "lead")])
        #expect(result.map(\.id) == ["lead", "other"])
        #expect(result[0].evidence.map(\.id) == ["e1", "e2"])
    }

    @Test func foldsEvidenceThatPrecedesLead() {
        let result = foldAttentionEvidence([item("e1", lead: "lead"), item("other"), item("lead")])
        #expect(result.map(\.id) == ["other", "lead"])
        #expect(result[1].evidence.map(\.id) == ["e1"])
    }

    @Test func retainsOrphansAndSelfReferences() {
        let input = [item("orphan", lead: "missing"), item("self", lead: "self")]
        #expect(foldAttentionEvidence(input).map(\.id) == input.map(\.id))
    }

    @Test func retainsCyclesAndChains() {
        let cycle = [item("A", lead: "B"), item("B", lead: "A")]
        let chain = [item("A", lead: "B"), item("B", lead: "C"), item("C")]
        #expect(foldAttentionEvidence(cycle).map(\.id) == cycle.map(\.id))
        #expect(foldAttentionEvidence(chain).map(\.id) == chain.map(\.id))
    }

    @Test func retainsAmbiguousDuplicateIDsWithoutLosingRows() {
        let input = [item("lead"), item("lead"), item("e", lead: "lead"), item("e", lead: "lead")]
        let result = foldAttentionEvidence(input)
        #expect(result.map(\.id) == input.map(\.id))
        #expect(result.count == input.count)
    }
}
