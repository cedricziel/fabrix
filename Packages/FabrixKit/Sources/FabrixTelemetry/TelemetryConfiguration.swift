import Foundation

/// Where and how to ship OTLP data. Built from Info.plist keys that CI fills at build time;
/// any missing, blank or unexpanded value means telemetry stays off.
struct TelemetryConfiguration: Sendable, Equatable {
    let endpoint: URL
    let apiKey: String
    let tenantID: String
    let datasetID: String

    init?(infoDictionary: [String: Any]) {
        func value(_ key: String) -> String? {
            guard let raw = (infoDictionary[key] as? String)?.trimmingCharacters(in: .whitespaces),
                  !raw.isEmpty, !raw.contains("$(")
            else { return nil }
            return raw
        }
        guard let endpoint = value("FabrixOTLPEndpoint").flatMap(URL.init(string:)),
              ["http", "https"].contains(endpoint.scheme),
              let apiKey = value("FabrixOTLPAPIKey"),
              let tenantID = value("FabrixOTLPTenantID"),
              let datasetID = value("FabrixOTLPDatasetID")
        else { return nil }
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.tenantID = tenantID
        self.datasetID = datasetID
    }

    var headers: [(String, String)] {
        [("authorization", "Bearer \(apiKey)"), ("x-tenant-id", tenantID), ("x-dataset-id", datasetID)]
    }

    func url(for signal: String) -> URL {
        endpoint.appending(path: "v1/\(signal)")
    }
}
