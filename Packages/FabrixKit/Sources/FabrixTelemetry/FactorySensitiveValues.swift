import FabrixCore
import Observation
import Synchronization

/// Feeds the names and hosts of saved factories to the exporter and follows changes to the store.
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
        values.withLock { $0 = factories.flatMap { [$0.name, $0.baseURL.host()].compactMap(\.self) } }
    }
}
