import Foundation
import Testing
@testable import FabrixCore

struct AttentionMappingTests {
    struct Case: Sendable {
        let source: String
        let metadataJSON: String
        let expected: AttentionCardType
    }

    @Test(arguments: cases)
    func cardDerivation(testCase: Case) throws {
        let metadata = try JSONSerialization.jsonObject(with: Data(testCase.metadataJSON.utf8))
        let row: [String: Any] = [
            "id": "row-1",
            "sourceKind": testCase.source,
            "subject": [
                "id": "subject-1",
                "kind": "interaction",
                "title": "Test",
                "metadata": metadata
            ],
            "createdAt": 0,
            "activityAt": 0
        ]
        let data = try JSONSerialization.data(withJSONObject: row)
        let decoded = try JSONDecoder().decode(AttentionItemDTO.self, from: data)
        #expect(decoded.cardType == testCase.expected)
    }

    static let cases: [Case] = [
        .init(source: "approval", metadataJSON: "{}", expected: .boardApproval),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"request_confirmation"}"#, expected: .confirm),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"request_checkbox_confirmation"}"#, expected: .confirm),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"ask_user_questions"}"#, expected: .answerQuestions),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"suggest_tasks"}"#, expected: .suggestedTasks),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"request_item_verdicts"}"#, expected: .reviewItems),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"request_confirmation","isPlanTarget":true,"requestKind":"deliverable"}"#, expected: .reviewPlan),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"request_confirmation","requestKind":"deliverable"}"#, expected: .reviewDeliverable),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"ask_user_questions","requestKind":"tool_action"}"#, expected: .toolAccess),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"connection_intent"}"#, expected: .connectService),
        .init(source: "issue_thread_interaction", metadataJSON: #"{"kind":"future"}"#, expected: .unknown("future")),
        .init(source: "future", metadataJSON: "{}", expected: .unknown("future")),
        .init(source: "decision", metadataJSON: "{}", expected: .makeChoice),
        .init(source: "review", metadataJSON: #"{"reviewAttentionState":"stalled"}"#, expected: .blockedTask),
        .init(source: "review", metadataJSON: "{}", expected: .reviewTask)
    ]
}
