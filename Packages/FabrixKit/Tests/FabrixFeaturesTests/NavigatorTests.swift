@testable import FabrixFeatures
import SwiftUI
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

    @Test func factoryTabOffersTheSectionsWithoutATab() {
        #expect(CompactTab.factory.nestedSections == [.orgChart, .activity])
        #expect(CompactTab.tasks.nestedSections.isEmpty)
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

struct ScenePolicyTests {
    @Test func pollingContinuesWhileInactive() {
        #expect(ScenePolicy.keepsPolling(.active))
        #expect(ScenePolicy.keepsPolling(.inactive))
        #expect(!ScenePolicy.keepsPolling(.background))
    }

    @Test func decisionsAreSentOnlyOnReachingTheBackground() {
        #expect(!ScenePolicy.commitsDecisions(.active))
        #expect(!ScenePolicy.commitsDecisions(.inactive))
        #expect(ScenePolicy.commitsDecisions(.background))
    }
}

@MainActor
struct NavigatorResetTests {
    @Test func switchingContextReturnsEveryStackToItsRoot() {
        let navigator = Navigator()
        navigator.path.append("fe")
        navigator.isCompact = true
        navigator.open(.activity)

        navigator.resetPaths()

        #expect(navigator.path.isEmpty)
        #expect(navigator.tabPaths.isEmpty)
    }
}
