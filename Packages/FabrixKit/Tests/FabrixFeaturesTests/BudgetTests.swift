@testable import FabrixFeatures
import Testing

struct BudgetTests {
    @Test func fractionNeedsAPositiveCap() {
        #expect(Budget(spentCents: 50, capCents: 200).fraction == 0.25)
        #expect(Budget(spentCents: 50, capCents: nil).fraction == nil)
        #expect(Budget(spentCents: 50, capCents: 0).fraction == nil)
    }

    @Test func nearCapFromNinetyPercent() {
        #expect(Budget(spentCents: 18_800, capCents: 20_000).isNearCap)
        #expect(!Budget(spentCents: 17_900, capCents: 20_000).isNearCap)
        #expect(!Budget(spentCents: 100, capCents: nil).isNearCap)
    }
}
