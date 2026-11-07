@testable import FabrixDesign
import Testing

struct BudgetMeterTests {
    @Test func ratioIsSpentOverLimit() {
        #expect(BudgetMeter(spent: 412, limit: 1000).ratio == 0.412)
    }

    @Test func ratioClampsAboveLimit() {
        #expect(BudgetMeter(spent: 250, limit: 200).ratio == 1)
    }

    @Test func ratioClampsNegativeSpend() {
        #expect(BudgetMeter(spent: -5, limit: 200).ratio == 0)
    }

    @Test(arguments: [0.0, -10.0])
    func ratioIsZeroWithoutAPositiveLimit(limit: Double) {
        #expect(BudgetMeter(spent: 50, limit: limit).ratio == 0)
    }

    @Test func warnsFromNinetyPercent() {
        #expect(!BudgetMeter(spent: 89, limit: 100).isNearLimit)
        #expect(BudgetMeter(spent: 90, limit: 100).isNearLimit)
        #expect(BudgetMeter(spent: 188, limit: 200).isNearLimit)
    }

    @Test func percentRoundsDown() {
        #expect(BudgetMeter(spent: 188, limit: 200).percent == 94)
        #expect(BudgetMeter(spent: 999, limit: 1000).percent == 99)
    }
}
