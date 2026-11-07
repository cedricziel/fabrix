/// Supplies the factory names and hosts the app knows about, so the exporter can replace them
/// wherever they appear. The app shell adapts its factory store to this; FabrixCore never sees telemetry.
public protocol SensitiveValueSource: Sendable {
    func sensitiveValues() -> [String]
}

struct NoSensitiveValues: SensitiveValueSource {
    func sensitiveValues() -> [String] { [] }
}
