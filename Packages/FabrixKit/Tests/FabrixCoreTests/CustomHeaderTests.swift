@testable import FabrixCore
import Foundation
import Testing

struct CustomHeaderTests {
    private let oidc = FactoryAuthConfiguration(
        oidc: OIDCSettings(issuer: URL(string: "https://idp.test")!, clientID: "fabrix", redirectURI: URL(string: "com.cedricziel.fabrix:/cb")!, tokenHeader: "X-Forwarded-Access-Token")
    )

    @Test func trimsNamesAndValues() throws {
        let headers = try CustomHeader.validated([CustomHeader(name: " X-Proxy-Token ", value: " secret ")], for: .boardKey)
        #expect(headers == [CustomHeader(name: "X-Proxy-Token", value: "secret")])
    }

    @Test(arguments: ["", "  ", "X Proxy", "X-Proxy:", "Prox\u{e9}", "X-Token\nInjected"])
    func rejectsInvalidNames(name: String) {
        #expect(throws: PaperclipError.self) { try CustomHeader.validated([CustomHeader(name: name, value: "v")], for: .none) }
    }

    @Test(arguments: ["Host", "content-length", "Transfer-Encoding", "CONNECTION"])
    func rejectsReservedNames(name: String) {
        #expect(throws: PaperclipError.self) { try CustomHeader.validated([CustomHeader(name: name, value: "v")], for: .none) }
    }

    @Test func rejectsLineBreaksInValues() {
        #expect(throws: PaperclipError.self) {
            try CustomHeader.validated([CustomHeader(name: "X-Token", value: "a\r\nX-Evil: 1")], for: .none)
        }
    }

    @Test func rejectsDuplicateNamesIgnoringCase() {
        #expect(throws: PaperclipError.self) {
            try CustomHeader.validated([CustomHeader(name: "X-Token", value: "a"), CustomHeader(name: "x-token", value: "b")], for: .none)
        }
    }

    @Test func rejectsAuthorizationOnlyWhenTheBoardKeyUsesIt() throws {
        let authorization = [CustomHeader(name: "authorization", value: "Basic abc")]
        #expect(throws: PaperclipError.self) { try CustomHeader.validated(authorization, for: .boardKey) }
        #expect(try CustomHeader.validated(authorization, for: .none) == authorization)
    }

    @Test func rejectsTheOIDCTokenHeader() {
        #expect(throws: PaperclipError.self) {
            try CustomHeader.validated([CustomHeader(name: "x-forwarded-access-token", value: "v")], for: oidc)
        }
    }

    @Test func errorNamesTheHeader() {
        #expect(throws: PaperclipError.invalidAuthConfiguration("Host is set by the system and can't be a custom header.")) {
            try CustomHeader.validated([CustomHeader(name: "Host", value: "v")], for: .none)
        }
    }
}
