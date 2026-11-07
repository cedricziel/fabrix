@testable import FabrixTelemetry
import Foundation
import OpenTelemetryApi
import Testing

struct AttributeScrubberTests {
    private let anonymizer = Anonymizer(salt: Data(repeating: 7, count: 32))
    private var scrubber: AttributeScrubber {
        AttributeScrubber(anonymizer: anonymizer, sensitive: ["Acme Factory", "paperclip.acme.lan"])
    }

    @Test func urlKeepsSchemeAndPathButHashesHostAndDropsTheRest() {
        let scrubbed = scrubber.scrub(url: "https://user:pw@Paperclip.acme.lan:3100/api/companies/c1?token=abc#frag")
        #expect(scrubbed == "https://\(anonymizer.hash("paperclip.acme.lan"))/api/companies/c1")
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

    @Test func registryAddsValuesAtRuntime() {
        let registry = SensitiveValues()
        let scrubber = AttributeScrubber(anonymizer: anonymizer, registry: registry)
        #expect(scrubber.scrub("Night Shift") == "Night Shift")
        registry.insert(["Night Shift"])
        #expect(scrubber.scrub("Night Shift") == anonymizer.hash("Night Shift"))
    }

    @Test func blankValuesAreNotRegistered() {
        let registry = SensitiveValues()
        registry.insert(["", "  "])
        #expect(registry.values.isEmpty)
    }
}
