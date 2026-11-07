import FabrixCore
import FabrixDesign
import SwiftUI

extension TaskStatus {
    var title: LocalizedStringResource {
        switch self {
        case .backlog: LocalizedStringResource("Backlog", bundle: .module)
        case .todo: LocalizedStringResource("Todo", bundle: .module)
        case .inProgress: LocalizedStringResource("In progress", bundle: .module)
        case .inReview: LocalizedStringResource("In review", bundle: .module)
        case .blocked: LocalizedStringResource("Blocked", bundle: .module)
        case .done: LocalizedStringResource("Done", bundle: .module)
        case .cancelled: LocalizedStringResource("Cancelled", bundle: .module)
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
