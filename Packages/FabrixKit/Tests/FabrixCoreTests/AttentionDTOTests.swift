import Foundation
import Testing
@testable import FabrixCore

struct AttentionDTOTests {
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

    @Test func recordedFeedsDecode() throws {
        let decoder = makeDecoder()

        let legacy = try decoder.decode(AttentionFeedDTO.self, from: Data(AttentionFixtures.legacyMine.utf8))
        #expect(legacy.items.count == 3)
        #expect(legacy.items.compactMap(\.value).count == 3)
        #expect(legacy.viewCounts == nil)

        let routed = try decoder.decode(AttentionFeedDTO.self, from: Data(AttentionFixtures.routedMine.utf8))
        #expect(routed.items.count == 8)
        #expect(routed.items.compactMap(\.value).count == 8)
        #expect(routed.viewCounts != nil)
    }

    @Test func malformedRowIsSkipped() throws {
        let fixture = try #require(JSONSerialization.jsonObject(with: Data(AttentionFixtures.routedMine.utf8)) as? [String: Any])
        var payload = fixture
        let items = try #require(fixture["items"] as? [[String: Any]])
        payload["items"] = [["id": "broken"]] + items
        let data = try JSONSerialization.data(withJSONObject: payload)
        let feed = try makeDecoder().decode(AttentionFeedDTO.self, from: data)
        #expect(feed.items.count == 9)
        #expect(feed.items.compactMap(\.value).count == 8)
        #expect(feed.items.first?.value == nil)
        #expect(feed.deskBadgeCount == 8)
    }

    @Test func invalidEnvelopeFails() {
        let decoder = makeDecoder()
        #expect(throws: DecodingError.self) {
            try decoder.decode(AttentionFeedDTO.self, from: Data(#"{"items":[]}"#.utf8))
        }
        #expect(throws: DecodingError.self) {
            try decoder.decode(AttentionFeedDTO.self, from: Data(#"{"items":"bad","deskBadgeCount":8}"#.utf8))
        }
    }
}
