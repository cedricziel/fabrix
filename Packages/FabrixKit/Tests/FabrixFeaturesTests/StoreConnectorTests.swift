import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
struct StoreConnectorTests {
    private let issuer = URL(string: "https://auth.example")!

    @Test func boardKeyUsesPaperclipAuthOnly() {
        let (configuration, key) = StoreConnector.configuration(for: .paperclip(apiKey: "k"))
        #expect(configuration == .boardKey)
        #expect(key == "k")
    }

    @Test func oidcAloneSendsTheTokenInAuthorization() throws {
        let (configuration, key) = StoreConnector.configuration(for: .oidc(issuer: issuer, clientID: "fabrix"))
        let oidc = try #require(configuration.oidc)
        #expect(!configuration.usesBoardKey && key == nil)
        #expect(oidc.issuer == issuer && oidc.clientID == "fabrix")
        #expect(oidc.tokenHeader == "Authorization")
        #expect(oidc.redirectURI.scheme == "com.cedricziel.fabrix")
    }

    @Test func oidcInFrontOfPaperclipMovesTheTokenOutOfAuthorization() throws {
        let (configuration, key) = StoreConnector.configuration(for: .oidcWithPaperclip(issuer: issuer, clientID: "c", apiKey: "k"))
        #expect(configuration.usesBoardKey && key == "k")
        #expect(configuration.oidc?.tokenHeader == "X-Forwarded-Access-Token")
        #expect(throws: Never.self) { try configuration.validate() }
    }

    @Test func unknownFactoryIsNotRestored() {
        let store = FactoryStore(defaults: UserDefaults(suiteName: UUID().uuidString)!, credentials: InMemoryCredentialStore())
        #expect(StoreConnector(store: store).restore(factoryID: "missing") == nil)
    }
}
