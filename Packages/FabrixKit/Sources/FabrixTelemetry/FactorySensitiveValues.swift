import FabrixCore
import Observation
import Synchronization

/// Feeds the names, hosts and custom header values of saved factories to the exporter and follows changes to the store.
@MainActor
public final class FactorySensitiveValues: SensitiveValueSource {
    private let store: FactoryStore
    private nonisolated let values = Mutex<[String]>([])

    public init(store: FactoryStore) {
        self.store = store
        track()
    }

    public nonisolated func sensitiveValues() -> [String] {
        values.withLock { $0 }
    }

    private func track() {
        let factories = withObservationTracking { store.factories } onChange: { [weak self] in
            Task { @MainActor in self?.track() }
        }
        let listed = factories.flatMap { factory in
            [factory.name, factory.baseURL.host()].compactMap(\.self)
                + ((try? store.customHeaders(for: factory)) ?? []).map(\.value)
        }
        values.withLock { $0 = listed }
    }
}
