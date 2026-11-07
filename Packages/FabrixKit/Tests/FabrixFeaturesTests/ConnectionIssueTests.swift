import FabrixCore
import FabrixDesign
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

    @Test func timersFreezeWhileTheFactoryCannotBeRefreshed() async {
        let service = GatedService()
        let model = model(service)
        await model.refresh()
        #expect(model.dataFrozenAt == nil)

        await service.failSnapshots(true)
        await model.refresh()
        #expect(model.dataFrozenAt == model.lastRefreshedAt)

        await service.failSnapshots(false)
        await model.refresh()
        #expect(model.dataFrozenAt == nil)
    }

    @Test func refreshingIsVisibleWhileItRuns() async {
        let service = GatedService()
        let model = model(service)
        await model.refresh()
        await service.holdNextSnapshot()

        let refresh = Task { await model.refresh() }
        await service.waitUntilHolding()
        #expect(model.isRefreshing)
        await service.release()
        await refresh.value

        #expect(!model.isRefreshing)
    }
}

struct ConnectionStatusTests {
    private let now = Date(timeIntervalSinceReferenceDate: 10000)
    private let locale = Locale(identifier: "en_US")

    private func status(_ issue: ConnectionIssue, updated: TimeInterval? = nil) -> ConnectionStatus? {
        ConnectionStatus(
            ConnectionProblem(issue: issue, detail: "server text"), factory: "58lab", company: "Atlas",
            lastRefreshedAt: updated.map { now - $0 }, now: now, locale: locale
        )
    }

    @Test func noProblemNoStrip() {
        #expect(ConnectionStatus(nil, factory: "58lab", company: nil, lastRefreshedAt: nil) == nil)
    }

    @Test func offlineSaysWhenDataLastArrived() throws {
        let strip = try #require(status(.unreachable, updated: 180))
        #expect(strip.tone == .stale)
        #expect(strip.title == "Can't reach 58lab")
        #expect(strip.detail == "Updated 3 minutes ago")
        #expect(strip.action == .retry)
    }

    @Test(arguments: [
        (ConnectionIssue.signedOut, StatusStrip.Tone.blocking, "Signed out of 58lab", ConnectionStatus.Action?.some(.signIn)),
        (.noAccess, .blocking, "No access to Atlas", .retry),
        (.serverProblem(status: 502), .warning, "58lab had a problem (502)", .retry),
        (.serverProblem(status: nil), .warning, "58lab had a problem", .retry),
        (.unsupported, .warning, "This server's version isn't supported yet", nil),
    ])
    func eachIssueHasATitleAndAction(
        issue: ConnectionIssue, tone: StatusStrip.Tone, title: String, action: ConnectionStatus.Action?
    ) throws {
        let strip = try #require(status(issue))
        #expect(strip.tone == tone)
        #expect(strip.title == title)
        #expect(strip.action == action)
        #expect(strip.detail == nil)
    }

    @Test func signedOutWithoutABoardKeyOffersRetryInstead() throws {
        let strip = try #require(ConnectionStatus(
            ConnectionProblem(issue: .signedOut, detail: ""), factory: "58lab", company: nil,
            lastRefreshedAt: nil, canSignIn: false, now: now, locale: locale
        ))
        #expect(strip.action == .retry)
    }

    @Test func anExpiringKeyAsksToSignInAgain() {
        let strip = ConnectionStatus(keyExpiresAt: now + 2 * 86400, factory: "58lab", now: now, locale: locale)
        #expect(strip.tone == .stale)
        #expect(strip.title == "Fabrix's key for 58lab expires in 2 days")
        #expect(strip.action == .signIn)
    }
}
