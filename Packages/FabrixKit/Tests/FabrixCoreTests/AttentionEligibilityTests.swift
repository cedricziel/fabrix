import Foundation
import Testing
@testable import FabrixCore

struct AttentionEligibilityTests {
    private func item(source: String = "issue_thread_interaction", kind: String = "interaction", status: String = "pending", metadata: [String: Any] = ["kind": "request_confirmation"], detail: [String: Any]? = nil, audience: [String: Any]? = nil) throws -> AttentionItemDTO {
        var subject: [String: Any] = ["id": "subject-1", "kind": kind, "title": "Test", "status": status, "metadata": metadata]
        if let detail { subject["detail"] = detail }
        var row: [String: Any] = ["id": "row-1", "sourceKind": source, "subject": subject, "createdAt": 0, "activityAt": 0]
        if let detail { row["detail"] = detail }
        if let audience { row["audience"] = audience }
        return try JSONDecoder().decode(AttentionItemDTO.self, from: JSONSerialization.data(withJSONObject: row))
    }

    @Test func answerEligibility() throws {
        #expect(try item(source: "approval", kind: "approval").answer == .approval(sourceID: "subject-1"))
        #expect(try item(metadata: ["kind": "request_confirmation"]).answer == .confirmation)
        #expect(try item(status: "done").answer == .openInPaperclip)
        #expect(try item(kind: "issue").answer == .openInPaperclip)
        #expect(try item(metadata: ["kind": "request_checkbox_confirmation"]).answer == .openInPaperclip)
        #expect(try item(detail: ["kind": "checkbox_confirmation"]).answer == .openInPaperclip)
        #expect(try item(metadata: ["kind": "ask_user_questions"]).answer == .openInPaperclip)
        #expect(try item(metadata: ["kind": "request_item_verdicts"]).answer == .verdicts)
        #expect(try item(metadata: ["kind": "request_confirmation", "requestKind": "tool_action"]).answer == .openInPaperclip)
        #expect(try item(metadata: ["kind": "request_confirmation", "secretProposal": ["x": 1]]).answer == .openInPaperclip)
        #expect(try item(metadata: ["kind": "request_confirmation", "secretProposal": NSNull()]).answer == .confirmation)
    }

    @Test func routingEligibility() throws {
        let pool = try item(audience: ["kind": "pool"])
        let user = try item(audience: ["kind": "user"])
        let unknown = try item(metadata: ["kind": "future"])
        #expect(pool.canClaim(supportsRouting: true)); #expect(pool.canTransfer(supportsRouting: true))
        #expect(!user.canClaim(supportsRouting: true)); #expect(user.canTransfer(supportsRouting: true))
        #expect(!pool.canClaim(supportsRouting: false)); #expect(!pool.canTransfer(supportsRouting: false))
        #expect(!unknown.canClaim(supportsRouting: true)); #expect(!unknown.canTransfer(supportsRouting: true))
    }
    @Test func malformedRequestKindFailsClosed() throws {
        for value: Any in [true, 42, "", [String: String](), ["future"]] {
            let dto = try item(metadata: ["kind": "request_confirmation", "requestKind": value], audience: ["kind": "pool"])
            #expect(dto.answer == .openInPaperclip)
            #expect(!dto.canClaim(supportsRouting: true))
            #expect(!dto.canTransfer(supportsRouting: true))
        }
        #expect(try item(metadata: ["kind": "request_confirmation", "requestKind": NSNull()]).answer == .confirmation)
    }

}
