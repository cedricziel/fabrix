import FabrixCore
import FabrixDesign

/// Monthly spend against an optional cap, in US cents.
struct Budget: Hashable {
    static let nearCap = BudgetMeter.warningThreshold

    var spentCents: Int
    var capCents: Int?

    var fraction: Double? {
        guard let capCents, capCents > 0 else { return nil }
        return Double(spentCents) / Double(capCents)
    }

    var isNearCap: Bool { (fraction ?? 0) >= Self.nearCap }
}

extension Agent {
    var budget: Budget { Budget(spentCents: spentMonthlyCents, capCents: budgetMonthlyCents) }
}

extension TaskStatus {
    var isOpen: Bool { self != .done && self != .cancelled }
}
