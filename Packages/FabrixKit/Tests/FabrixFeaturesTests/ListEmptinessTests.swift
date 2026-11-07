@testable import FabrixFeatures
import Testing

struct ListEmptinessTests {
    @Test func aCompanyWithNothingYetIsNoData() {
        #expect(ListEmptiness(total: 0, visible: 0, query: "") == .noData)
        #expect(ListEmptiness(total: 0, visible: 0, query: "atl") == .noData)
    }

    @Test func aSearchThatMatchesNothingNamesTheQuery() {
        #expect(ListEmptiness(total: 9, visible: 0, query: " atl-999 ") == .noResults(query: "atl-999"))
    }

    @Test func anythingVisibleIsNotEmpty() {
        #expect(ListEmptiness(total: 9, visible: 2, query: "atl") == .notEmpty)
    }
}
