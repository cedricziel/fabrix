import FabrixCore
import FabrixDesign
import SwiftUI

/// Ticks once a second while visible.
struct ElapsedText: View {
    let since: Date

    var body: some View {
        TimelineView(.periodic(from: since, by: 1)) { context in
            Text(Elapsed.string(from: since, to: context.date))
                .monospacedDigit()
        }
    }
}

extension Binding {
    /// Shows a presentation while an optional selection is set; dismissing clears it.
    func isPresent<Wrapped: Sendable>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool> { wrappedValue != nil } set: { if !$0 { wrappedValue = nil } }
    }
}

extension BudgetBar {
    init(_ budget: Budget, height: CGFloat = 8) {
        self.init(spent: Double(budget.spentCents), limit: Double(budget.capCents ?? 0), height: height)
    }
}

extension AgentStatus {
    var style: StatusStyle {
        switch self {
        case .running: .running
        case .idle: .idle
        case .paused: .paused
        case .needsYou: .needsYou
        case .blocked, .error: .blocked
        }
    }
}
