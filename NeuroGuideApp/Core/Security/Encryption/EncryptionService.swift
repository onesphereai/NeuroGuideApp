//
//  EncryptionService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation

/// Protocol defining encryption and decryption operations
protocol EncryptionService {
    /// Generate a new encryption key
    func generateKey() throws -> Data

    /// Encrypt data using the provided key
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - key: Encryption key (256-bit for AES-256)
    /// - Returns: Encrypted data with nonce and authentication tag
    func encrypt(data: Data, using key: Data) throws -> Data

    /// Decrypt data using the provided key
    /// - Parameters:
    ///   - encryptedData: Data to decrypt (including nonce and tag)
    ///   - key: Decryption key
    /// - Returns: Decrypted plaintext data
    func decrypt(encryptedData: Data, using key: Data) throws -> Data

    /// Derive a key from a password using PBKDF2
    /// - Parameters:
    ///   - password: Password string
    ///   - salt: Salt for key derivation (16+ bytes recommended)
    ///   - rounds: Number of PBKDF2 rounds (100,000+ recommended)
    /// - Returns: Derived 256-bit key
    func deriveKey(from password: String, salt: Data, rounds: Int) throws -> Data
}
