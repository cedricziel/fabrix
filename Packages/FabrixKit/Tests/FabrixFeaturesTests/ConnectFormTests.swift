import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

struct ConnectFormTests {
    @Test(arguments: [
        ("https://factory.example.com", "https://factory.example.com"),
        ("  factory.local:3100 ", "https://factory.local:3100"),
        ("http://192.168.1.4:3100/", "http://192.168.1.4:3100/"),
    ])
    func normalizesAddresses(input: String, expected: String) {
        #expect(ConnectForm.url(from: input)?.absoluteString == expected)
    }

    @Test(arguments: ["", "   ", "ftp://factory", "https://"])
    func rejectsUnusableAddresses(input: String) {
        #expect(ConnectForm.url(from: input) == nil)
    }

    @Test func paperclipKeyAuth() throws {
        let form = ConnectForm(address: "f.example", method: .paperclip, apiKey: " key ")
        let request = try form.validated()
        #expect(request.baseURL.absoluteString == "https://f.example")
        #expect(request.auth == .paperclip(apiKey: "key"))
    }

    @Test func oidcAuthIgnoresTheKey() throws {
        let form = ConnectForm(address: "f.example", method: .oidc, apiKey: "unused", issuer: "auth.example", clientID: "fabrix")
        #expect(try form.validated().auth == .oidc(issuer: URL(string: "https://auth.example")!, clientID: "fabrix"))
    }

    @Test func oidcInFrontOfPaperclipNeedsBoth() throws {
        let form = ConnectForm(address: "f.example", method: .oidcWithPaperclip, apiKey: "k", issuer: "https://auth.example", clientID: "c")
        #expect(try form.validated().auth == .oidcWithPaperclip(issuer: URL(string: "https://auth.example")!, clientID: "c", apiKey: "k"))
    }

    @Test func browserSignInIsTheDefault() throws {
        let form = ConnectForm(address: "f.example")
        #expect(form.method == .browser)
        #expect(try form.validated().auth == .browser)
    }

    @Test func oidcWithBrowserNeedsNoKey() throws {
        let form = ConnectForm(address: "f.example", method: .oidcWithBrowser, issuer: "auth.example", clientID: "c")
        #expect(try form.validated().auth == .oidcWithBrowser(issuer: URL(string: "https://auth.example")!, clientID: "c"))
    }

    @Test func blankHeaderRowsAreDropped() throws {
        var form = ConnectForm(address: "f.example", method: .paperclip, apiKey: "k")
        form.headers = [
            ConnectForm.HeaderRow(name: "X-Proxy-Token", value: "secret"),
            ConnectForm.HeaderRow(name: "  ", value: ""),
            ConnectForm.HeaderRow(),
        ]

        #expect(try form.validated().headers == [CustomHeader(name: "X-Proxy-Token", value: "secret")])
    }

    @Test func rowsWithOnlyAValueAreKeptForCoreToReject() throws {
        var form = ConnectForm(address: "f.example", method: .paperclip, apiKey: "k")
        form.headers = [ConnectForm.HeaderRow(name: "", value: "orphan")]

        #expect(try form.validated().headers == [CustomHeader(name: "", value: "orphan")])
    }

    @Test(arguments: [
        (ConnectForm(address: "nope://x", method: .paperclip, apiKey: "k"), ConnectForm.Problem.address),
        (ConnectForm(address: "f.example", method: .paperclip), .apiKey),
        (ConnectForm(address: "f.example", method: .oidc, clientID: "c"), .issuer),
        (ConnectForm(address: "f.example", method: .oidc, issuer: "auth.example"), .clientID),
        (ConnectForm(address: "f.example", method: .oidcWithPaperclip, issuer: "auth.example", clientID: "c"), .apiKey),
    ])
    func reportsTheFirstMissingField(form: ConnectForm, problem: ConnectForm.Problem) {
        #expect(throws: problem) { try form.validated() }
    }
}
