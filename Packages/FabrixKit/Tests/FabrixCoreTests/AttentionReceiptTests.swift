import Foundation
import Testing
@testable import FabrixCore

struct AttentionReceiptTests {
    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: value) { return date }
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            if let date = standard.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date: \(value)")
        }
        return decoder
    }

    @Test func routedReceiptMapsToDomainFeed() throws {
        let dto = try makeDecoder().decode(AttentionFeedDTO.self, from: Data(AttentionFixtures.routedReceipt.utf8))
        let feed = dto.domainFeed()
        #expect(feed.items.isEmpty)
        #expect(feed.deskBadgeCount == 0)
        #expect(feed.viewCounts == [.mine: 0, .unassigned: 0, .company: 1])
        let receipt = try #require(feed.receipts.first)
        let sourceId = try #require(dto.receipts?.first?.value?.sourceId)
        #expect(feed.receipts.count == 1)
        #expect(receipt.outcome == "transferred")
        #expect(receipt.source.kind == "issue_thread_interaction")
        #expect(receipt.source.id == sourceId)
        #expect(receipt.title == "Confirmation requested")
        #expect(receipt.reason == "Sandbox receipt capture return")
        #expect(receipt.actorUserID == "routed-user-2")
        #expect(receipt.transferredToUserID == "routed-user-2")
        #expect(receipt.task?.identifier == "ATL-10")
        #expect(receipt.task?.title == "Receipt capture confirmation")
        #expect(receipt.webPath?.contains("#interaction-") == true)
        #expect(receipt.expiresAt.timeIntervalSince(receipt.createdAt) == 604800)
        #expect(receipt.dismissalKey.contains(receipt.id))
    }

    @Test func malformedReceiptAndOptionalFieldsAreTolerated() throws {
        let fixture = try #require(JSONSerialization.jsonObject(with: Data(AttentionFixtures.routedReceipt.utf8)) as? [String: Any])
        var payload = fixture
        var receipts = try #require(fixture["receipts"] as? [[String: Any]])
        var valid = try #require(receipts.first)
        valid["issue"] = "malformed"
        valid["reason"] = 42
        payload["receipts"] = [["id": "bad"], valid]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let feed = try makeDecoder().decode(AttentionFeedDTO.self, from: data).domainFeed()
        #expect(feed.receipts.count == 1)
        #expect(feed.deskBadgeCount == 0)
        #expect(feed.receipts[0].task == nil)
        #expect(feed.receipts[0].reason == nil)
    }
}
