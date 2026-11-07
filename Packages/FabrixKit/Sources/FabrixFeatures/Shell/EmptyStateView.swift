import SwiftUI

/// The empty state for a list that can also be searched: what's missing, or what didn't match.
struct EmptyStateView: View {
    let emptiness: ListEmptiness
    let title: LocalizedStringResource
    let systemImage: String
    let hint: LocalizedStringResource

    var body: some View {
        switch emptiness {
        case .notEmpty:
            EmptyView()
        case .noData:
            ContentUnavailableView {
                Label(title, systemImage: systemImage)
            } description: {
                Text(hint)
            }
        case let .noResults(query):
            ContentUnavailableView.search(text: query)
        }
    }
}
