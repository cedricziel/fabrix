import Foundation
import OpenTelemetryApi
import OpenTelemetryProtocolExporterCommon
import OpenTelemetryProtocolExporterHttp
import OpenTelemetrySdk
import ResourceExtension
import Synchronization
import URLSessionInstrumentation

/// Entry point for the app shells: call `start()` once at launch and `flush()` when the app goes to the background.
public enum Telemetry {
    private static let runtime = Mutex<Runtime?>(nil)

    static var isRunning: Bool {
        runtime.withLock { $0 != nil }
    }

    /// Starts exporting to SignalDB if the build carries an ingest key; otherwise does nothing.
    /// `sensitiveValues` supplies factory names and hosts to replace wherever they appear.
    @discardableResult
    public static func start(sensitiveValues: (any SensitiveValueSource)? = nil) -> Bool {
        start(infoDictionary: Bundle.main.infoDictionary ?? [:], sensitiveValues: sensitiveValues ?? NoSensitiveValues())
    }

    @discardableResult
    static func start(
        infoDictionary: [String: Any],
        sensitiveValues: any SensitiveValueSource = NoSensitiveValues(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard let configuration = TelemetryConfiguration(infoDictionary: infoDictionary) else { return false }
        return runtime.withLock { current in
            guard current == nil else { return true }
            let anonymizer = Anonymizer(salt: Anonymizer.installSalt(in: defaults))
            let resource = Resource().merging(other: Resource(attributes: resourceAttributes(infoDictionary: infoDictionary, defaults: defaults)))
            current = Runtime(configuration: configuration, anonymizer: anonymizer, sensitiveValues: sensitiveValues, resource: resource)
            return true
        }
    }

    /// Exports what is buffered, off the main thread and within the time the OS grants before suspending.
    public static func flush() {
        guard let runtime = runtime.withLock({ $0 }) else { return }
        #if os(macOS)
            DispatchQueue.global(qos: .utility).async { runtime.flush() }
        #else
            ProcessInfo.processInfo.performExpiringActivity(withReason: "Flush telemetry") { expired in
                if !expired {
                    runtime.flush()
                }
            }
        #endif
    }

    static func resourceAttributes(infoDictionary: [String: Any], defaults: UserDefaults) -> [String: AttributeValue] {
        let instanceKey = "fabrix.telemetry.instance-id"
        let instanceID = defaults.string(forKey: instanceKey) ?? {
            let id = UUID().uuidString
            defaults.set(id, forKey: instanceKey)
            return id
        }()
        #if DEBUG
            let environment = "development"
        #else
            let environment = "production"
        #endif
        var attributes = OSResourceProvider(source: OperatingSystemDataSource()).attributes
        attributes[SemanticConventions.Service.name.rawValue] = .string("fabrix")
        attributes[SemanticConventions.Service.version.rawValue] = .string(infoDictionary["CFBundleShortVersionString"] as? String ?? "unknown")
        attributes[SemanticConventions.Service.instanceId.rawValue] = .string(instanceID)
        attributes[SemanticConventions.Deployment.environmentName.rawValue] = .string(environment)
        attributes[SemanticConventions.Device.modelIdentifier.rawValue] = DeviceDataSource().model.map(AttributeValue.string)
        attributes["app.build"] = .string(infoDictionary["CFBundleVersion"] as? String ?? "unknown")
        return attributes
    }
}

final class Runtime: @unchecked Sendable {
    private let logger: any OpenTelemetryApi.Logger
    private let tracerProvider: TracerProviderSdk
    private let logProcessor: BatchLogRecordProcessor
    private let meterProvider: MeterProviderSdk
    private let urlSessionInstrumentation: URLSessionInstrumentation

    init(configuration: TelemetryConfiguration, anonymizer: Anonymizer, sensitiveValues: any SensitiveValueSource, resource: Resource) {
        let otlp = OtlpConfiguration(headers: configuration.headers, exportAsJson: false)

        let spanHTTP = OtlpHttpTraceExporter(endpoint: configuration.url(for: "traces"), config: otlp, envVarHeaders: nil)
        let spanExporter = ScrubbingSpanExporter(anonymizer: anonymizer, sensitiveValues: sensitiveValues, wrapping: spanHTTP)
        tracerProvider = TracerProviderBuilder()
            .with(resource: resource)
            .add(spanProcessor: BatchSpanProcessor(spanExporter: spanExporter))
            .build()
        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)

        let logHTTP = OtlpHttpLogExporter(endpoint: configuration.url(for: "logs"), config: otlp, envVarHeaders: nil)
        let logExporter = ScrubbingLogExporter(anonymizer: anonymizer, sensitiveValues: sensitiveValues, wrapping: logHTTP)
        logProcessor = BatchLogRecordProcessor(logRecordExporter: logExporter)
        let loggerProvider = LoggerProviderBuilder()
            .with(resource: resource)
            .with(processors: [logProcessor])
            .build()
        OpenTelemetry.registerLoggerProvider(loggerProvider: loggerProvider)
        logger = loggerProvider.loggerBuilder(instrumentationScopeName: "fabrix").build()

        let metricExporter = OtlpHttpMetricExporter(endpoint: configuration.url(for: "metrics"), config: otlp, envVarHeaders: nil)
        meterProvider = Self.makeMeterProvider(exporter: ScrubbingMetricExporter(wrapping: metricExporter), resource: resource)
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
