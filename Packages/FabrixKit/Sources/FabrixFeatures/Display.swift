import FabrixCore
import FabrixDesign
import SwiftUI

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
        case .inReview: Color(red: 0.427, green: 0.157, blue: 0.851)
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
