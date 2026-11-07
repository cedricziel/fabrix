import Foundation
import OpenTelemetryApi
import Synchronization

/// Values (factory names, hosts) that must never leave the device verbatim.
public final class SensitiveValues: Sendable {
    private let storage = Mutex<[String]>([])

    public init() {}

    public func insert(_ values: some Sequence<String>) {
        let cleaned = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        storage.withLock { current in
            current = Set(current).union(cleaned).sorted { $0.count > $1.count }
        }
    }

    /// Longest first, so a value that contains another is replaced whole.
    var values: [String] {
        storage.withLock { $0 }
    }
}

/// Rewrites telemetry so no Paperclip host, URL query or registered sensitive value is exported.
struct AttributeScrubber: Sendable {
    private static let hostKeys: Set<String> = [
        SemanticConventions.Server.address.rawValue, SemanticConventions.Client.address.rawValue,
        SemanticConventions.Url.domain.rawValue, SemanticConventions.Network.peerAddress.rawValue,
        "net.peer.name", "net.host.name", "http.host",
    ]
    private static let urlKeys: Set<String> = [
        SemanticConventions.Url.full.rawValue, SemanticConventions.Url.path.rawValue, "http.url", "http.target",
    ]
    private static let droppedKeys: Set<String> = [SemanticConventions.Url.query.rawValue, SemanticConventions.Url.fragment.rawValue]

    let anonymizer: Anonymizer
    let registry: SensitiveValues

    init(anonymizer: Anonymizer, registry: SensitiveValues) {
        self.anonymizer = anonymizer
        self.registry = registry
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
        for value in registry.values where result.range(of: value, options: .caseInsensitive) != nil {
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
        URLComponents(string: "//\(host)")?.host ?? host
    }
}
