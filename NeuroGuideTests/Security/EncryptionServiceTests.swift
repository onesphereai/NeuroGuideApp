//
//  EncryptionServiceTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security Tests
//

import XCTest
@testable import NeuroGuideApp

final class EncryptionServiceTests: XCTestCase {

    var encryptionService: EncryptionService!

    override func setUp() {
        super.setUp()
        encryptionService = AESEncryptionService.shared
    }

    override func tearDown() {
        encryptionService = nil
        super.tearDown()
    }

    // MARK: - Key Generation Tests

    func testGenerateKey() throws {
        let key = try encryptionService.generateKey()

        XCTAssertEqual(key.count, 32, "Key should be 256 bits (32 bytes)")
    }

    func testGenerateUniqueKeys() throws {
        let key1 = try encryptionService.generateKey()
        let key2 = try encryptionService.generateKey()

        XCTAssertNotEqual(key1, key2, "Each generated key should be unique")
    }

    // MARK: - Encryption/Decryption Round-Trip Tests

    func testEncryptDecryptRoundTrip() throws {
        let key = try encryptionService.generateKey()
        let plaintext = "Hello, NeuroGuide!".data(using: .utf8)!

        // Encrypt
        let encrypted = try encryptionService.encrypt(data: plaintext, using: key)

        // Verify encrypted data is different from plaintext
        XCTAssertNotEqual(encrypted, plaintext)

        // Decrypt
        let decrypted = try encryptionService.decrypt(encryptedData: encrypted, using: key)

        // Verify decrypted matches original
        XCTAssertEqual(decrypted, plaintext)

        let decryptedString = String(data: decrypted, encoding: .utf8)
        XCTAssertEqual(decryptedString, "Hello, NeuroGuide!")
    }

    func testEncryptDecryptEmptyData() throws {
        let key = try encryptionService.generateKey()
        let plaintext = Data()

        let encrypted = try encryptionService.encrypt(data: plaintext, using: key)
        let decrypted = try encryptionService.decrypt(encryptedData: encrypted, using: key)

        XCTAssertEqual(decrypted, plaintext)
    }

