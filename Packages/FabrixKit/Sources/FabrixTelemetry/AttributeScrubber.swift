import Foundation
import OpenTelemetryApi

/// Rewrites telemetry so no Paperclip host, URL query or registered sensitive value is exported.
struct AttributeScrubber: Sendable {
    private static let hostKeys: Set<String> = [
        SemanticConventions.Server.address.rawValue, SemanticConventions.Client.address.rawValue,
        SemanticConventions.Url.domain.rawValue, SemanticConventions.Network.peerAddress.rawValue,
        "net.peer.name", "net.host.name", "http.host", PaperclipAttribute.factoryID.rawValue,
    ]
    private static let urlKeys: Set<String> = [
        SemanticConventions.Url.full.rawValue, SemanticConventions.Url.path.rawValue, "http.url", "http.target",
    ]
    private static let droppedKeys: Set<String> = [
        SemanticConventions.Url.query.rawValue, SemanticConventions.Url.fragment.rawValue,
        SemanticAttributes.networkConnectionSubtype.rawValue, SemanticAttributes.networkCarrierName.rawValue,
        SemanticAttributes.networkCarrierIcc.rawValue, SemanticAttributes.networkCarrierMcc.rawValue,
        SemanticAttributes.networkCarrierMnc.rawValue,
    ]

    let anonymizer: Anonymizer
    /// Longest first, so a value that contains another is replaced whole.
    private let sensitiveValues: [(value: String, hash: String)]

    init(anonymizer: Anonymizer, sensitiveValues: [String]) {
        self.anonymizer = anonymizer
        self.sensitiveValues = Set(sensitiveValues.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }
            .map { ($0, anonymizer.hash($0)) }
    }

    func scrub(url: String) -> String {
        guard var components = URLComponents(string: url) else {
            return scrubUnparseable(url: url)
        }
        if let host = components.host, !host.isEmpty {
            components.host = anonymizer.hash(Self.normalized(host))
        }
        components.user = nil
        components.password = nil
        components.port = nil
        components.query = nil
        components.fragment = nil
        let path = Self.template(components.path)
        components.path = ""
        return (components.string ?? "") + path
    }

    /// Fallback for strings URLComponents rejects: still hashes whatever sits where the host would.
    private func scrubUnparseable(url: String) -> String {
        let withoutQuery = String(url.prefix { $0 != "?" && $0 != "#" })
        guard let separator = withoutQuery.range(of: "://") else {
            return Self.template(withoutQuery)
        }
        let scheme = withoutQuery[..<separator.lowerBound]
        let rest = withoutQuery[separator.upperBound...]
        let authority = rest.prefix { $0 != "/" }
        let host = Self.stripPort(String(authority.split(separator: "@").last ?? authority))
        return "\(scheme)://\(anonymizer.hash(Self.normalized(host)))" + Self.template(String(rest.dropFirst(authority.count)))
    }

    func scrub(_ text: String) -> String {
        replaceSensitiveValues(in: text.replacing(#/(?i)\b[a-z][a-z0-9+.\-]*://[^\s"'<>]+/#) { match in
            let raw = String(match.output)
            let trailing = raw.reversed().prefix { ".,;:)]}".contains($0) }
            return scrub(url: String(raw.dropLast(trailing.count))) + String(trailing.reversed())
        })
    }

    private func replaceSensitiveValues(in text: String) -> String {
        var result = text
        for (value, hash) in sensitiveValues where result.range(of: value, options: .caseInsensitive) != nil {
            result = result.replacingOccurrences(of: value, with: hash, options: .caseInsensitive)
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
        let isPaperclipRequest = requestHost(in: attributes).map { host in
            sensitiveValues.contains { $0.value.caseInsensitiveCompare(host) == .orderedSame }
        } ?? false
        var result: [String: AttributeValue] = [:]
        for (key, value) in attributes where !Self.droppedKeys.contains(key) {
            switch (key, value) {
            case let (key, .string(host)) where Self.hostKeys.contains(key):
                result[key] = .string(anonymizer.hash(Self.normalized(Self.stripPort(host))))
            case let (key, .string(url)) where Self.urlKeys.contains(key):
                result[key] = .string(replaceSensitiveValues(in: scrub(url: url)))
            default:
                result[key] = scrub(value)
            }
        }
        if isPaperclipRequest, case let .string(path) = result[SemanticConventions.Url.path.rawValue], path.hasPrefix("/api/") {
            result[PaperclipAttribute.apiRoute.rawValue] = .string(path)
        }
        return result
    }

    /// Replaces path segments that look like identifiers (UUIDs, numbers, long opaque tokens) with `{id}`.
    static func template(_ path: String) -> String {
        path.split(separator: "/", omittingEmptySubsequences: false).map { segment in
            let isID = UUID(uuidString: String(segment)) != nil
                || (!segment.isEmpty && segment.allSatisfy(\.isNumber))
                || (segment.count >= 16 && segment.contains(where: \.isNumber) && segment.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
            return isID ? "{id}" : String(segment)
        }.joined(separator: "/")
    }

    private func requestHost(in attributes: [String: AttributeValue]) -> String? {
        if case let .string(address) = attributes[SemanticConventions.Server.address.rawValue] {
            return Self.normalized(Self.stripPort(address))
        }
        if case let .string(url) = attributes[SemanticConventions.Url.full.rawValue], let host = URLComponents(string: url)?.host {
            return Self.normalized(host)
        }
        return nil
    }

    private static func stripPort(_ host: String) -> String {
        // Unbracketed IPv6 can't carry a port, and URLComponents would misread its last group as one.
        if !host.hasPrefix("["), host.filter({ $0 == ":" }).count > 1 {
            return host
        }
        if let parsed = URLComponents(string: "//\(host)")?.host {
            return parsed
        }
        guard !host.hasPrefix("["), let colon = host.lastIndex(of: ":"), host[host.index(after: colon)...].allSatisfy(\.isNumber) else {
            return host
        }
        return String(host[..<colon])
    }

    /// IPv6 literals hash without their brackets, however they were written.
    private static func normalized(_ host: String) -> String {
        host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    }
}
