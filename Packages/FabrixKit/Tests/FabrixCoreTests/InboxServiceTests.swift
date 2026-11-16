@testable import FabrixCore
import Foundation
import Testing

struct InboxServiceTests {
    private let companyID = "c1"
    private let attentionPath = "/api/companies/c1/attention"

    private func service(_ routes: [String: StubURLProtocol.Response], recorder: RequestRecorder) -> PaperclipFactoryService {
        let server = FakeServer(routes: routes, recorder: recorder)
        return PaperclipFactoryService(client: PaperclipClient(baseURL: server.baseURL, credential: "k", session: server.session))
    }

    @Test(arguments: AttentionView.allCases)
    func attentionRequestsEachViewAndMapsRoutedFeed(view: AttentionView) async throws {
        let recorder = RequestRecorder()
        let feed = try await service(["GET \(attentionPath)": .json(AttentionFixtures.routedMine)], recorder: recorder)
            .attention(companyID: companyID, view: view, cursor: nil)

        let request = try #require(recorder.last("GET", attentionPath))
        let url = try #require(request.url)
        let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = try #require(query.queryItems)
        #expect(request.httpMethod == "GET")
        #expect(items.first { $0.name == "view" }?.value == view.rawValue)
        #expect(items.first { $0.name == "limit" }?.value == "100")
        #expect(items.first { $0.name == "cursor" } == nil)
        #expect(feed.items.count == 8)
        #expect(feed.deskBadgeCount == 8)
        #expect(feed.supportsRouting)
    }

    @Test func attentionPreservesOpaqueCursorAndMapsLegacyFeed() async throws {
        let cursor = "a+b/&?= ü%2B"
        let recorder = RequestRecorder()
        let feed = try await service(["GET \(attentionPath)": .json(AttentionFixtures.legacyMine)], recorder: recorder)
            .attention(companyID: companyID, view: .mine, cursor: cursor)

        let request = try #require(recorder.last("GET", attentionPath))
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = try #require(components.queryItems)
        #expect(items.first { $0.name == "cursor" }?.value == cursor)
        #expect(components.percentEncodedQuery?.contains("%2B") == true)
        #expect(components.percentEncodedQuery?.contains("+") == false)
        #expect(items.count == 3)
        #expect(feed.supportsRouting == false)
        #expect(feed.items.allSatisfy { $0.closeModes.isEmpty && !$0.canClaim && !$0.canTransfer })
    }

    @Test func peopleRequestsDirectoryAndMapsPeople() async throws {
        let path = "/api/companies/c1/user-directory"
        let recorder = RequestRecorder()
        let people = try await service(["GET \(path)": .json(AttentionFixtures.routedDirectory)], recorder: recorder)
            .people(companyID: companyID)

        #expect(recorder.last("GET", path)?.httpMethod == "GET")
        #expect(people.count == 2)
    }
}
