import FabrixCore
import FabrixDesign
import SwiftUI

extension AgentStatus {
    var label: LocalizedStringKey {
        switch self {
        case .running: "Running"
        case .idle: "Idle"
        case .paused: "Paused"
        case .needsYou: "Needs you"
        case .blocked: "Blocked"
        case .error: "Error"
        }
    }

    var color: Color {
        switch self {
        case .running: Palette.run
        case .idle: Palette.idle
        case .paused: Palette.muted
        case .needsYou: Palette.signal
        case .blocked, .error: Palette.halt
        }
    }

    var isHollow: Bool {
        self == .paused || self == .needsYou
    }
}

extension TaskStatus {
    var title: LocalizedStringKey {
        switch self {
        case .backlog: "Backlog"
        case .todo: "Todo"
        case .inProgress: "In progress"
        case .inReview: "In review"
        case .blocked: "Blocked"
        case .done: "Done"
        case .cancelled: "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .backlog, .cancelled: Palette.idle
        case .todo: Palette.steel
        case .inProgress: Palette.run
        case .inReview: Palette.review
        case .blocked: Palette.halt
        case .done: Palette.done
        }
    }
}

extension ApprovalKind {
    var label: String {
        switch self {
        case .hire: String(localized: "Hire")
        case .strategy: String(localized: "Strategy")
        case .budget: String(localized: "Budget")
        case .other: String(localized: "Other")
        }
    }
}
