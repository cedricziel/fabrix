import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
struct FactorySwitchingTests {
    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: UUID().uuidString)!
    }

    /// Connects `hosts` in order; the last one ends up open.
    private func connected(_ hosts: [String], defaults: UserDefaults? = nil) async -> (AppModel, RecordingConnector) {
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: defaults ?? freshDefaults())
        for host in hosts {
            await model.connect(ConnectForm(address: host, apiKey: "k"))
        }
        return (model, connector)
    }

    @Test func menuListsSavedFactoriesThenTheDemo() async {
        let (model, _) = await connected(["one.example", "two.example"])
        let menu = model.factoryMenu
        #expect(menu.factories.map(\.factory.name) == ["one.example", "two.example", "Demo factory"])
        #expect(menu.factories.map(\.isOpen) == [false, true, false])
        #expect(menu.canRemove)
    }

    @Test func menuMarksTheSelectedCompanyAndNumbersShortcuts() {
        let companies = (1 ... 11).map { Company(id: "c\($0)", name: "C\($0)") }
        let menu = FactoryMenu(saved: [], open: nil, companies: companies, selectedCompanyID: "c2")
        #expect(menu.companies.filter(\.isSelected).map(\.id) == ["c2"])
        #expect(menu.companies.map(\.shortcut) == [1, 2, 3, 4, 5, 6, 7, 8, 9, nil, nil])
    }

    @Test func demoCannotBeRemoved() async {
        let (model, _) = await connected(["one.example"])
        await model.exploreDemo()
        #expect(!model.factoryMenu.canRemove)
        #expect(model.factoryMenu.factories.last?.isOpen == true)
    }

    @Test func switchingCompanyFromTheMenu() async throws {
        let model = AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: TwoCompanyFactory()),
            defaults: freshDefaults()
        )
        await model.refresh()
        let orbit = try #require(model.factoryMenu.companies.first { $0.company.name == "Orbit" })

        await model.select(orbit.company)

        #expect(model.snapshot?.company.name == "Orbit")
        #expect(model.factoryMenu.companies.first { $0.isSelected }?.company.name == "Orbit")
    }

    @Test func switchingFactoryOpensItAndRemembersIt() async throws {
        let defaults = freshDefaults()
        let (model, connector) = await connected(["one.example", "two.example"], defaults: defaults)
        let one = try #require(connector.factories.first)

        await model.open(one)

        #expect(model.factory?.name == "one.example")
        #expect(model.loadState == .loaded)
        #expect(AppModel(connector: connector, defaults: defaults).factory?.name == "one.example")
    }

    @Test func switchingToTheDemoAndBack() async throws {
        let (model, connector) = await connected(["one.example"])
        await model.open(FactoryConnection.demo().factory)
        #expect(model.factory?.name == "Demo factory")

        await model.open(try #require(connector.factories.first))
        #expect(model.factory?.name == "one.example")
    }

    @Test func removingOpensTheNextSavedFactory() async {
        let (model, connector) = await connected(["one.example", "two.example"])

        await model.removeOpenFactory()

        #expect(connector.factories.map(\.name) == ["one.example"])
        #expect(model.factory?.name == "one.example")
        #expect(model.loadState == .loaded)
    }

    @Test func removingTheLastFactoryReturnsToOnboarding() async {
        let defaults = freshDefaults()
        let (model, connector) = await connected(["one.example"], defaults: defaults)

        await model.removeOpenFactory()

        #expect(connector.factories.isEmpty)
        #expect(model.isOnboarding)
        #expect(AppModel(connector: connector, defaults: defaults).isOnboarding)
    }

    @Test func failedRemoveKeepsTheFactoryOpen() async {
        let (model, connector) = await connected(["one.example"])
        connector.forgetError = ConnectFailure(message: "Keychain locked")

        await model.removeOpenFactory()

        #expect(model.factory?.name == "one.example")
        #expect(model.lastError == "Keychain locked")
    }

    @Test func removingTheDemoDoesNothing() async {
        let (model, connector) = await connected(["one.example"])
        await model.exploreDemo()

        await model.removeOpenFactory()

        #expect(model.factory?.name == "Demo factory")
        #expect(connector.factories.count == 1)
    }
}
