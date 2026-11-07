@testable import FabrixTelemetry
import Foundation
import Testing

struct TelemetryConfigurationTests {
    private let complete: [String: Any] = [
        "FabrixOTLPEndpoint": "https://ingest.example.com",
        "FabrixOTLPAPIKey": "sk-test",
        "FabrixOTLPTenantID": "apps",
        "FabrixOTLPDatasetID": "fabrix",
    ]

    @Test func readsAllKeysFromInfoDictionary() throws {
        let config = try #require(TelemetryConfiguration(infoDictionary: complete))
        #expect(config.endpoint == URL(string: "https://ingest.example.com"))
        #expect(config.apiKey == "sk-test")
        #expect(config.tenantID == "apps")
        #expect(config.datasetID == "fabrix")
    }

    @Test func sendsSignalDBHeaders() throws {
        let config = try #require(TelemetryConfiguration(infoDictionary: complete))
        let headers = Dictionary(uniqueKeysWithValues: config.headers)
        #expect(headers == [
            "authorization": "Bearer sk-test",
            "x-tenant-id": "apps",
            "x-dataset-id": "fabrix",
        ])
    }

    @Test func buildsSignalURLs() throws {
        let config = try #require(TelemetryConfiguration(infoDictionary: complete))
        #expect(config.url(for: "traces").absoluteString == "https://ingest.example.com/v1/traces")
    }

    @Test(arguments: ["FabrixOTLPEndpoint", "FabrixOTLPAPIKey", "FabrixOTLPTenantID", "FabrixOTLPDatasetID"])
    func isDisabledWhenAKeyIsMissing(key: String) {
        var info = complete
        info.removeValue(forKey: key)
        #expect(TelemetryConfiguration(infoDictionary: info) == nil)
    }

    @Test(arguments: ["", "  ", "$(OTLP_API_KEY)"])
    func isDisabledWhenTheKeyIsBlankOrUnexpanded(value: String) {
        var info = complete
        info["FabrixOTLPAPIKey"] = value
        #expect(TelemetryConfiguration(infoDictionary: info) == nil)
    }

    @Test func isDisabledForANonHTTPEndpoint() {
        var info = complete
        info["FabrixOTLPEndpoint"] = "not a url"
        #expect(TelemetryConfiguration(infoDictionary: info) == nil)
    }
}
