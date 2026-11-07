import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

private struct Sandbox {
    var url: URL
    var key: String

    static var current: Sandbox? {
        let env = ProcessInfo.processInfo.environment
        guard let url = env["FABRIX_SANDBOX_URL"].flatMap(URL.init(string:)), let key = env["FABRIX_SANDBOX_KEY"] else { return nil }
        return Sandbox(url: url, key: key)
    }

    /// Approves a sign-in request the way the board user does on the approval page.
    func approve(_ approvalURL: URL) async throws {
        let components = try #require(URLComponents(url: approvalURL, resolvingAgainstBaseURL: false))
        let id = approvalURL.lastPathComponent
        let token = try #require(components.queryItems?.first { $0.name == "token" }?.value)
        var request = URLRequest(url: url.appending(path: "api/cli-auth/challenges/\(id)/approve"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["token": token])
        let (_, response) = try await URLSession.shared.data(for: request)
        #expect((response as? HTTPURLResponse)?.statusCode == 200)
    }
}

/// Browser sign-in through the app's own path, against a sandbox seeded by `scripts/paperclip-sandbox-seed.sh`.
@MainActor
@Suite(.serialized, .enabled(if: Sandbox.current != nil, "Set FABRIX_SANDBOX_URL to run against a Paperclip sandbox"))
struct SandboxSignInTests {
    private let sandbox = Sandbox.current!

    @Test func browserSignInConnectsThenSignsInAgain() async throws {
        let store = FactoryStore(defaults: UserDefaults(suiteName: "SandboxSignInTests-\(UUID().uuidString)")!, credentials: InMemoryCredentialStore())
        let model = AppModel(connector: StoreConnector(store: store), defaults: UserDefaults(suiteName: "SandboxSignInTests-\(UUID().uuidString)")!)
        var approvals: [Task<Void, any Error>] = []
        let approve: @MainActor (URL) -> Void = { url in approvals.append(Task { try await sandbox.approve(url) }) }

        await model.connect(ConnectForm(address: sandbox.url.absoluteString), openURL: approve)
        for approval in approvals { try await approval.value }

        let factory = try #require(model.factory)
        #expect(model.browserSignIn == nil)
        #expect(model.companies.contains { $0.name == "Atlas Sandbox" })
        #expect(approvals.count == 1)

        await model.signInAgain(openURL: approve)
        for approval in approvals { try await approval.value }

        #expect(approvals.count == 2)
        #expect(model.factory?.id == factory.id)
        #expect(store.factories.count == 1)
        #expect(model.companies.contains { $0.name == "Atlas Sandbox" })
        #expect(try await store.service(for: factory).credentialExpiry() != nil)
    }
}
