//
//  KeychainError.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation
import Security

/// Errors that can occur during keychain operations
enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case unexpectedData
    case unhandledError(status: OSStatus)
    case encodingError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "The requested item was not found in the keychain"
        case .duplicateItem:
            return "An item with this key already exists in the keychain"
        case .unexpectedData:
            return "Unexpected data format returned from keychain"
        case .unhandledError(let status):
            if let message = SecCopyErrorMessageString(status, nil) as String? {
                return "Keychain error: \(message) (status: \(status))"
            }
            return "Keychain error with status code: \(status)"
        case .encodingError:
            return "Failed to encode data for keychain storage"
        case .decodingError:
            return "Failed to decode data from keychain"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .itemNotFound:
            return "The item may have been deleted or never created. Try creating it first."
        case .duplicateItem:
            return "Delete the existing item first or use update instead."
        case .unexpectedData:
            return "The stored data format may be corrupted. Try deleting and recreating the item."
        case .unhandledError:
            return "This may be a system-level issue. Try restarting the app or device."
        case .encodingError, .decodingError:
            return "Check that the data type is Codable and try again."
        }
    }

    /// Convert OSStatus to KeychainError
    static func from(status: OSStatus) -> KeychainError {
        switch status {
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        default:
            return .unhandledError(status: status)
        }
    }
}
