import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
struct ConnectionIssueTests {
    @Test(arguments: [
        (PaperclipError.transport(.cannotConnectToHost) as any Error, ConnectionIssue?.some(.unreachable)),
        (URLError(.notConnectedToInternet), .unreachable),
        (PaperclipError.unauthorized("Agent token did not verify"), .signedOut),
        (PaperclipError.signInRequired(nil), .signedOut),
        (PaperclipError.forbidden("Board access required"), .noAccess),
        (PaperclipError.server(status: 502, message: nil), .serverProblem(status: 502)),
        (PaperclipError.conflict(nil), .serverProblem(status: 409)),
        (PaperclipError.decoding("bad"), .unsupported),
        (CancellationError(), nil),
        (URLError(.cancelled), nil),
        (PaperclipError.transport(.cancelled), nil),
    ])
    func classifiesErrors(error: any Error, issue: ConnectionIssue?) {
        #expect(ConnectionIssue(classifying: error) == issue)
    }

    private func model(_ service: GatedService) -> AppModel {
        AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: service),
            defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
    }

    @Test func pollsReportConnectionProblemsButNotActionErrors() async {
        let service = GatedService()
        let model = model(service)
        await model.refresh()

        await service.failSnapshots(true)
        await model.refresh()

        #expect(model.connectionProblem?.issue == .unreachable)
        #expect(model.actionError == nil)
    }

    @Test func aGoodPollKeepsTheActionError() async throws {
        let service = GatedService(failingDecisions: [])
        let model = model(service)
        await model.refresh()
        await service.failPauses(true)
        let agent = try #require(model.agent("cto"))

        await model.pause(agent)
        #expect(model.actionError != nil)
        await model.refresh()

        #expect(model.actionError != nil)
        model.dismissActionError()
        #expect(model.actionError == nil)
    }

    @Test func aDismissedProblemReturnsOnlyWhenItsKindChanges() async {
        let service = GatedService()
        let model = model(service)
        await model.refresh()
        await service.failSnapshots(true)
        await model.refresh()

        model.dismissConnectionProblem()
        await model.refresh()
        #expect(model.visibleConnectionProblem == nil)

        await service.failSnapshots(false)
        await service.failCompanies(with: PaperclipError.unauthorized(nil))
        await model.refresh()
        #expect(model.visibleConnectionProblem?.issue == .signedOut)
    }
}
