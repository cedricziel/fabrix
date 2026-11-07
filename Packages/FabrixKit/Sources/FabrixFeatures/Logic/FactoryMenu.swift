import FabrixCore

/// What the title menu and the macOS Factory menu offer: saved factories plus the demo,
/// the open factory's companies, and whether the open factory can be removed.
struct FactoryMenu: Equatable {
    struct FactoryItem: Identifiable, Equatable {
        var factory: Factory
        var isOpen: Bool
        var id: Factory.ID { factory.id }
    }

    struct CompanyItem: Identifiable, Equatable {
        var company: Company
        var isSelected: Bool
        /// 1…9 for Command-1…9, in list order.
        var shortcut: Int?
        var id: Company.ID { company.id }
    }

    var factories: [FactoryItem]
    var companies: [CompanyItem]
    var canRemove: Bool

    init(saved: [Factory], open: Factory?, companies: [Company], selectedCompanyID: Company.ID?) {
        let demo = FactoryConnection.demo().factory
        factories = (saved + [demo]).map { FactoryItem(factory: $0, isOpen: $0.id == open?.id) }
        self.companies = companies.enumerated().map { index, company in
            CompanyItem(company: company, isSelected: company.id == selectedCompanyID, shortcut: index < 9 ? index + 1 : nil)
        }
        canRemove = open.map { factory in saved.contains { $0.id == factory.id } } ?? false
    }
}
