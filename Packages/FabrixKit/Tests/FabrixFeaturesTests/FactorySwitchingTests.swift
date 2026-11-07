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

    @Test func removingSendsDecisionsStillInTheirUndoWindow() async throws {
        let connector = RecordingConnector()
        let service = DemoFactoryService()
        connector.service = service
        let model = AppModel(connector: connector, defaults: freshDefaults(), undoWindow: .seconds(60))
        await model.connect(ConnectForm(address: "one.example", apiKey: "k"))
        let approval = try #require(model.waitingApprovals.first)
        model.decide(approval, approve: true)

        await model.removeOpenFactory()

        let sent = try await service.snapshot(companyID: "atlas").approvals.first { $0.id == approval.id }
        #expect(sent?.state == .approved)
    }

    @Test func anotherWindowLeavesAFactoryRemovedElsewhere() async {
        let connector = RecordingConnector()
        let defaults = freshDefaults()
        let windowA = AppModel(connector: connector, defaults: defaults)
        await windowA.connect(ConnectForm(address: "one.example", apiKey: "k"))
        await windowA.connect(ConnectForm(address: "two.example", apiKey: "k"))
        let windowB = AppModel(connector: connector, defaults: defaults)
        #expect(windowB.factory?.name == "two.example")

        await windowA.removeOpenFactory()
        await windowB.leaveIfRemoved()

        #expect(windowB.factory?.name == "one.example")
    }

    @Test func windowsOnAFactoryThatStillExistsStayPut() async {
        let (model, _) = await connected(["one.example"])
        await model.leaveIfRemoved()
        #expect(model.factory?.name == "one.example")
        await model.exploreDemo()
        await model.leaveIfRemoved()
        #expect(model.factory?.name == "Demo factory")
    }

    @Test func switchingFactorySendsStagedDecisionsToTheFactoryTheyBelongTo() async throws {
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: freshDefaults(), undoWindow: .milliseconds(50))
        await model.connect(ConnectForm(address: "one.example", apiKey: "k"))
        await model.connect(ConnectForm(address: "two.example", apiKey: "k"))
        let one = try #require(connector.factories.first)
        let two = try #require(connector.factories.last)
        let approval = try #require(model.waitingApprovals.first)
        model.decide(approval, approve: true)

        await model.open(one)
        try await Task.sleep(for: .milliseconds(200))

        let sentToTwo = try await connector.saved[two.id]?.service.snapshot(companyID: "atlas")
        let sentToOne = try await connector.saved[one.id]?.service.snapshot(companyID: "atlas")
        #expect(sentToTwo?.approvals.first { $0.id == approval.id }?.state == .approved)
        #expect(sentToOne?.approvals.first { $0.id == approval.id }?.state == .pending)
        #expect(model.waitingApprovals.contains { $0.id == approval.id })
    }

    @Test func switchingToTheDemoSendsStagedDecisionsFirst() async throws {
        let connector = RecordingConnector()
        let model = AppModel(connector: connector, defaults: freshDefaults(), undoWindow: .seconds(60))
        await model.connect(ConnectForm(address: "one.example", apiKey: "k"))
        let one = try #require(connector.factories.first)
        let approval = try #require(model.waitingApprovals.first)
        model.decide(approval, approve: false)

        await model.exploreDemo()

        let sent = try await connector.saved[one.id]?.service.snapshot(companyID: "atlas")
        #expect(sent?.approvals.first { $0.id == approval.id }?.state == .rejected)
        #expect(model.waitingApprovals.contains { $0.id == approval.id })
    }

    @Test func aSecondConnectWhileOneIsRunningIsIgnored() async {
        let connector = RecordingConnector()
        connector.delay = .milliseconds(100)
        let model = AppModel(connector: connector, defaults: freshDefaults())

        async let first = model.connect(ConnectForm(address: "one.example", apiKey: "k"))
        async let second = model.connect(ConnectForm(address: "two.example", apiKey: "k"))
        let results = await [first, second]

        #expect(connector.calls.count == 1)
        #expect(results.filter { $0 }.count == 1)
    }
}
