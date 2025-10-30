//
//  EncryptionError.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation

/// Errors that can occur during encryption operations
enum EncryptionError: LocalizedError {
    case keyGenerationFailed
    case encryptionFailed(underlying: Error)
    case decryptionFailed(underlying: Error)
    case invalidKey
    case invalidData
    case authenticationFailed
    case keyDerivationFailed

    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        case .encryptionFailed(let error):
            return "Encryption failed: \(error.localizedDescription)"
        case .decryptionFailed(let error):
            return "Decryption failed: \(error.localizedDescription)"
        case .invalidKey:
            return "Invalid encryption key"
        case .invalidData:
            return "Invalid data format"
        case .authenticationFailed:
            return "Data authentication failed - data may be corrupted"
        case .keyDerivationFailed:
            return "Failed to derive encryption key"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .keyGenerationFailed:
            return "Try restarting the app. If the issue persists, reinstall the app."
        case .encryptionFailed, .decryptionFailed:
            return "Check that the data is not corrupted and try again."
        case .invalidKey:
            return "The encryption key may have been reset. You may need to re-authenticate."
        case .invalidData:
            return "The data format is not recognized. It may be from an older app version."
        case .authenticationFailed:
            return "The data appears to be corrupted or tampered with. It cannot be read."
        case .keyDerivationFailed:
            return "Unable to derive encryption key. Try restarting the app."
        }
    }
}
