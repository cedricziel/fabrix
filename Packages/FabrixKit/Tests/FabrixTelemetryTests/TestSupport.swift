@testable import FabrixTelemetry
import Synchronization

final class StubSensitiveValues: SensitiveValueSource {
    let current: Mutex<[String]>

    init(_ values: [String] = []) {
        current = Mutex(values)
    }

    func sensitiveValues() -> [String] {
        current.withLock { $0 }
    }
}
