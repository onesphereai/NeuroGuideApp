//
//  KeychainService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation

/// Protocol defining keychain operations for secure credential storage
protocol KeychainService {
    /// Save data to keychain
    /// - Parameters:
    ///   - data: Data to store
    ///   - key: Unique identifier for the item
    ///   - accessible: When the item should be accessible (default: afterFirstUnlock)
    func save(data: Data, forKey key: String, accessible: KeychainAccessibility) throws

    /// Load data from keychain
    /// - Parameter key: Unique identifier for the item
    /// - Returns: Stored data, or nil if not found
    func load(key: String) throws -> Data?

    /// Delete item from keychain
    /// - Parameter key: Unique identifier for the item
    func delete(key: String) throws

    /// Check if item exists in keychain
    /// - Parameter key: Unique identifier for the item
    /// - Returns: True if item exists
    func exists(key: String) -> Bool

    /// Delete all items from keychain (use with caution)
    func deleteAll() throws

    /// Save Codable object to keychain
    /// - Parameters:
    ///   - object: Codable object to store
    ///   - key: Unique identifier for the item
    ///   - accessible: When the item should be accessible
    func save<T: Codable>(object: T, forKey key: String, accessible: KeychainAccessibility) throws

    /// Load Codable object from keychain
    /// - Parameters:
    ///   - key: Unique identifier for the item
    ///   - type: Type of the object to decode
    /// - Returns: Decoded object, or nil if not found
    func load<T: Codable>(key: String, type: T.Type) throws -> T?
}

/// Keychain accessibility options
enum KeychainAccessibility {
    case afterFirstUnlock           // Accessible after first device unlock (default)
    case afterFirstUnlockThisDeviceOnly  // Not backed up to iCloud
    case whenUnlocked                // Only when device is unlocked
    case whenUnlockedThisDeviceOnly  // Not backed up, only when unlocked
    case whenPasscodeSetThisDeviceOnly // Requires device passcode

    var attributeValue: String {
        switch self {
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock as String
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked as String
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String
        }
    }
}

// MARK: - Default Parameter Extension

extension KeychainService {
    func save(data: Data, forKey key: String, accessible: KeychainAccessibility = .afterFirstUnlockThisDeviceOnly) throws {
        try save(data: data, forKey: key, accessible: accessible)
    }

    func save<T: Codable>(object: T, forKey key: String, accessible: KeychainAccessibility = .afterFirstUnlockThisDeviceOnly) throws {
        try save(object: object, forKey: key, accessible: accessible)
    }
}
