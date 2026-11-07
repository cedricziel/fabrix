import Foundation
import Security

/// Where the installation ID lives between launches.
protocol InstallationIDStore: Sendable {
    func read() throws -> String?
    func write(_ id: String) throws
}

/// A random UUID generated once per installation, never derived from hardware IDs or identifierForVendor.
enum InstallationID {
    /// Never throws or blocks on Keychain trouble: if the store can't be read or written,
    /// this launch gets its own random ID.
    static func resolve(store: some InstallationIDStore) -> String {
        let stored: String?
        do {
            stored = try store.read()
        } catch {
            return UUID().uuidString
        }
        if let stored, !stored.isEmpty {
            return stored
        }
        let id = UUID().uuidString
        try? store.write(id)
        return id
    }
}

/// A generic password in the app's default (shared) Keychain access group, the same one
/// FactoryStore uses. It survives reinstalls, stays on this device and is never synced.
struct KeychainInstallationIDStore: InstallationIDStore {
    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.cedricziel.fabrix.telemetry",
            kSecAttrAccount as String: "installation-id",
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrSynchronizable as String: false,
        ]
    }

    func read() throws -> String? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        switch status {
        case errSecSuccess: return (result as? Data).map { String(decoding: $0, as: UTF8.self) }
        case errSecItemNotFound: return nil
        default: throw KeychainFailure(status: status)
        }
    }

    func write(_ id: String) throws {
        var item = query
        item[kSecValueData as String] = Data(id.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainFailure(status: status) }
    }
}

struct KeychainFailure: Error {
    let status: OSStatus
}
