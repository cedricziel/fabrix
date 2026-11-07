import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
struct PendingActionTests {
    private func model(_ service: GatedService) -> AppModel {
        AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service),
            defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
    }

    @Test func anActionIsPendingUntilItsRefreshLands() async throws {
        let service = GatedService()
        let model = model(service)
        await model.refresh()
        let agent = try #require(model.agent("cto"))

        await service.holdNextSnapshot()
        let pausing = Task { await model.pause(agent) }
        await service.waitUntilHolding()
        #expect(model.isPending(.pause("cto")))

        await model.pause(agent)
        #expect(await service.pauseCalls == 1)

        await service.release()
        await pausing.value
        #expect(!model.isPending(.pause("cto")))
    }

    @Test func wakeIsUnavailableInAPausedCompany() async throws {
        let model = model(GatedService())
        await model.refresh()
        let ops = try #require(model.agent("ops"))
        #expect(model.canWake(ops))

        await model.setCompanyPaused(true)

        #expect(!model.canWake(ops))
    }

    @Test func runningAgentsCannotBeWoken() async throws {
        let model = model(GatedService())
        await model.refresh()
        #expect(!model.canWake(try #require(model.agent("cto"))))
    }
}
