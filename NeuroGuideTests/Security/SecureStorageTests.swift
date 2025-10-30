//
//  SecureStorageTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security Tests
//

import XCTest
@testable import NeuroGuideApp

final class SecureStorageTests: XCTestCase {

    var secureStorage: SecureStorageService!
    var keychainService: KeychainService!
    let testKey = "test.storage.key"

    override func setUp() async throws {
        try await super.setUp()

        // Use test instances
        keychainService = KeychainManager(serviceName: "com.neuroguide.test.storage")
        let encryptionService = AESEncryptionService.shared

        secureStorage = SecureStorageManager(
            encryptionService: encryptionService,
            keychainService: keychainService,
            fileManager: .default
        )

        // Clean up any existing test data
        try await secureStorage.deleteAll()
    }

    override func tearDown() async throws {
        // Clean up after tests
        try await secureStorage.deleteAll()
        try? keychainService.deleteAll()

        secureStorage = nil
        keychainService = nil

        try await super.tearDown()
    }

    // MARK: - Test Models

    struct TestPerson: Codable, Equatable {
        let name: String
        let age: Int
        let email: String
    }

    struct TestSettings: Codable, Equatable {
        let notificationsEnabled: Bool
        let theme: String
        let fontSize: Int
    }

    // MARK: - Save Tests

    func testSaveObject() async throws {
        let person = TestPerson(name: "Alice", age: 30, email: "alice@example.com")

        try await secureStorage.save(person, forKey: testKey)

        XCTAssertTrue(secureStorage.exists(forKey: testKey))
    }

