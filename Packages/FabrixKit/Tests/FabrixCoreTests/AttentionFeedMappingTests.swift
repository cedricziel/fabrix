import Foundation
import Testing
@testable import FabrixCore

struct AttentionFeedMappingTests {
    @Test func capturedEvidencePreservesCounts() throws {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            guard let date = formatter.date(from: value) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO 8601 date: \(value)")
            }
            return date
        }

        let dto = try decoder.decode(AttentionFeedDTO.self, from: Data(AttentionFixtures.routedEvidence.utf8))
        let rawItems = dto.items.compactMap(\.value)
        let evidence = try #require(rawItems.first {
            $0.obligationLeadId != nil && $0.obligationLeadId != $0.id
        })
        let feed = dto.domainFeed()
        let lead = try #require(feed.items.first { $0.id == evidence.obligationLeadId })

        #expect(lead.evidence.contains { $0.id == evidence.id })
        #expect(feed.items.count == rawItems.count - 1)
        #expect(feed.deskBadgeCount == dto.deskBadgeCount)
        #expect(feed.nextCursor == dto.nextCursor)
    }
}
