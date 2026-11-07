@testable import FabrixTelemetry
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import Synchronization
import Testing

struct TelemetryTests {
    @Test func startIsANoOpWithoutConfiguration() {
        #expect(Telemetry.start(infoDictionary: [:]) == false)
        #expect(Telemetry.isRunning == false)
    }

    @Test func resourceDescribesTheAppWithoutIdentifyingTheMachine() {
        let info: [String: Any] = ["CFBundleShortVersionString": "1.2.3", "CFBundleVersion": "42"]
        let attributes = Telemetry.resourceAttributes(infoDictionary: info, installationID: UUID().uuidString)

        #expect(attributes["service.name"] == .string("fabrix"))
        #expect(attributes["service.version"] == .string("1.2.3"))
        #expect(attributes["app.build"] == .string("42"))
        #expect(attributes["host.name"] == nil)
        #expect(attributes["device.id"] == nil)
        #expect(attributes["os.version"] != nil)
    }
}

final class CapturingMetricExporter: MetricExporter {
    let metrics = Mutex<[MetricData]>([])
    func export(metrics: [MetricData]) -> ExportResult {
        self.metrics.withLock { $0 += metrics }
        return .success
    }
    func flush() -> ExportResult { .success }
    func shutdown() -> ExportResult { .success }
    func getAggregationTemporality(for instrument: InstrumentType) -> AggregationTemporality { .cumulative }
}

struct MeterProviderTests {
    @Test func countersReachTheExporter() {
        let exporter = CapturingMetricExporter()
        let provider = Runtime.makeMeterProvider(exporter: exporter, resource: Resource())
        provider.get(name: "test").counterBuilder(name: "fabrix.test.count").build().add(value: 1)
        _ = provider.forceFlush()
        #expect(exporter.metrics.withLock { $0.map(\.name) } == ["fabrix.test.count"])
    }
}
