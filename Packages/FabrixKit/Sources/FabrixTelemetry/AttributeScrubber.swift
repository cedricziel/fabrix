import Foundation
import OpenTelemetryApi
import Synchronization

/// Values (factory names, hosts) that must never leave the device verbatim.
public final class SensitiveValues: Sendable {
    private let storage = Mutex<Set<String>>([])

    public init() {}

    public func insert(_ values: some Sequence<String>) {
        let cleaned = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        storage.withLock { $0.formUnion(cleaned) }
    }

    var values: Set<String> {
        storage.withLock { $0 }
    }
}

/// Rewrites telemetry so no Paperclip host, URL query or registered sensitive value is exported.
struct AttributeScrubber: Sendable {
    private static let hostKeys: Set<String> = [
        "net.peer.name", "net.host.name", "server.address", "client.address",
        "http.host", "url.domain", "network.peer.address",
    ]
    private static let urlKeys: Set<String> = ["http.url", "url.full", "http.target", "url.path"]
    private static let droppedKeys: Set<String> = ["url.query", "url.fragment"]

    let anonymizer: Anonymizer
    let registry: SensitiveValues

    init(anonymizer: Anonymizer, registry: SensitiveValues) {
        self.anonymizer = anonymizer
        self.registry = registry
    }

    init(anonymizer: Anonymizer, sensitiveValues: [String]) {
        let registry = SensitiveValues()
        registry.insert(sensitiveValues)
        self.init(anonymizer: anonymizer, registry: registry)
    }

    func scrub(url: String) -> String {
        guard var components = URLComponents(string: url) else {
            return String(url.prefix { $0 != "?" && $0 != "#" })
        }
        if let host = components.host, !host.isEmpty {
            components.host = anonymizer.hash(host)
        }
        components.user = nil
        components.password = nil
        components.port = nil
        components.query = nil
        components.fragment = nil
        return components.string ?? ""
    }

    func scrub(_ text: String) -> String {
        replaceSensitiveValues(in: text.replacing(#/https?://[^\s"'<>]+/#) { match in
            let raw = String(match.output)
            let trailing = raw.reversed().prefix { ".,;:)]}".contains($0) }
            return scrub(url: String(raw.dropLast(trailing.count))) + String(trailing.reversed())
        })
    }

    private func replaceSensitiveValues(in text: String) -> String {
        var result = text
        for value in registry.values.sorted(by: { $0.count > $1.count }) {
            result = result.replacingOccurrences(of: value, with: anonymizer.hash(value), options: .caseInsensitive)
        }
        return result
    }

    func scrub(_ value: AttributeValue) -> AttributeValue {
        switch value {
        case let .string(text):
            .string(scrub(text))
        case let .array(array):
            .array(AttributeArray(values: array.values.map(scrub)))
        case let .set(set):
            .set(AttributeSet(labels: scrub(attributes: set.labels)))
        default:
            value
        }
    }

    func scrub(attributes: [String: AttributeValue]) -> [String: AttributeValue] {
        var result: [String: AttributeValue] = [:]
        for (key, value) in attributes where !Self.droppedKeys.contains(key) {
            switch (key, value) {
            case let (key, .string(host)) where Self.hostKeys.contains(key):
                result[key] = .string(anonymizer.hash(Self.stripPort(host)))
            case let (key, .string(url)) where Self.urlKeys.contains(key):
                result[key] = .string(replaceSensitiveValues(in: scrub(url: url)))
            default:
                result[key] = scrub(value)
            }
        }
        return result
    }

    private static func stripPort(_ host: String) -> String {
        guard !host.hasPrefix("["), let colon = host.lastIndex(of: ":"),
              host[host.index(after: colon)...].allSatisfy(\.isNumber),
              host.firstIndex(of: ":") == colon
        else { return host }
        return String(host[..<colon])
    }
}
