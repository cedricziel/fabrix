import FabrixCore
import FabrixDesign
import SwiftUI

extension TaskStatus {
    var title: LocalizedStringResource {
        switch self {
        case .backlog: .features("Backlog")
        case .todo: .features("Todo")
        case .inProgress: .features("In progress")
        case .inReview: .features("In review")
        case .blocked: .features("Blocked")
        case .done: .features("Done")
        case .cancelled: .features("Cancelled")
        }
    }

    var color: Color {
        switch self {
        case .backlog, .cancelled: Palette.idle
        case .todo: Palette.steel
        case .inProgress: Palette.run
        case .inReview: Color(red: 0.427, green: 0.157, blue: 0.851)
        case .blocked: Palette.halt
        case .done: Palette.done
        }
    }
}

extension ApprovalKind {
    var label: String {
        switch self {
        case .hire: String(localized: "Hire", bundle: .module)
        case .strategy: String(localized: "Strategy", bundle: .module)
        case .budget: String(localized: "Budget", bundle: .module)
        case .other: String(localized: "Other", bundle: .module)
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

extension ProjectStatus {
    var style: ProjectStatusStyle {
        switch self {
        case .backlog: .backlog
        case .planned: .planned
        case .inProgress: .inProgress
        case .completed: .completed
        case .cancelled: .cancelled
        case .other: .other
        }
    }
}

extension Project {
    /// The target date on the day Paperclip stores, in the user's calendar.
    var targetDay: Date? {
        targetDate.flatMap { Calendar.current.date(from: DateComponents(year: $0.year, month: $0.month, day: $0.day)) }
    }
}
