//
//  SecureStorageManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation

/// Implementation of SecureStorageService with encryption
class SecureStorageManager: SecureStorageService {

    // MARK: - Singleton

    static let shared = SecureStorageManager()

    // MARK: - Properties

    private let encryptionService: EncryptionService
    private let keychainService: KeychainService
    private let fileManager: FileManager

    private let storageDirectoryName = "SecureStorage"
    private let masterKeyIdentifier = "com.neuroguide.storage.masterKey"

    private var masterKey: Data?

    // MARK: - Initialization

    init(
        encryptionService: EncryptionService = AESEncryptionService.shared,
        keychainService: KeychainService = KeychainManager.shared,
        fileManager: FileManager = .default
    ) {
        self.encryptionService = encryptionService
        self.keychainService = keychainService
        self.fileManager = fileManager

        // Initialize master key
        try? initializeMasterKey()
    }

    // MARK: - Storage Directory

    func storageDirectory() -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(storageDirectoryName, isDirectory: true)
    }

    // MARK: - Encryption Status

    func isEncryptionEnabled() -> Bool {
        return masterKey != nil
    }

    // MARK: - Save

    func save<T: Codable>(_ object: T, forKey key: String) async throws {
        // Ensure storage directory exists
        try createStorageDirectoryIfNeeded()

        // Encode to JSON
        let data: Data
        do {
            data = try JSONEncoder().encode(object)
        } catch {
            throw StorageError.encodingFailed(underlying: error)
        }

        // Encrypt data
        let encryptedData: Data
        do {
            let key = try getMasterKey()
            encryptedData = try encryptionService.encrypt(data: data, using: key)
        } catch {
            throw StorageError.encryptionFailed(underlying: error)
        }

        // Write to file
        let fileURL = storageDirectory().appendingPathComponent(sanitizeKey(key))
        do {
            try encryptedData.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            throw StorageError.writeFailed(underlying: error)
        }
    }

    // MARK: - Load

    func load<T: Codable>(forKey key: String, as type: T.Type) async throws -> T? {
        let fileURL = storageDirectory().appendingPathComponent(sanitizeKey(key))

        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        // Read encrypted data
        let encryptedData: Data
        do {
            encryptedData = try Data(contentsOf: fileURL)
        } catch {
            throw StorageError.readFailed(underlying: error)
        }

        // Decrypt data
        let decryptedData: Data
        do {
            let key = try getMasterKey()
            decryptedData = try encryptionService.decrypt(encryptedData: encryptedData, using: key)
        } catch {
            throw StorageError.decryptionFailed(underlying: error)
        }

        // Decode from JSON
        do {
            let object = try JSONDecoder().decode(type, from: decryptedData)
            return object
        } catch {
            throw StorageError.decodingFailed(underlying: error)
        }
    }

    // MARK: - Delete

    func delete(forKey key: String) async throws {
        let fileURL = storageDirectory().appendingPathComponent(sanitizeKey(key))

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return // Already deleted
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw StorageError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Exists

    func exists(forKey key: String) -> Bool {
        let fileURL = storageDirectory().appendingPathComponent(sanitizeKey(key))
        return fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - Delete All

    func deleteAll() async throws {
        let directory = storageDirectory()

        guard fileManager.fileExists(atPath: directory.path) else {
            return // Nothing to delete
        }

        do {
            try fileManager.removeItem(at: directory)
            try createStorageDirectoryIfNeeded()
        } catch {
            throw StorageError.deleteFailed(underlying: error)
        }
    }

    // MARK: - All Keys

    func allKeys() throws -> [String] {
        let directory = storageDirectory()

        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        do {
            let filenames = try fileManager.contentsOfDirectory(atPath: directory.path)
            return filenames.map { desanitizeKey($0) }
        } catch {
            throw StorageError.readFailed(underlying: error)
        }
    }

    // MARK: - Private Helpers

    private func initializeMasterKey() throws {
        // Try to load existing key from keychain
        if let existingKey = try? keychainService.load(key: masterKeyIdentifier) {
            masterKey = existingKey
            return
        }

        // Generate new master key
        do {
            let newKey = try encryptionService.generateKey()
            try keychainService.save(
                data: newKey,
                forKey: masterKeyIdentifier,
                accessible: .afterFirstUnlockThisDeviceOnly
            )
            masterKey = newKey
        } catch {
            throw StorageError.masterKeyCreationFailed
        }
    }

    private func getMasterKey() throws -> Data {
        guard let key = masterKey else {
            // Try to reload from keychain
            if let key = try? keychainService.load(key: masterKeyIdentifier) {
                masterKey = key
                return key
            }
            throw StorageError.masterKeyNotFound
        }
        return key
    }

    private func createStorageDirectoryIfNeeded() throws {
        let directory = storageDirectory()

        guard !fileManager.fileExists(atPath: directory.path) else {
            return
        }

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ])
        } catch {
            throw StorageError.directoryCreationFailed(underlying: error)
        }
    }

    private func sanitizeKey(_ key: String) -> String {
        // Convert key to safe filename
        return key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .appending(".enc")
    }

    private func desanitizeKey(_ filename: String) -> String {
        // Convert filename back to key
        return filename
            .replacingOccurrences(of: ".enc", with: "")
            .replacingOccurrences(of: "_", with: ".")
    }
}

// MARK: - Convenience Methods

extension SecureStorageManager {
    /// Reset all secure storage (delete all files and regenerate master key)
    func resetStorage() async throws {
        // Delete all files
        try await deleteAll()

        // Delete master key from keychain
        try? keychainService.delete(key: masterKeyIdentifier)

        // Regenerate master key
        masterKey = nil
        try initializeMasterKey()
    }

    /// Get storage size in bytes
    func getStorageSize() throws -> Int64 {
        let directory = storageDirectory()

        guard fileManager.fileExists(atPath: directory.path) else {
            return 0
        }

        let files = try fileManager.contentsOfDirectory(atPath: directory.path)
        var totalSize: Int64 = 0

        for file in files {
            let fileURL = directory.appendingPathComponent(file)
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }

        return totalSize
    }
}
