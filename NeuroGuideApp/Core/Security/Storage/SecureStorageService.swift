//
//  SecureStorageService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation

/// Protocol defining secure local storage with encryption
protocol SecureStorageService {
    /// Save Codable object with automatic encryption
    /// - Parameters:
    ///   - object: Object to save
    ///   - key: Unique identifier for the object
    func save<T: Codable>(_ object: T, forKey key: String) async throws

    /// Load Codable object with automatic decryption
    /// - Parameters:
    ///   - key: Unique identifier for the object
    ///   - type: Type of the object to decode
    /// - Returns: Decoded object, or nil if not found
    func load<T: Codable>(forKey key: String, as type: T.Type) async throws -> T?

    /// Delete stored object
    /// - Parameter key: Unique identifier for the object
    func delete(forKey key: String) async throws

    /// Check if object exists
    /// - Parameter key: Unique identifier for the object
    /// - Returns: True if object exists
    func exists(forKey key: String) -> Bool

    /// Delete all stored objects (use with caution)
    func deleteAll() async throws

    /// Get list of all stored keys
    func allKeys() throws -> [String]

    /// Get storage directory URL
    func storageDirectory() -> URL

    /// Check if encryption is enabled
    func isEncryptionEnabled() -> Bool
}

// MARK: - Storage Keys

/// Common storage keys used throughout the app
enum SecureStorageKeys {
    // Settings
    static let appSettings = "app.settings"
    static let privacySettings = "privacy.settings"
    static let accessibilitySettings = "accessibility.settings"

    // User data (future)
    static func childProfile(id: String) -> String {
        return "child.profile.\(id)"
    }

    static func sessionData(id: String) -> String {
        return "session.data.\(id)"
    }

    static func analysisResult(id: String) -> String {
        return "analysis.result.\(id)"
    }
}
