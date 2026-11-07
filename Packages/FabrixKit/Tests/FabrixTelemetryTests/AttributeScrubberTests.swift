@testable import FabrixTelemetry
import Foundation
import OpenTelemetryApi
import Testing

struct AttributeScrubberTests {
    private let anonymizer = Anonymizer(salt: Data(repeating: 7, count: 32))
    private var scrubber: AttributeScrubber {
        AttributeScrubber(anonymizer: anonymizer, sensitiveValues: ["Acme Factory", "paperclip.acme.lan"])
    }

    @Test func urlKeepsSchemeAndPathButHashesHostAndDropsTheRest() {
        let scrubbed = scrubber.scrub(url: "https://user:pw@Paperclip.acme.lan:3100/api/companies/c1?token=abc#frag")
        #expect(scrubbed == "https://\(anonymizer.hash("paperclip.acme.lan"))/api/companies/c1")
    }

    @Test(arguments: ["pcp_board_4f1c9a0e7b2d", "pcp_cli_auth_Zx8-_q2"])
    func paperclipTokensInTextAreHashed(token: String) {
        #expect(scrubber.scrub("Rejected \(token).") == "Rejected \(anonymizer.hash(token)).")
    }

    @Test func urlWithoutHostLosesItsQuery() {
        #expect(scrubber.scrub(url: "/api/issues?q=secret") == "/api/issues")
    }

    @Test func hostAttributesAreHashed() {
        let scrubbed = scrubber.scrub(attributes: [
            "net.peer.name": .string("10.0.0.5"),
            "server.address": .string("factory.example.com"),
            "http.host": .string("factory.example.com:3100"),
        ])
        #expect(scrubbed["net.peer.name"] == .string(anonymizer.hash("10.0.0.5")))
        #expect(scrubbed["server.address"] == .string(anonymizer.hash("factory.example.com")))
        #expect(scrubbed["http.host"] == .string(anonymizer.hash("factory.example.com")))
    }

    @Test func urlAttributesAreScrubbed() {
        let scrubbed = scrubber.scrub(attributes: [
            "http.url": .string("http://factory.example.com/api/agents?apiKey=x"),
            "url.full": .string("http://factory.example.com/api/agents?apiKey=x"),
            "http.target": .string("/api/agents?apiKey=x"),
            "url.query": .string("apiKey=x"),
        ])
        let hashed = "http://\(anonymizer.hash("factory.example.com"))/api/agents"
        #expect(scrubbed["http.url"] == .string(hashed))
        #expect(scrubbed["url.full"] == .string(hashed))
        #expect(scrubbed["http.target"] == .string("/api/agents"))
        #expect(scrubbed["url.query"] == nil)
    }

    @Test func sensitiveValuesAreReplacedInsideFreeText() {
        let text = "Lost connection to Acme Factory at paperclip.acme.lan"
        let expected = "Lost connection to \(anonymizer.hash("Acme Factory")) at \(anonymizer.hash("paperclip.acme.lan"))"
        #expect(scrubber.scrub(text) == expected)
    }

    @Test func sensitiveValuesMatchCaseInsensitively() {
        #expect(scrubber.scrub("ACME FACTORY is down") == "\(anonymizer.hash("Acme Factory")) is down")
    }

    @Test func urlsInsideFreeTextAreScrubbed() {
        let text = "Could not connect to http://192.168.1.20:3100/api/health?x=1."
        #expect(scrubber.scrub(text) == "Could not connect to http://\(anonymizer.hash("192.168.1.20"))/api/health.")
    }

    @Test func nonStringValuesAreLeftAlone() {
        let attributes: [String: AttributeValue] = ["http.status_code": .int(200), "ok": .bool(true)]
        #expect(scrubber.scrub(attributes: attributes) == attributes)
    }

    @Test func stringArraysAreScrubbedElementwise() {
        let scrubbed = scrubber.scrub(.array(AttributeArray(values: [.string("Acme Factory"), .int(1)])))
        #expect(scrubbed == .array(AttributeArray(values: [.string(anonymizer.hash("Acme Factory")), .int(1)])))
    }

    @Test func blankSensitiveValuesAreIgnored() {
        let scrubber = AttributeScrubber(anonymizer: anonymizer, sensitiveValues: ["", "  "])
        #expect(scrubber.scrub("nothing to hide") == "nothing to hide")
    }

    @Test func urlsWithUppercaseSchemesAreScrubbed() {
        let text = "Request to HTTPS://Factory.example.com/api?token=abc failed"
        #expect(scrubber.scrub(text) == "Request to HTTPS://\(anonymizer.hash("factory.example.com"))/api failed")
    }

