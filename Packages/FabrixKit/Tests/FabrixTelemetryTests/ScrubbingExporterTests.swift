@testable import FabrixTelemetry
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import Synchronization
import Testing

private final class CapturingSpanExporter: SpanExporter {
    let spans = Mutex<[SpanData]>([])
    func export(spans: [SpanData], explicitTimeout _: TimeInterval?) -> SpanExporterResultCode {
        self.spans.withLock { $0 += spans }
        return .success
    }

    func flush(explicitTimeout _: TimeInterval?) -> SpanExporterResultCode {
        .success
    }

    func shutdown(explicitTimeout _: TimeInterval?) {}
}

private final class CapturingLogExporter: LogRecordExporter {
    let records = Mutex<[ReadableLogRecord]>([])
    func export(logRecords: [ReadableLogRecord], explicitTimeout _: TimeInterval?) -> ExportResult {
        records.withLock { $0 += logRecords }
        return .success
    }

    func shutdown(explicitTimeout _: TimeInterval?) {}
    func forceFlush(explicitTimeout _: TimeInterval?) -> ExportResult {
        .success
    }
}

struct ScrubbingExporterTests {
    private let anonymizer = Anonymizer(salt: Data(repeating: 3, count: 32))
    private let source = StubSensitiveValues(["Acme Factory"])

    @Test func spansLeaveWithScrubbedNameAttributesEventsAndResource() throws {
        let capture = CapturingSpanExporter()
        let provider = TracerProviderBuilder()
            .with(resource: Resource(attributes: ["factory.label": .string("Acme Factory")]))
            .add(spanProcessor: SimpleSpanProcessor(spanExporter: ScrubbingSpanExporter(anonymizer: anonymizer, sensitiveValues: source, wrapping: capture)))
            .build()
        let span = provider.get(instrumentationName: "test")
            .spanBuilder(spanName: "GET Acme Factory")
            .setAttribute(key: "http.url", value: "https://acme.lan/api/agents?key=1")
            .startSpan()
        span.addEvent(name: "retry", attributes: ["reason": .string("Acme Factory timed out")])
        span.end()
        provider.forceFlush()

        let exported = try #require(capture.spans.withLock { $0.first })
        let hashedName = anonymizer.hash("Acme Factory")
        #expect(exported.name == "GET \(hashedName)")
        #expect(exported.attributes["http.url"] == .string("https://\(anonymizer.hash("acme.lan"))/api/agents"))
        #expect(exported.events.first?.attributes["reason"] == .string("\(hashedName) timed out"))
        #expect(exported.resource.attributes["factory.label"] == .string(hashedName))
    }

    @Test func logRecordsLeaveWithScrubbedBodyAndAttributes() throws {
        let capture = CapturingLogExporter()
        let provider = LoggerProviderBuilder()
            .with(processors: [SimpleLogRecordProcessor(logRecordExporter: ScrubbingLogExporter(anonymizer: anonymizer, sensitiveValues: source, wrapping: capture))])
            .build()
        provider.get(instrumentationScopeName: "test").logRecordBuilder()
            .setBody(.string("Refreshed Acme Factory"))
            .setAttributes(["url.full": .string("http://acme.lan/x?y=1")])
            .emit()

        let record = try #require(capture.records.withLock { $0.first })
        #expect(record.body == .string("Refreshed \(anonymizer.hash("Acme Factory"))"))
        #expect(record.attributes["url.full"] == .string("http://\(anonymizer.hash("acme.lan"))/x"))
    }

    @Test func sensitiveValuesAreReadFromTheSourceAtExportTime() throws {
        let capture = CapturingLogExporter()
        let provider = LoggerProviderBuilder()
            .with(processors: [SimpleLogRecordProcessor(logRecordExporter: ScrubbingLogExporter(anonymizer: anonymizer, sensitiveValues: source, wrapping: capture))])
            .build()
        source.current.withLock { $0.append("Night Shift") }
        provider.get(instrumentationScopeName: "test").logRecordBuilder().setBody(.string("Connected to Night Shift")).emit()

        let record = try #require(capture.records.withLock { $0.first })
        #expect(record.body == .string("Connected to \(anonymizer.hash("Night Shift"))"))
    }

    @Test func metricPointsLeaveWithoutAttributes() {
        let capture = CapturingMetricExporter()
        let provider = Runtime.makeMeterProvider(exporter: ScrubbingMetricExporter(wrapping: capture), resource: Resource())
        provider.get(name: "test").counterBuilder(name: "fabrix.test.count").build()
            .add(value: 1, attributes: ["server.address": .string("paperclip.acme.lan")])
        _ = provider.forceFlush()

        let points = capture.metrics.withLock { $0 }.flatMap(\.data.points)
        #expect(!points.isEmpty)
        #expect(points.allSatisfy { $0.attributes.isEmpty })
    }
}
