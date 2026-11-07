import FabrixCore
import Foundation
import Synchronization
@testable import FabrixFeatures
import Testing

private struct Sandbox: Sendable {
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

/// Plays the user approving on Paperclip's page: approves through the API, then stays open
/// until the app dismisses the sheet.
private final class ApprovingBrowser: WebAuthenticator {
    let sandbox: Sandbox
    private let count = Mutex(0)

    init(sandbox: Sandbox) {
        self.sandbox = sandbox
    }

    var approvals: Int { count.withLock { $0 } }

    func authenticate(url: URL, callbackScheme _: String) async throws -> URL {
        try await sandbox.approve(url)
        count.withLock { $0 += 1 }
        try await Task.sleep(for: .seconds(3600))
        throw CancellationError()
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
        let browser = ApprovingBrowser(sandbox: sandbox)

        await model.connect(ConnectForm(address: sandbox.url.absoluteString), webAuthenticator: browser)

        let factory = try #require(model.factory)
        #expect(model.browserSignIn == nil)
        #expect(model.companies.contains { $0.name == "Atlas Sandbox" })
        #expect(browser.approvals == 1)

        await model.signInAgain(webAuthenticator: browser)

        #expect(browser.approvals == 2)
        #expect(model.factory?.id == factory.id)
        #expect(store.factories.count == 1)
        #expect(model.companies.contains { $0.name == "Atlas Sandbox" })
        #expect(try await store.service(for: factory).credentialExpiry() != nil)
    }
}
