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
