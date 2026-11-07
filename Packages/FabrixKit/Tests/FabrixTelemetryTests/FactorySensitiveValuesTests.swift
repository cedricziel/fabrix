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

    private func storeWithSavedFactory() throws -> FactoryStore {
        let defaults = try #require(UserDefaults(suiteName: "FactorySensitiveValuesTests-\(UUID())"))
        let stored: [String: Any] = [
            "factory": ["id": factory.id, "name": factory.name, "baseURL": factory.baseURL.absoluteString, "isOnline": true],
            "auth": ["usesBoardKey": false],
        ]
        defaults.set(try JSONSerialization.data(withJSONObject: [stored]), forKey: "fabrix.factories")
        let store = FactoryStore(defaults: defaults, credentials: MemoryCredentials())
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
}
