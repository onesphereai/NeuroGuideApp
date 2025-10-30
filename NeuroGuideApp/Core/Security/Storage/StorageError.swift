//
//  StorageError.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation

/// Errors that can occur during secure storage operations
enum StorageError: LocalizedError {
    case fileNotFound(path: String)
    case writeFailed(underlying: Error)
    case readFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case directoryCreationFailed(underlying: Error)
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)
    case encryptionFailed(underlying: Error)
    case decryptionFailed(underlying: Error)
    case masterKeyNotFound
    case masterKeyCreationFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .writeFailed(let error):
            return "Failed to write file: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read file: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete file: \(error.localizedDescription)"
        case .directoryCreationFailed(let error):
            return "Failed to create directory: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .encryptionFailed(let error):
            return "Failed to encrypt data: \(error.localizedDescription)"
        case .decryptionFailed(let error):
            return "Failed to decrypt data: \(error.localizedDescription)"
        case .masterKeyNotFound:
            return "Encryption master key not found"
        case .masterKeyCreationFailed:
            return "Failed to create encryption master key"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "The file may not have been created yet. Try saving data first."
        case .writeFailed, .readFailed, .deleteFailed:
            return "Check that the app has permission to access the file system."
        case .directoryCreationFailed:
            return "Check available storage space and app permissions."
        case .encodingFailed, .decodingFailed:
            return "The data format may be incompatible. Try deleting and recreating."
        case .encryptionFailed, .decryptionFailed:
            return "The encryption key may have changed. You may need to reset app data."
        case .masterKeyNotFound:
            return "The encryption key may have been deleted. App data will be reset."
        case .masterKeyCreationFailed:
            return "Unable to initialize encryption. Try restarting the app."
        }
    }
}