    @Test func webSocketURLsAreScrubbed() {
        let text = "Stream closed: wss://factory.example.com:3100/api/events?token=abc"
        #expect(scrubber.scrub(text) == "Stream closed: wss://\(anonymizer.hash("factory.example.com"))/api/events")
    }

    @Test func bareFactoryHostsInErrorTextAreHashed() {
        let text = "The certificate is invalid; you might be connecting to a server pretending to be \"paperclip.acme.lan\"."
        #expect(!scrubber.scrub(text).contains("paperclip.acme.lan"))
        #expect(scrubber.scrub(text).contains(anonymizer.hash("paperclip.acme.lan")))
    }

    @Test func identifiersInPathsBecomeTemplates() {
        let scrubbed = scrubber.scrub(attributes: [
            "url.path": .string("/api/companies/0b6c4a8e-2f43-4c47-9a3e-6d1f5c2b7e91/agents/1234"),
            "url.full": .string("https://factory.example.com/api/issues/01HZX3K8Q9V2M7R4T6Y1B5N0CD/comments"),
        ])
        #expect(scrubbed["url.path"] == .string("/api/companies/{id}/agents/{id}"))
        #expect(scrubbed["url.full"] == .string("https://\(anonymizer.hash("factory.example.com"))/api/issues/{id}/comments"))
    }

    @Test func paperclipRequestsGetTheirRouteTemplate() {
        let scrubbed = scrubber.scrub(attributes: [
            "server.address": .string("Paperclip.acme.lan"),
            "url.path": .string("/api/companies/0b6c4a8e-2f43-4c47-9a3e-6d1f5c2b7e91/agents"),
        ])
        #expect(scrubbed[PaperclipAttribute.apiRoute.rawValue] == .string("/api/companies/{id}/agents"))
    }

    @Test func otherHostsGetNoRoute() {
        let scrubbed = scrubber.scrub(attributes: [
            "server.address": .string("api.example.com"),
            "url.path": .string("/api/v1/things"),
        ])
        #expect(scrubbed[PaperclipAttribute.apiRoute.rawValue] == nil)
    }

    @Test func unparseableURLsStillLoseTheirHost() {
        let scrubbed = scrubber.scrub(url: "https://bad host.acme.lan:3100/api/x?token=abc")
        #expect(scrubbed == "https://\(anonymizer.hash("bad host.acme.lan"))/api/x")
    }

    @Test func onlyTheConnectionTypeSurvivesFromNetworkStatus() {
        let scrubbed = scrubber.scrub(attributes: [
            "network.connection.type": .string("cell"),
            "network.connection.subtype": .string("LTE"),
            "network.carrier.name": .string("Telekom"),
            "network.carrier.icc": .string("de"),
            "network.carrier.mcc": .string("262"),
            "network.carrier.mnc": .string("01"),
        ])
        #expect(scrubbed == ["network.connection.type": .string("cell")])
    }

    @Test func unbracketedIPv6AddressesKeepTheirWholeAddress() {
        let scrubber = AttributeScrubber(anonymizer: anonymizer, sensitiveValues: ["fe80::1"])
        let scrubbed = scrubber.scrub(attributes: [
            "server.address": .string("fe80::1"),
            "url.full": .string("http://[fe80::1]:3100/api/companies/1234/agents"),
            "url.path": .string("/api/companies/1234/agents"),
        ])
        let hashed = anonymizer.hash("fe80::1")
        #expect(scrubbed["server.address"] == .string(hashed))
        #expect(scrubbed["url.full"] == .string("http://\(hashed)/api/companies/{id}/agents"))
        #expect(scrubbed[PaperclipAttribute.apiRoute.rawValue] == .string("/api/companies/{id}/agents"))
    }

    @Test func ipv6HostsHashTheSameEverywhere() {
        let scrubbed = scrubber.scrub(attributes: [
            "server.address": .string("[fe80::1]"),
            "url.full": .string("http://[fe80::1]:3100/api/health"),
        ])
        let hashed = anonymizer.hash("fe80::1")
        #expect(scrubbed["server.address"] == .string(hashed))
        #expect(scrubbed["url.full"] == .string("http://\(hashed)/api/health"))
    }

    @Test func nonAPIPathsGetNoRoute() {
        let scrubbed = scrubber.scrub(attributes: ["server.address": .string("paperclip.acme.lan"), "url.path": .string("/health")])
        #expect(scrubbed[PaperclipAttribute.apiRoute.rawValue] == nil)
    }

    @Test func factoryIDIsAlwaysHashed() {
        let scrubbed = scrubber.scrub(attributes: [PaperclipAttribute.factoryID.rawValue: .string("paperclip.acme.lan")])
        #expect(scrubbed[PaperclipAttribute.factoryID.rawValue] == .string(anonymizer.hash("paperclip.acme.lan")))
    }
}
