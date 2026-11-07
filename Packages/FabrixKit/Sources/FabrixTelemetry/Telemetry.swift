import Foundation
import OpenTelemetryApi
import OpenTelemetryProtocolExporterCommon
import OpenTelemetryProtocolExporterHttp
import OpenTelemetrySdk
import Synchronization
import URLSessionInstrumentation

/// Entry point for the app shells: call `start()` once at launch and `flush()` when the app goes to the background.
public enum Telemetry {
    private static let runtime = Mutex<Runtime?>(nil)
    private static let sensitiveValues = SensitiveValues()

    public static var isRunning: Bool {
        runtime.withLock { $0 != nil }
    }

    /// Starts exporting to SignalDB if the build carries an ingest key; otherwise does nothing.
    @discardableResult
    public static func start(bundle: Bundle = .main, defaults: UserDefaults = .standard) -> Bool {
        start(infoDictionary: bundle.infoDictionary ?? [:], defaults: defaults)
    }

    @discardableResult
    static func start(infoDictionary: [String: Any], defaults: UserDefaults = .standard) -> Bool {
        guard let configuration = TelemetryConfiguration(infoDictionary: infoDictionary) else { return false }
        return runtime.withLock { current in
            guard current == nil else { return true }
            let scrubber = AttributeScrubber(anonymizer: Anonymizer(salt: Anonymizer.installSalt(in: defaults)), registry: sensitiveValues)
            let resource = Resource().merging(other: Resource(attributes: resourceAttributes(infoDictionary: infoDictionary, defaults: defaults)))
            current = Runtime(configuration: configuration, scrubber: scrubber, resource: resource)
            return true
        }
    }

    /// Factory names and hosts to replace with their hash wherever they appear in telemetry.
    public static func registerSensitive(_ values: some Sequence<String>) {
        sensitiveValues.insert(values)
    }

    public static func log(_ message: String, severity: Severity = .info, attributes: [String: String] = [:]) {
        runtime.withLock { $0 }?.logger.logRecordBuilder()
            .setSeverity(severity)
            .setBody(.string(message))
            .setAttributes(attributes.mapValues(AttributeValue.string))
            .emit()
    }

    public static func flush() {
        runtime.withLock { $0 }?.flush()
    }

    static func resourceAttributes(infoDictionary: [String: Any], defaults: UserDefaults) -> [String: AttributeValue] {
        let instanceKey = "fabrix.telemetry.instance-id"
        let instanceID = defaults.string(forKey: instanceKey) ?? UUID().uuidString
        defaults.set(instanceID, forKey: instanceKey)
        #if DEBUG
            let environment = "development"
        #else
            let environment = "production"
        #endif
        return [
            "service.name": .string("fabrix"),
            "service.version": .string(infoDictionary["CFBundleShortVersionString"] as? String ?? "unknown"),
            "service.instance.id": .string(instanceID),
            "app.build": .string(infoDictionary["CFBundleVersion"] as? String ?? "unknown"),
            "deployment.environment.name": .string(environment),
            "os.name": .string(osName),
            "os.version": .string(ProcessInfo.processInfo.operatingSystemVersionString),
            "device.model.identifier": .string(hardwareModel),
        ]
    }

    private static var osName: String {
        #if os(macOS)
            "macOS"
        #else
            "iOS"
        #endif
    }

    private static var hardwareModel: String {
        #if os(macOS)
            let name = "hw.model"
        #else
            let name = "hw.machine"
        #endif
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buffer, &size, nil, 0)
        return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}

final class Runtime: @unchecked Sendable {
    let logger: any OpenTelemetryApi.Logger
    private let tracerProvider: TracerProviderSdk
    private let logProcessor: BatchLogRecordProcessor
    private let meterProvider: MeterProviderSdk
    private let urlSessionInstrumentation: URLSessionInstrumentation

    init(configuration: TelemetryConfiguration, scrubber: AttributeScrubber, resource: Resource) {
        let otlp = OtlpConfiguration(headers: configuration.headers, exportAsJson: false)

        let spanHTTP = OtlpHttpTraceExporter(endpoint: configuration.url(for: "traces"), config: otlp, envVarHeaders: nil)
        let spanExporter = ScrubbingSpanExporter(scrubber: scrubber, wrapping: spanHTTP)
        tracerProvider = TracerProviderBuilder()
            .with(resource: resource)
            .add(spanProcessor: BatchSpanProcessor(spanExporter: spanExporter))
            .build()
        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)

        let logHTTP = OtlpHttpLogExporter(endpoint: configuration.url(for: "logs"), config: otlp, envVarHeaders: nil)
        let logExporter = ScrubbingLogExporter(scrubber: scrubber, wrapping: logHTTP)
        logProcessor = BatchLogRecordProcessor(logRecordExporter: logExporter)
        let loggerProvider = LoggerProviderBuilder()
            .with(resource: resource)
            .with(processors: [logProcessor])
            .build()
        OpenTelemetry.registerLoggerProvider(loggerProvider: loggerProvider)
        logger = loggerProvider.loggerBuilder(instrumentationScopeName: "fabrix").build()

        let metricExporter = OtlpHttpMetricExporter(endpoint: configuration.url(for: "metrics"), config: otlp, envVarHeaders: nil)
        meterProvider = Self.makeMeterProvider(exporter: metricExporter, resource: resource)
        OpenTelemetry.registerMeterProvider(meterProvider: meterProvider)

        let ingestHost = configuration.endpoint.host
        urlSessionInstrumentation = URLSessionInstrumentation(configuration: URLSessionInstrumentationConfiguration(
            shouldInstrument: { $0.url?.host != ingestHost },
            shouldInjectTracingHeaders: { _ in false },
            tracer: tracerProvider.get(instrumentationName: "fabrix.urlsession"),
            semanticConvention: .stable
        ))

        recordLaunch()
    }

    static func makeMeterProvider(exporter: MetricExporter, resource: Resource) -> MeterProviderSdk {
        MeterProviderSdk.builder()
            .setResource(resource: resource)
            .registerMetricReader(reader: PeriodicMetricReaderBuilder(exporter: exporter).setInterval(timeInterval: 60).build())
            // Without a registered view the SDK creates no storage and silently drops every measurement.
            .registerView(selector: InstrumentSelector.builder().setInstrument(name: ".*").build(), view: View.builder().build())
            .build()
    }

    func flush() {
        tracerProvider.forceFlush()
        logProcessor.forceFlush()
        _ = meterProvider.forceFlush()
    }

    private func recordLaunch() {
        tracerProvider.get(instrumentationName: "fabrix").spanBuilder(spanName: "app.launch").startSpan().end()
        meterProvider.get(name: "fabrix").counterBuilder(name: "fabrix.app.launches").build().add(value: 1)
        logger.logRecordBuilder().setSeverity(.info).setBody(.string("Telemetry started")).emit()
    }
}
