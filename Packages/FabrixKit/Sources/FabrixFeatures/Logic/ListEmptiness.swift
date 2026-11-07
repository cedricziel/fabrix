/// Why a list shows nothing: the company has nothing yet, or the search matched nothing.
enum ListEmptiness: Equatable {
    case notEmpty
    case noData
    case noResults(query: String)

    init(total: Int, visible: Int, query: String) {
        let query = query.trimmingCharacters(in: .whitespaces)
        if visible > 0 {
            self = .notEmpty
        } else if total > 0 && !query.isEmpty {
            self = .noResults(query: query)
        } else {
            self = .noData
        }
    }
}
