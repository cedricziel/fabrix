@testable import FabrixFeatures
import Testing

@MainActor
struct NavigatorTests {
    @Test func splitLayoutSwitchesSectionAndClearsThePath() {
        let navigator = Navigator()
        navigator.path.append("fe")
        navigator.open(.approvals)
        #expect(navigator.section == .approvals)
        #expect(navigator.path.isEmpty)
    }

    @Test func compactLayoutPicksTheTabForATabSection() {
        let navigator = Navigator()
        navigator.isCompact = true
        navigator.open(.approvals)
        #expect(navigator.tab == .approvals)
        #expect(navigator.tabPaths[.approvals]?.isEmpty == true)
    }

    @Test func compactLayoutPushesSectionsWithoutATabOntoFactory() {
        let navigator = Navigator()
        navigator.isCompact = true
        navigator.tab = .agents
        navigator.open(.activity)
        #expect(navigator.tab == .factory)
        #expect(navigator.tabPaths[.factory]?.count == 1)
    }
}
