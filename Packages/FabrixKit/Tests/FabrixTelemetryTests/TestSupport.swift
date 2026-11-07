@testable import FabrixTelemetry

extension AttributeScrubber {
    init(anonymizer: Anonymizer, sensitive values: [String]) {
        let registry = SensitiveValues()
        registry.insert(values)
        self.init(anonymizer: anonymizer, registry: registry)
    }
}
