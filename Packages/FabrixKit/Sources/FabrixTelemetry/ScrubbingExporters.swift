import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

final class ScrubbingSpanExporter: SpanExporter {
    private let scrubber: AttributeScrubber
    private let next: SpanExporter

    init(scrubber: AttributeScrubber, wrapping next: SpanExporter) {
        self.scrubber = scrubber
        self.next = next
    }

    func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        next.export(spans: spans.map(scrub), explicitTimeout: explicitTimeout)
    }

    func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        next.flush(explicitTimeout: explicitTimeout)
    }

    func shutdown(explicitTimeout: TimeInterval?) {
        next.shutdown(explicitTimeout: explicitTimeout)
    }

    private func scrub(_ span: SpanData) -> SpanData {
        var span = span
        let events = span.events.map {
            SpanData.Event(name: scrubber.scrub($0.name), timestamp: $0.timestamp, attributes: scrubber.scrub(attributes: $0.attributes))
        }
        let links = span.links.map { SpanData.Link(context: $0.context, attributes: scrubber.scrub(attributes: $0.attributes)) }
        var status = span.status
        if case let .error(description) = status {
            status = .error(description: scrubber.scrub(description))
        }
        span.settingName(scrubber.scrub(span.name))
        span.settingAttributes(scrubber.scrub(attributes: span.attributes))
        span.settingEvents(events)
        span.settingLinks(links)
        span.settingStatus(status)
        span.settingResource(Resource(attributes: scrubber.scrub(attributes: span.resource.attributes)))
        return span
    }
}

final class ScrubbingLogExporter: LogRecordExporter {
    private let scrubber: AttributeScrubber
    private let next: LogRecordExporter

    init(scrubber: AttributeScrubber, wrapping next: LogRecordExporter) {
        self.scrubber = scrubber
        self.next = next
    }

    func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) -> ExportResult {
        next.export(logRecords: logRecords.map(scrub), explicitTimeout: explicitTimeout)
    }

    func shutdown(explicitTimeout: TimeInterval?) {
        next.shutdown(explicitTimeout: explicitTimeout)
    }

    func forceFlush(explicitTimeout: TimeInterval?) -> ExportResult {
        next.forceFlush(explicitTimeout: explicitTimeout)
    }

    private func scrub(_ record: ReadableLogRecord) -> ReadableLogRecord {
        ReadableLogRecord(
            resource: Resource(attributes: scrubber.scrub(attributes: record.resource.attributes)),
            instrumentationScopeInfo: record.instrumentationScopeInfo,
            timestamp: record.timestamp,
            observedTimestamp: record.observedTimestamp,
            spanContext: record.spanContext,
            severity: record.severity,
            body: record.body.map(scrubber.scrub),
            attributes: scrubber.scrub(attributes: record.attributes),
            eventName: record.eventName
        )
    }
}
