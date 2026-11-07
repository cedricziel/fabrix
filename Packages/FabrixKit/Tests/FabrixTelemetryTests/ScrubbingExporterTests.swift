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
    private var scrubber: AttributeScrubber {
        AttributeScrubber(anonymizer: anonymizer, sensitiveValues: ["Acme Factory"])
    }

    @Test func spansLeaveWithScrubbedNameAttributesEventsAndResource() throws {
        let capture = CapturingSpanExporter()
        let provider = TracerProviderBuilder()
            .with(resource: Resource(attributes: ["factory.label": .string("Acme Factory")]))
            .add(spanProcessor: SimpleSpanProcessor(spanExporter: ScrubbingSpanExporter(scrubber: scrubber, wrapping: capture)))
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
            .with(processors: [SimpleLogRecordProcessor(logRecordExporter: ScrubbingLogExporter(scrubber: scrubber, wrapping: capture))])
            .build()
        provider.get(instrumentationScopeName: "test").logRecordBuilder()
            .setBody(.string("Refreshed Acme Factory"))
            .setAttributes(["url.full": .string("http://acme.lan/x?y=1")])
            .emit()

        let record = try #require(capture.records.withLock { $0.first })
        #expect(record.body == .string("Refreshed \(anonymizer.hash("Acme Factory"))"))
        #expect(record.attributes["url.full"] == .string("http://\(anonymizer.hash("acme.lan"))/x"))
    }
}
