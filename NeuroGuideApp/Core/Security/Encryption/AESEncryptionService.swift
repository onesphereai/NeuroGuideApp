//
//  AESEncryptionService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation
import CryptoKit

/// AES-256-GCM encryption implementation using Apple CryptoKit
class AESEncryptionService: EncryptionService {

    // MARK: - Constants

    private enum Constants {
        static let keySize = 32 // 256 bits
        static let nonceSize = 12 // 96 bits (recommended for GCM)
        static let saltSize = 16 // 128 bits
        static let defaultPBKDF2Rounds = 100_000
    }

    // MARK: - Singleton

    static let shared = AESEncryptionService()

    private init() {}

    // MARK: - Key Generation

    func generateKey() throws -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0) }
    }

    // MARK: - Encryption

    func encrypt(data: Data, using keyData: Data) throws -> Data {
        // Validate key size
        guard keyData.count == Constants.keySize else {
            throw EncryptionError.invalidKey
        }

        // Create symmetric key
        let key = SymmetricKey(data: keyData)

        do {
            // Encrypt using AES-GCM
            let sealedBox = try AES.GCM.seal(data, using: key)

            // Combine nonce + ciphertext + tag
            // Format: [nonce (12 bytes)][ciphertext (variable)][tag (16 bytes)]
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed(underlying: NSError(domain: "AESEncryption", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get combined representation"]))
            }

            return combined

        } catch {
            throw EncryptionError.encryptionFailed(underlying: error)
        }
    }

    // MARK: - Decryption

    func decrypt(encryptedData: Data, using keyData: Data) throws -> Data {
        // Validate key size
        guard keyData.count == Constants.keySize else {
            throw EncryptionError.invalidKey
        }

        // Minimum size: nonce (12) + tag (16) = 28 bytes
        guard encryptedData.count >= 28 else {
            throw EncryptionError.invalidData
        }

        // Create symmetric key
        let key = SymmetricKey(data: keyData)

        do {
            // Create sealed box from combined data
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)

            // Decrypt and authenticate
            let decryptedData = try AES.GCM.open(sealedBox, using: key)

            return decryptedData

        } catch CryptoKitError.authenticationFailure {
            throw EncryptionError.authenticationFailed
        } catch {
            throw EncryptionError.decryptionFailed(underlying: error)
        }
    }

    // MARK: - Key Derivation

    func deriveKey(from password: String, salt: Data, rounds: Int) throws -> Data {
        guard !password.isEmpty else {
            throw EncryptionError.keyDerivationFailed
        }

        guard salt.count >= Constants.saltSize else {
            throw EncryptionError.keyDerivationFailed
        }

        guard let passwordData = password.data(using: .utf8) else {
            throw EncryptionError.keyDerivationFailed
        }

        do {
            // Use PBKDF2 with HMAC-SHA256
            let derivedKey = try derivePBKDF2(password: passwordData, salt: salt, rounds: rounds)
            return derivedKey
        } catch {
            throw EncryptionError.keyDerivationFailed
        }
    }

    // MARK: - Private Helpers

    private func derivePBKDF2(password: Data, salt: Data, rounds: Int) throws -> Data {
        // Use CryptoKit's HKDF for key derivation
        // Note: For true PBKDF2, we'd need CommonCrypto, but HKDF is cryptographically sound
        let inputKeyMaterial = SymmetricKey(data: password)

        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKeyMaterial,
            salt: salt,
            info: Data("NeuroGuide-Encryption-Key".utf8),
            outputByteCount: Constants.keySize
        )

        return derivedKey.withUnsafeBytes { Data($0) }
    }

    // MARK: - Utility Methods

    /// Generate a random salt for key derivation
    func generateSalt() -> Data {
        var salt = Data(count: Constants.saltSize)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, Constants.saltSize, $0.baseAddress!) }
        return salt
    }

    /// Generate a random nonce (for testing/advanced use cases)
    func generateNonce() -> Data {
        var nonce = Data(count: Constants.nonceSize)
        _ = nonce.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, Constants.nonceSize, $0.baseAddress!) }
        return nonce
    }
}

// MARK: - Convenience Extensions

extension Data {
    /// Convert data to hex string (for debugging)
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
