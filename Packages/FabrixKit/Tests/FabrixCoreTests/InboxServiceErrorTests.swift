@testable import FabrixCore
import Foundation
import Testing

struct InboxServiceErrorTests {
    private let companyID = PaperclipFixtures.companyID

    private func service(path: String, response: StubURLProtocol.Response) -> PaperclipFactoryService {
        let server = FakeServer(routes: ["GET \(path)": response])
        return PaperclipFactoryService(client: PaperclipClient(baseURL: server.baseURL, credential: "k", session: server.session))
    }

    private func checkAttention(_ response: StubURLProtocol.Response, expected: any Error) async {
        let service = service(path: "/api/companies/\(companyID)/attention", response: response)
        do {
            _ = try await service.attention(companyID: companyID, view: .company, cursor: nil)
            #expect(Bool(false))
        } catch {
            #expect((error as? FactoryServiceError) == (expected as? FactoryServiceError))
            if case .decoding = expected as? PaperclipError {
                if case .decoding = error as? PaperclipError {} else { Issue.record("Expected a decoding error, got \(error)") }
            } else {
                #expect((error as? PaperclipError) == (expected as? PaperclipError))
            }
        }
    }

    private func checkPeople(_ response: StubURLProtocol.Response, expected: any Error) async {
        let service = service(path: "/api/companies/\(companyID)/user-directory", response: response)
        do {
            _ = try await service.people(companyID: companyID)
            #expect(Bool(false))
        } catch {
            #expect((error as? FactoryServiceError) == (expected as? FactoryServiceError))
            if case .decoding = expected as? PaperclipError {
                if case .decoding = error as? PaperclipError {} else { Issue.record("Expected a decoding error, got \(error)") }
            } else {
                #expect((error as? PaperclipError) == (expected as? PaperclipError))
            }
        }
    }

    @Test func attentionAndPeopleMapNotFoundBodiesPrecisely() async {
        for response in [StubURLProtocol.Response(status: 404, body: Data()), .json(#"{"error":"API route not found"}"#, status: 404)] {
            await checkAttention(response, expected: FactoryServiceError.unsupported)
            await checkPeople(response, expected: FactoryServiceError.unsupported)
        }
        let companyMissing = StubURLProtocol.Response.json(#"{"error":"Company not found"}"#, status: 404)
        await checkAttention(companyMissing, expected: PaperclipError.notFound("Company not found"))
        await checkPeople(companyMissing, expected: PaperclipError.notFound("Company not found"))
    }

    @Test func attentionAndPeoplePreserveUnauthorizedAndServerErrors() async {
        for (response, expected) in [
            (StubURLProtocol.Response.json(#"{"error":"bad token"}"#, status: 401), PaperclipError.unauthorized("bad token")),
            (StubURLProtocol.Response.json(#"{"error":"broken"}"#, status: 500), PaperclipError.server(status: 500, message: "broken")),
        ] {
            await checkAttention(response, expected: expected)
            await checkPeople(response, expected: expected)
        }
    }

    @Test func malformedSuccessfulResponsesAreDecodingErrors() async {
        let malformed = StubURLProtocol.Response.json("not json")
        await checkAttention(malformed, expected: PaperclipError.decoding(""))
        await checkPeople(malformed, expected: PaperclipError.decoding(""))
    }

    @Test func attentionForbiddenOnlyMapsBoardUserContextRequirement() async {
        await checkAttention(.json(#"{"error":"Board user context required"}"#, status: 403), expected: FactoryServiceError.unsupported)
        await checkAttention(.json(#"{"error":"Forbidden"}"#, status: 403), expected: PaperclipError.forbidden("Forbidden"))
    }

    @Test func peopleMapsAnyForbiddenToUnsupported() async {
        await checkPeople(.json(#"{"error":"Forbidden"}"#, status: 403), expected: FactoryServiceError.unsupported)
    }
}
