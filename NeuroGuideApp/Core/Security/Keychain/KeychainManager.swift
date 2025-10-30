//
//  KeychainManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation
import Security

/// Implementation of KeychainService using iOS Security framework
class KeychainManager: KeychainService {

    // MARK: - Singleton

    static let shared = KeychainManager()

    // MARK: - Properties

    private let serviceName: String

    // MARK: - Initialization

    init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.neuroguide.app") {
        self.serviceName = serviceName
    }

    // MARK: - Save

    func save(data: Data, forKey key: String, accessible: KeychainAccessibility) throws {
        // Delete existing item first
        try? delete(key: key)

        // Build query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessible.attributeValue
        ]

        // Execute
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.from(status: status)
        }
    }

    // MARK: - Load

    func load(key: String) throws -> Data? {
        // Build query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Execute
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // Handle result
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.unexpectedData
            }
            return data

        case errSecItemNotFound:
            return nil

        default:
            throw KeychainError.from(status: status)
        }
    }

    // MARK: - Delete

    func delete(key: String) throws {
        // Build query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        // Execute
        let status = SecItemDelete(query as CFDictionary)

        // Success or item not found are both OK
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.from(status: status)
        }
    }

    // MARK: - Exists

    func exists(key: String) -> Bool {
        // Build query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]

        // Execute
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Delete All

    func deleteAll() throws {
        // Build query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        // Execute
        let status = SecItemDelete(query as CFDictionary)

        // Success or item not found are both OK
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.from(status: status)
        }
    }

    // MARK: - Codable Save

    func save<T: Codable>(object: T, forKey key: String, accessible: KeychainAccessibility) throws {
        do {
            let data = try JSONEncoder().encode(object)
            try save(data: data, forKey: key, accessible: accessible)
        } catch is EncodingError {
            throw KeychainError.encodingError
        } catch {
            throw error
        }
    }

    // MARK: - Codable Load

    func load<T: Codable>(key: String, type: T.Type) throws -> T? {
        guard let data = try load(key: key) else {
            return nil
        }

        do {
            let object = try JSONDecoder().decode(type, from: data)
            return object
        } catch is DecodingError {
            throw KeychainError.decodingError
        } catch {
            throw error
        }
    }

    // MARK: - Update (Helper)

    /// Update existing keychain item
    private func update(data: Data, forKey key: String) throws {
        // Build query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        // Build attributes to update
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        // Execute
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            throw KeychainError.from(status: status)
        }
    }
}

// MARK: - Key Constants

extension KeychainManager {
    /// Common keychain keys used throughout the app
    enum Keys {
        static let encryptionMasterKey = "com.neuroguide.encryption.masterKey"
        static let biometricEnabled = "com.neuroguide.biometric.enabled"
        static let userPasscode = "com.neuroguide.user.passcode"
    }
}
