@testable import FabrixTelemetry
import Foundation
import Synchronization
import Testing

private struct KeychainUnavailable: Error {}

private final class FakeInstallationIDStore: InstallationIDStore {
    let stored = Mutex<String?>(nil)
    let writes = Mutex(0)
    let failReads: Bool
    let failWrites: Bool

    init(failReads: Bool = false, failWrites: Bool = false) {
        self.failReads = failReads
        self.failWrites = failWrites
    }

    func read() throws -> String? {
        if failReads { throw KeychainUnavailable() }
        return stored.withLock { $0 }
    }

    func write(_ id: String) throws {
        writes.withLock { $0 += 1 }
        if failWrites { throw KeychainUnavailable() }
        stored.withLock { $0 = id }
    }
}

struct InstallationIDTests {
    @Test func firstCallGeneratesAndStoresAnID() {
        let store = FakeInstallationIDStore()
        let id = InstallationID.resolve(store: store)
        #expect(UUID(uuidString: id) != nil)
        #expect(store.stored.withLock { $0 } == id)
    }

    @Test func laterCallsReturnTheStoredID() {
        let store = FakeInstallationIDStore()
        let first = InstallationID.resolve(store: store)
        let second = InstallationID.resolve(store: store)
        #expect(first == second)
        #expect(store.writes.withLock { $0 } == 1)
    }

    @Test func unreadableKeychainFallsBackWithoutOverwriting() {
        let store = FakeInstallationIDStore(failReads: true)
        let id = InstallationID.resolve(store: store)
        #expect(UUID(uuidString: id) != nil)
        #expect(store.writes.withLock { $0 } == 0)
    }

    @Test func unwritableKeychainStillYieldsAnID() {
        let store = FakeInstallationIDStore(failWrites: true)
        #expect(UUID(uuidString: InstallationID.resolve(store: store)) != nil)
    }

    @Test func resourceCarriesTheInstallationIDTwice() {
        let attributes = Telemetry.resourceAttributes(infoDictionary: [:], installationID: "6F1C1E2A-0000-4000-8000-000000000001")
        #expect(attributes["app.installation.id"] == .string("6F1C1E2A-0000-4000-8000-000000000001"))
        #expect(attributes["service.instance.id"] == .string("6F1C1E2A-0000-4000-8000-000000000001"))
    }
}
