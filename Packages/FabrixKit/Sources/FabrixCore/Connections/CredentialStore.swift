import Foundation
import Security
import Synchronization

/// Secret storage for factory credentials, keyed by `Factory.ID`.
public protocol CredentialStore: Sendable {
    func credential(for factoryID: Factory.ID) throws -> String?
    /// Stores the credential, or deletes it when `credential` is nil.
    func setCredential(_ credential: String?, for factoryID: Factory.ID) throws
}

public struct KeychainError: Error, Equatable, Sendable {
    public var status: OSStatus
}

/// Generic-password items in the data protection keychain, shared code for iOS and macOS.
public struct KeychainCredentialStore: CredentialStore {
    public var service: String

    public init(service: String = "com.cedricziel.fabrix.factory") {
        self.service = service
    }

    public func credential(for factoryID: Factory.ID) throws -> String? {
        var query = baseQuery(factoryID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return (result as? Data).map { String(decoding: $0, as: UTF8.self) }
        case errSecItemNotFound: return nil
        default: throw KeychainError(status: status)
        }
    }

    public func setCredential(_ credential: String?, for factoryID: Factory.ID) throws {
        let deleteStatus = SecItemDelete(baseQuery(factoryID) as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw KeychainError(status: deleteStatus)
        }
        guard let credential else { return }

        var item = baseQuery(factoryID)
        item[kSecValueData as String] = Data(credential.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    private func baseQuery(_ factoryID: Factory.ID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: factoryID,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }
}

/// Keeps credentials in memory. For tests, previews and the demo factory.
public final class InMemoryCredentialStore: CredentialStore {
    private let storage = Mutex<[Factory.ID: String]>([:])

    public init() {}

    public func credential(for factoryID: Factory.ID) throws -> String? {
        storage.withLock { $0[factoryID] }
    }

    public func setCredential(_ credential: String?, for factoryID: Factory.ID) throws {
        storage.withLock { $0[factoryID] = credential }
    }

    public var isEmpty: Bool {
        storage.withLock { $0.isEmpty }
    }
}
