import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

final class ScrubbingSpanExporter: SpanExporter {
    private let anonymizer: Anonymizer
    private let source: any SensitiveValueSource
    private let next: SpanExporter

    init(anonymizer: Anonymizer, sensitiveValues source: any SensitiveValueSource, wrapping next: SpanExporter) {
        self.anonymizer = anonymizer
        self.source = source
        self.next = next
    }

    func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        let scrubber = AttributeScrubber(anonymizer: anonymizer, sensitiveValues: source.sensitiveValues())
        return next.export(spans: spans.map { scrub($0, with: scrubber) }, explicitTimeout: explicitTimeout)
    }

    func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        next.flush(explicitTimeout: explicitTimeout)
    }

    func shutdown(explicitTimeout: TimeInterval?) {
        next.shutdown(explicitTimeout: explicitTimeout)
    }

    private func scrub(_ span: SpanData, with scrubber: AttributeScrubber) -> SpanData {
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
    private let anonymizer: Anonymizer
    private let source: any SensitiveValueSource
    private let next: LogRecordExporter

    init(anonymizer: Anonymizer, sensitiveValues source: any SensitiveValueSource, wrapping next: LogRecordExporter) {
        self.anonymizer = anonymizer
        self.source = source
        self.next = next
    }

    func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) -> ExportResult {
        let scrubber = AttributeScrubber(anonymizer: anonymizer, sensitiveValues: source.sensitiveValues())
        return next.export(logRecords: logRecords.map { scrub($0, with: scrubber) }, explicitTimeout: explicitTimeout)
    }

    func shutdown(explicitTimeout: TimeInterval?) {
        next.shutdown(explicitTimeout: explicitTimeout)
    }

    func forceFlush(explicitTimeout: TimeInterval?) -> ExportResult {
        next.forceFlush(explicitTimeout: explicitTimeout)
    }

    private func scrub(_ record: ReadableLogRecord, with scrubber: AttributeScrubber) -> ReadableLogRecord {
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

/// Fabrix metrics carry no attributes by design; stripping them keeps it that way.
final class ScrubbingMetricExporter: MetricExporter {
    private let next: MetricExporter

    init(wrapping next: MetricExporter) {
        self.next = next
    }

    func export(metrics: [MetricData]) -> ExportResult {
        for point in metrics.flatMap(\.data.points) {
            point.attributes = [:]
        }
        return next.export(metrics: metrics)
    }

    func flush() -> ExportResult {
        next.flush()
    }

    func shutdown() -> ExportResult {
        next.shutdown()
    }

    func getAggregationTemporality(for instrument: InstrumentType) -> AggregationTemporality {
        next.getAggregationTemporality(for: instrument)
    }
}