    func testSaveOverwritesExisting() async throws {
        let person1 = TestPerson(name: "Alice", age: 30, email: "alice@example.com")
        let person2 = TestPerson(name: "Bob", age: 25, email: "bob@example.com")

        try await secureStorage.save(person1, forKey: testKey)
        try await secureStorage.save(person2, forKey: testKey)

        let loaded = try await secureStorage.load(forKey: testKey, as: TestPerson.self)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.name, "Bob")
    }

    // MARK: - Load Tests

    func testLoadExistingObject() async throws {
        let person = TestPerson(name: "Charlie", age: 35, email: "charlie@example.com")

        try await secureStorage.save(person, forKey: testKey)
        let loaded = try await secureStorage.load(forKey: testKey, as: TestPerson.self)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded, person)
    }

    func testLoadNonExistentObject() async throws {
        let loaded = try await secureStorage.load(forKey: "nonexistent.key", as: TestPerson.self)

        XCTAssertNil(loaded)
    }

    // MARK: - Delete Tests

    func testDeleteExistingObject() async throws {
        let person = TestPerson(name: "David", age: 40, email: "david@example.com")

        try await secureStorage.save(person, forKey: testKey)
        XCTAssertTrue(secureStorage.exists(forKey: testKey))

        try await secureStorage.delete(forKey: testKey)
        XCTAssertFalse(secureStorage.exists(forKey: testKey))
    }

    func testDeleteNonExistentObject() async throws {
        // Should not throw
        try await secureStorage.delete(forKey: "nonexistent.key")
    }

    func testDeleteAll() async throws {
        // Save multiple items
        try await secureStorage.save(TestPerson(name: "A", age: 1, email: "a@test.com"), forKey: "key1")
        try await secureStorage.save(TestPerson(name: "B", age: 2, email: "b@test.com"), forKey: "key2")
        try await secureStorage.save(TestPerson(name: "C", age: 3, email: "c@test.com"), forKey: "key3")

        XCTAssertTrue(secureStorage.exists(forKey: "key1"))
        XCTAssertTrue(secureStorage.exists(forKey: "key2"))
        XCTAssertTrue(secureStorage.exists(forKey: "key3"))

        try await secureStorage.deleteAll()

        XCTAssertFalse(secureStorage.exists(forKey: "key1"))
        XCTAssertFalse(secureStorage.exists(forKey: "key2"))
        XCTAssertFalse(secureStorage.exists(forKey: "key3"))
    }

    // MARK: - Exists Tests

    func testExistsForSavedObject() async throws {
        XCTAssertFalse(secureStorage.exists(forKey: testKey))

        try await secureStorage.save(TestPerson(name: "Test", age: 1, email: "test@test.com"), forKey: testKey)

        XCTAssertTrue(secureStorage.exists(forKey: testKey))
    }

    func testExistsForNonExistentObject() {
        XCTAssertFalse(secureStorage.exists(forKey: "nonexistent.key"))
    }

    // MARK: - All Keys Tests

    func testAllKeys() async throws {
        try await secureStorage.save(TestPerson(name: "A", age: 1, email: "a@test.com"), forKey: "person.1")
        try await secureStorage.save(TestPerson(name: "B", age: 2, email: "b@test.com"), forKey: "person.2")
        try await secureStorage.save(TestPerson(name: "C", age: 3, email: "c@test.com"), forKey: "person.3")

        let keys = try secureStorage.allKeys()

        XCTAssertEqual(keys.count, 3)
        XCTAssertTrue(keys.contains("person.1"))
        XCTAssertTrue(keys.contains("person.2"))
        XCTAssertTrue(keys.contains("person.3"))
    }

    func testAllKeysWhenEmpty() throws {
        let keys = try secureStorage.allKeys()

        XCTAssertEqual(keys.count, 0)
    }

    // MARK: - Encryption Tests

    func testDataIsEncryptedOnDisk() async throws {
        let person = TestPerson(name: "Secret", age: 42, email: "secret@example.com")

        try await secureStorage.save(person, forKey: testKey)

        // Read the raw file
        let directory = secureStorage.storageDirectory()
        let filename = testKey.replacingOccurrences(of: ".", with: "_") + ".enc"
        let fileURL = directory.appendingPathComponent(filename)

        let rawData = try Data(contentsOf: fileURL)

        // Verify it doesn't contain plaintext
        let plaintextJSON = try JSONEncoder().encode(person)
        XCTAssertNotEqual(rawData, plaintextJSON, "Data should be encrypted on disk")

        // Verify we can't find the email in the raw data
        let rawString = String(data: rawData, encoding: .utf8) ?? ""
        XCTAssertFalse(rawString.contains("secret@example.com"), "Plaintext should not be readable")
    }

    func testEncryptionIsEnabled() {
        XCTAssertTrue(secureStorage.isEncryptionEnabled())
    }

    // MARK: - Multiple Object Types Tests

    func testSaveDifferentObjectTypes() async throws {
        let person = TestPerson(name: "Alice", age: 30, email: "alice@example.com")
        let settings = TestSettings(notificationsEnabled: true, theme: "dark", fontSize: 16)

        try await secureStorage.save(person, forKey: "person")
        try await secureStorage.save(settings, forKey: "settings")

        let loadedPerson = try await secureStorage.load(forKey: "person", as: TestPerson.self)
        let loadedSettings = try await secureStorage.load(forKey: "settings", as: TestSettings.self)

        XCTAssertEqual(loadedPerson, person)
        XCTAssertEqual(loadedSettings, settings)
    }

    // MARK: - Large Data Tests

    func testSaveLargeObject() async throws {
        // Create a large array
        var largeArray: [TestPerson] = []
        for i in 0..<1000 {
            largeArray.append(TestPerson(name: "Person\(i)", age: i, email: "person\(i)@example.com"))
        }

        try await secureStorage.save(largeArray, forKey: testKey)
        let loaded = try await secureStorage.load(forKey: testKey, as: [TestPerson].self)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 1000)
        XCTAssertEqual(loaded?.first?.name, "Person0")
        XCTAssertEqual(loaded?.last?.name, "Person999")
    }

    // MARK: - Storage Size Tests

    func testGetStorageSize() async throws {
        let manager = secureStorage as! SecureStorageManager

        let initialSize = try manager.getStorageSize()
        XCTAssertEqual(initialSize, 0)

        try await secureStorage.save(TestPerson(name: "Test", age: 1, email: "test@test.com"), forKey: testKey)

        let sizeAfterSave = try manager.getStorageSize()
        XCTAssertGreaterThan(sizeAfterSave, 0)
    }

    // MARK: - Reset Storage Tests

    func testResetStorage() async throws {
        let manager = secureStorage as! SecureStorageManager

        // Save some data
        try await secureStorage.save(TestPerson(name: "A", age: 1, email: "a@test.com"), forKey: "key1")
        try await secureStorage.save(TestPerson(name: "B", age: 2, email: "b@test.com"), forKey: "key2")

        XCTAssertTrue(secureStorage.exists(forKey: "key1"))
        XCTAssertTrue(secureStorage.exists(forKey: "key2"))

        // Reset
        try await manager.resetStorage()

        // Verify data is gone
        XCTAssertFalse(secureStorage.exists(forKey: "key1"))
        XCTAssertFalse(secureStorage.exists(forKey: "key2"))

        // Verify new master key works
        try await secureStorage.save(TestPerson(name: "C", age: 3, email: "c@test.com"), forKey: "key3")
        let loaded = try await secureStorage.load(forKey: "key3", as: TestPerson.self)

        XCTAssertNotNil(loaded)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSaves() async throws {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let person = TestPerson(name: "Person\(i)", age: i, email: "person\(i)@test.com")
                    try? await self.secureStorage.save(person, forKey: "concurrent.\(i)")
                }
            }
        }

        // Verify all were saved
        for i in 0..<10 {
            XCTAssertTrue(secureStorage.exists(forKey: "concurrent.\(i)"))
        }
    }

    // MARK: - Error Handling Tests

    func testLoadWithWrongType() async throws {
        let person = TestPerson(name: "Alice", age: 30, email: "alice@example.com")

        try await secureStorage.save(person, forKey: testKey)

        // Try to load as wrong type
        do {
            _ = try await secureStorage.load(forKey: testKey, as: TestSettings.self)
            XCTFail("Should have thrown decoding error")
        } catch {
            // Expected to throw
            XCTAssertTrue(error is StorageError)
        }
    }

    // MARK: - Storage Directory Tests

    func testStorageDirectoryExists() async throws {
        let directory = secureStorage.storageDirectory()

        try await secureStorage.save(TestPerson(name: "Test", age: 1, email: "test@test.com"), forKey: testKey)

        let exists = FileManager.default.fileExists(atPath: directory.path)
        XCTAssertTrue(exists)
    }

    // MARK: - Key Sanitization Tests

    func testSaveWithSpecialCharactersInKey() async throws {
        let person = TestPerson(name: "Test", age: 1, email: "test@test.com")
        let specialKey = "key/with:special/characters"

        try await secureStorage.save(person, forKey: specialKey)
        let loaded = try await secureStorage.load(forKey: specialKey, as: TestPerson.self)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded, person)
    }

    // MARK: - Performance Tests

    func testSavePerformance() async throws {
        let person = TestPerson(name: "Performance", age: 30, email: "perf@test.com")

        measure {
            Task {
                try? await secureStorage.save(person, forKey: testKey)
            }
        }
    }

    func testLoadPerformance() async throws {
        let person = TestPerson(name: "Performance", age: 30, email: "perf@test.com")
        try await secureStorage.save(person, forKey: testKey)

        measure {
            Task {
                _ = try? await secureStorage.load(forKey: testKey, as: TestPerson.self)
            }
        }
    }
}
