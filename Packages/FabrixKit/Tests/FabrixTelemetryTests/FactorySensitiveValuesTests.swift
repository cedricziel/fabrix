import FabrixCore
@testable import FabrixTelemetry
import Foundation
import OpenTelemetrySdk
import Synchronization
import Testing

private final class MemoryCredentials: CredentialStore {
    private let values = Mutex<[Factory.ID: String]>([:])
    func credential(for factoryID: Factory.ID) throws -> String? { values.withLock { $0[factoryID] } }
    func setCredential(_ credential: String?, for factoryID: Factory.ID) throws { values.withLock { $0[factoryID] = credential } }
}

@MainActor
struct FactorySensitiveValuesTests {
    private let factory = Factory(id: "f1", name: "Night Shift", baseURL: URL(string: "https://paperclip.night.lan:3100")!, isOnline: true)
    private let anonymizer = Anonymizer(salt: Data(repeating: 9, count: 32))

    private func storeWithSavedFactory(headers: [String: String] = [:]) throws -> FactoryStore {
        let defaults = try #require(UserDefaults(suiteName: "FactorySensitiveValuesTests-\(UUID())"))
        let stored: [String: Any] = [
            "factory": ["id": factory.id, "name": factory.name, "baseURL": factory.baseURL.absoluteString, "isOnline": true],
            "auth": ["usesBoardKey": false],
            "headerNames": Array(headers.keys),
        ]
        defaults.set(try JSONSerialization.data(withJSONObject: [stored]), forKey: "fabrix.factories")
        let credentials = MemoryCredentials()
        if !headers.isEmpty {
            let values = String(decoding: try JSONSerialization.data(withJSONObject: headers), as: UTF8.self)
            try credentials.setCredential(values, for: "\(factory.id).headers")
        }
        let store = FactoryStore(defaults: defaults, credentials: credentials)
        try #require(store.factories == [factory])
        return store
    }

    @Test func savedFactoryNamesAndHostsAreHashedOnExport() throws {
        let capture = CapturingSpanExporter()
        let source = FactorySensitiveValues(store: try storeWithSavedFactory())
        let provider = TracerProviderBuilder()
            .add(spanProcessor: SimpleSpanProcessor(spanExporter: ScrubbingSpanExporter(anonymizer: anonymizer, sensitiveValues: source, wrapping: capture)))
            .build()
        provider.get(instrumentationName: "test").spanBuilder(spanName: "refresh")
            .setAttribute(key: "message", value: "Night Shift at paperclip.night.lan is offline")
            .startSpan().end()
        provider.forceFlush()

        let span = try #require(capture.spans.withLock { $0.first })
        #expect(span.attributes["message"] == .string("\(anonymizer.hash("Night Shift")) at \(anonymizer.hash("paperclip.night.lan")) is offline"))
    }

    @Test func removedFactoriesStopBeingListed() async throws {
        let store = try storeWithSavedFactory()
        let source = FactorySensitiveValues(store: store)
        #expect(Set(source.sensitiveValues()) == ["Night Shift", "paperclip.night.lan"])

        try store.remove(factory)
        for _ in 0 ..< 10 where !source.sensitiveValues().isEmpty {
            await Task.yield()
        }

        #expect(source.sensitiveValues().isEmpty)
    }

    @Test func savedHeaderValuesAreHashedOnExport() throws {
        let token = "tok_proxy_8f2c41d7"
        let store = try storeWithSavedFactory(headers: ["X-Proxy-Token": token])
        try #require(try store.customHeaders(for: factory) == [CustomHeader(name: "X-Proxy-Token", value: token)])
        let capture = CapturingSpanExporter()
        let provider = TracerProviderBuilder()
            .add(spanProcessor: SimpleSpanProcessor(spanExporter: ScrubbingSpanExporter(
                anonymizer: anonymizer, sensitiveValues: FactorySensitiveValues(store: store), wrapping: capture
            )))
            .build()
        let span = provider.get(instrumentationName: "test").spanBuilder(spanName: "request")
            .setAttribute(key: "http.request.header.x-proxy-token", value: token)
            .startSpan()
        span.status = .error(description: "Proxy rejected token \(token)")
        span.end()
        provider.forceFlush()

        let exported = try #require(capture.spans.withLock { $0.first })
        let hashed = anonymizer.hash(token)
        #expect(exported.attributes["http.request.header.x-proxy-token"] == .string(hashed))
        #expect(exported.status == .error(description: "Proxy rejected token \(hashed)"))
    }
}
