//
//  KeychainHelper.swift
//  NeuroGuide
//
//  Simple helper for storing strings in Keychain
//

import Foundation

/// Simple helper for storing API keys and other strings in Keychain
struct KeychainHelper {

    private static let service = KeychainManager.shared

    /// Save a string to Keychain
    static func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        try? service.save(data: data, forKey: key, accessible: .afterFirstUnlock)
    }

    /// Load a string from Keychain
    static func load(forKey key: String) -> String? {
        guard let data = try? service.load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete a string from Keychain
    static func delete(forKey key: String) {
        try? service.delete(key: key)
    }
}
