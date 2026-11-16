import Foundation
import Testing
@testable import FabrixCore

struct DemoInboxTests {
    @Test func demoViewsAndPeople() async throws {
        let service = DemoFactoryService(now: Date(timeIntervalSince1970: 1700000000))

        let mine = try await service.attention(companyID: "atlas", view: .mine, cursor: nil)
        let unassigned = try await service.attention(companyID: "atlas", view: .unassigned, cursor: nil)
        let company = try await service.attention(companyID: "atlas", view: .company, cursor: nil)

        #expect(mine.items.count == 8)
        #expect(unassigned.items.count == 1)
        #expect(company.items.count == 2)
        #expect(mine.deskBadgeCount == 8)
        #expect(unassigned.deskBadgeCount == 8)
        #expect(company.deskBadgeCount == 8)
        #expect(mine.viewCounts == [.mine: 8, .unassigned: 1, .company: 2])
        #expect(mine.receipts.count == 1)
        #expect(unassigned.receipts.isEmpty)
        #expect(company.receipts.isEmpty)

        #expect(mine.items.contains { $0.isCritical && $0.isProblem && $0.cardType == .budgetStop })
        #expect(mine.items.contains { $0.staleReason == "aged" })
        #expect(mine.items.contains { $0.audience?.transferredByUserID == "priya" })
        #expect(unassigned.items.first?.canClaim == true)

        let people = try await service.people(companyID: "atlas")
        #expect(people.map(\.id) == ["me", "priya", "sam"])
    }
}
