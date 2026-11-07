import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
struct CompanyGoneTests {
    private func model(_ service: GatedService) -> AppModel {
        AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service),
            defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
    }

    @Test func aDeletedCompanyFallsBackToTheNextOneWithANotice() async throws {
        let service = GatedService(TwoCompanyFactory())
        let model = model(service)
        await model.refresh()
        let orbit = try #require(model.companies.first { $0.name == "Orbit" })
        await model.select(orbit)
        #expect(model.snapshot?.company.name == "Orbit")

        await service.removeCompany("orbit")
        await model.refresh()

        #expect(model.snapshot?.company.name == "Atlas")
        #expect(model.companies.map(\.name) == ["Atlas"])
        #expect(model.actionError == "Orbit is no longer available.")
        #expect(model.connectionProblem == nil)
    }

    @Test func theLastCompanyGoingAwayShowsTheEmptyState() async {
        let service = GatedService()
        let model = model(service)
        await model.refresh()

        await service.removeCompany("atlas")
        await model.refresh()

        #expect(model.loadState == .empty)
        #expect(model.snapshot == nil)
        #expect(model.actionError == "Atlas is no longer available.")
    }

    @Test func noAccessToAListedCompanyIsAConnectionProblem() async {
        let service = GatedService()
        let model = model(service)
        await model.refresh()

        await service.failSnapshots(true)
        await model.refresh()

        #expect(model.snapshot?.company.name == "Atlas")
        #expect(model.actionError == nil)
        #expect(model.connectionProblem != nil)
    }
}