    func testEncryptDecryptLargeData() throws {
        let key = try encryptionService.generateKey()

        // Create 1MB of random data
        var plaintext = Data(count: 1024 * 1024)
        _ = plaintext.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 1024 * 1024, $0.baseAddress!) }

        let encrypted = try encryptionService.encrypt(data: plaintext, using: key)
        let decrypted = try encryptionService.decrypt(encryptedData: encrypted, using: key)

        XCTAssertEqual(decrypted, plaintext)
    }

    // MARK: - Encryption Format Tests

    func testEncryptedDataContainsNonceAndTag() throws {
        let key = try encryptionService.generateKey()
        let plaintext = "Test".data(using: .utf8)!

        let encrypted = try encryptionService.encrypt(data: plaintext, using: key)

        // AES-GCM combined format: nonce (12) + ciphertext + tag (16)
        // Minimum size should be 28 bytes (12 + 16)
        XCTAssertGreaterThanOrEqual(encrypted.count, 28)
    }

    func testEncryptionProducesDifferentOutputsForSameInput() throws {
        let key = try encryptionService.generateKey()
        let plaintext = "Same input".data(using: .utf8)!

        let encrypted1 = try encryptionService.encrypt(data: plaintext, using: key)
        let encrypted2 = try encryptionService.encrypt(data: plaintext, using: key)

        // Should produce different ciphertext due to random nonce
        XCTAssertNotEqual(encrypted1, encrypted2)

        // But both should decrypt to the same plaintext
        let decrypted1 = try encryptionService.decrypt(encryptedData: encrypted1, using: key)
        let decrypted2 = try encryptionService.decrypt(encryptedData: encrypted2, using: key)

        XCTAssertEqual(decrypted1, plaintext)
        XCTAssertEqual(decrypted2, plaintext)
    }

    // MARK: - Error Handling Tests

    func testDecryptWithWrongKey() throws {
        let key1 = try encryptionService.generateKey()
        let key2 = try encryptionService.generateKey()
        let plaintext = "Secret message".data(using: .utf8)!

        let encrypted = try encryptionService.encrypt(data: plaintext, using: key1)

        // Attempt to decrypt with wrong key
        XCTAssertThrowsError(try encryptionService.decrypt(encryptedData: encrypted, using: key2)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }

    func testDecryptWithInvalidKey() throws {
        let invalidKey = Data(repeating: 0, count: 16) // Wrong size
        let fakeEncrypted = Data(repeating: 0, count: 32)

        XCTAssertThrowsError(try encryptionService.decrypt(encryptedData: fakeEncrypted, using: invalidKey)) { error in
            guard let encryptionError = error as? EncryptionError else {
                XCTFail("Expected EncryptionError")
                return
            }

            if case .invalidKey = encryptionError {
                // Expected
            } else {
                XCTFail("Expected invalidKey error, got \(encryptionError)")
            }
        }
    }

    func testDecryptWithCorruptedData() throws {
        let key = try encryptionService.generateKey()
        let plaintext = "Test message".data(using: .utf8)!

        var encrypted = try encryptionService.encrypt(data: plaintext, using: key)

        // Corrupt the ciphertext
        encrypted[20] ^= 0xFF

        // Should fail authentication
        XCTAssertThrowsError(try encryptionService.decrypt(encryptedData: encrypted, using: key)) { error in
            guard let encryptionError = error as? EncryptionError else {
                XCTFail("Expected EncryptionError")
                return
            }

            if case .authenticationFailed = encryptionError {
                // Expected - GCM authentication should fail
            } else if case .decryptionFailed = encryptionError {
                // Also acceptable
            } else {
                XCTFail("Expected authenticationFailed error, got \(encryptionError)")
            }
        }
    }

    func testDecryptWithTooShortData() throws {
        let key = try encryptionService.generateKey()
        let tooShortData = Data(repeating: 0, count: 10) // Less than 28 bytes

        XCTAssertThrowsError(try encryptionService.decrypt(encryptedData: tooShortData, using: key)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }

    func testEncryptWithInvalidKey() throws {
        let invalidKey = Data(repeating: 0, count: 16) // Wrong size
        let plaintext = "Test".data(using: .utf8)!

        XCTAssertThrowsError(try encryptionService.encrypt(data: plaintext, using: invalidKey)) { error in
            guard let encryptionError = error as? EncryptionError else {
                XCTFail("Expected EncryptionError")
                return
            }

            if case .invalidKey = encryptionError {
                // Expected
            } else {
                XCTFail("Expected invalidKey error, got \(encryptionError)")
            }
        }
    }

    // MARK: - Key Derivation Tests

    func testDeriveKey() throws {
        let password = "MySecurePassword123"
        let salt = Data(repeating: 1, count: 16)
        let rounds = 100_000

        let derivedKey = try encryptionService.deriveKey(from: password, salt: salt, rounds: rounds)

        XCTAssertEqual(derivedKey.count, 32, "Derived key should be 256 bits")
    }

    func testDeriveKeyDeterministic() throws {
        let password = "TestPassword"
        let salt = Data(repeating: 2, count: 16)
        let rounds = 10_000

        let key1 = try encryptionService.deriveKey(from: password, salt: salt, rounds: rounds)
        let key2 = try encryptionService.deriveKey(from: password, salt: salt, rounds: rounds)

        XCTAssertEqual(key1, key2, "Same password and salt should produce same key")
    }

    func testDeriveKeyDifferentPasswords() throws {
        let salt = Data(repeating: 3, count: 16)
        let rounds = 10_000

        let key1 = try encryptionService.deriveKey(from: "password1", salt: salt, rounds: rounds)
        let key2 = try encryptionService.deriveKey(from: "password2", salt: salt, rounds: rounds)

        XCTAssertNotEqual(key1, key2, "Different passwords should produce different keys")
    }

    func testDeriveKeyDifferentSalts() throws {
        let password = "SamePassword"
        let salt1 = Data(repeating: 4, count: 16)
        let salt2 = Data(repeating: 5, count: 16)
        let rounds = 10_000

        let key1 = try encryptionService.deriveKey(from: password, salt: salt1, rounds: rounds)
        let key2 = try encryptionService.deriveKey(from: password, salt: salt2, rounds: rounds)

        XCTAssertNotEqual(key1, key2, "Different salts should produce different keys")
    }

    func testDeriveKeyWithEmptyPassword() throws {
        let salt = Data(repeating: 6, count: 16)

        XCTAssertThrowsError(try encryptionService.deriveKey(from: "", salt: salt, rounds: 10_000)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }

    func testDeriveKeyWithShortSalt() throws {
        let salt = Data(repeating: 7, count: 8) // Too short

        XCTAssertThrowsError(try encryptionService.deriveKey(from: "password", salt: salt, rounds: 10_000)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }

    // MARK: - Utility Tests

    func testGenerateSalt() {
        let service = AESEncryptionService.shared

        let salt1 = service.generateSalt()
        let salt2 = service.generateSalt()

        XCTAssertEqual(salt1.count, 16)
        XCTAssertEqual(salt2.count, 16)
        XCTAssertNotEqual(salt1, salt2, "Each salt should be unique")
    }

    func testGenerateNonce() {
        let service = AESEncryptionService.shared

        let nonce1 = service.generateNonce()
        let nonce2 = service.generateNonce()

        XCTAssertEqual(nonce1.count, 12)
        XCTAssertEqual(nonce2.count, 12)
        XCTAssertNotEqual(nonce1, nonce2, "Each nonce should be unique")
    }

    // MARK: - Performance Tests

    func testEncryptionPerformance() throws {
        let key = try encryptionService.generateKey()
        let plaintext = Data(repeating: 0, count: 1024 * 100) // 100KB

        measure {
            _ = try? encryptionService.encrypt(data: plaintext, using: key)
        }
    }

    func testDecryptionPerformance() throws {
        let key = try encryptionService.generateKey()
        let plaintext = Data(repeating: 0, count: 1024 * 100) // 100KB
        let encrypted = try encryptionService.encrypt(data: plaintext, using: key)

        measure {
            _ = try? encryptionService.decrypt(encryptedData: encrypted, using: key)
        }
    }
}
