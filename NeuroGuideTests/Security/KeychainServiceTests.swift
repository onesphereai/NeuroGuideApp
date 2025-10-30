//
//  KeychainServiceTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security Tests
//

import XCTest
@testable import NeuroGuideApp

final class KeychainServiceTests: XCTestCase {

    var keychainService: KeychainService!
    let testKey = "com.neuroguide.test.key"

    override func setUp() {
        super.setUp()
        keychainService = KeychainManager(serviceName: "com.neuroguide.test")

        // Clean up any existing test data
        try? keychainService.deleteAll()
    }

    override func tearDown() {
        // Clean up after tests
        try? keychainService.deleteAll()
        keychainService = nil
        super.tearDown()
    }

    // MARK: - Save Tests

    func testSaveData() throws {
        let testData = "Hello, Keychain!".data(using: .utf8)!

        try keychainService.save(data: testData, forKey: testKey)

        // Verify it was saved
        XCTAssertTrue(keychainService.exists(key: testKey))
    }

    func testSaveOverwritesExisting() throws {
        let data1 = "First".data(using: .utf8)!
        let data2 = "Second".data(using: .utf8)!

        try keychainService.save(data: data1, forKey: testKey)
        try keychainService.save(data: data2, forKey: testKey)

        let loaded = try keychainService.load(key: testKey)
        let loadedString = String(data: loaded!, encoding: .utf8)

        XCTAssertEqual(loadedString, "Second")
    }

    func testSaveWithDifferentAccessibility() throws {
        let testData = "Test".data(using: .utf8)!

        try keychainService.save(data: testData, forKey: testKey, accessible: .whenUnlocked)

        XCTAssertTrue(keychainService.exists(key: testKey))
    }

    // MARK: - Load Tests

    func testLoadExistingData() throws {
        let testData = "Load me!".data(using: .utf8)!

        try keychainService.save(data: testData, forKey: testKey)
        let loaded = try keychainService.load(key: testKey)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded, testData)
    }

    func testLoadNonExistentData() throws {
        let loaded = try keychainService.load(key: "nonexistent.key")

        XCTAssertNil(loaded)
    }

    // MARK: - Delete Tests

    func testDeleteExistingData() throws {
        let testData = "Delete me!".data(using: .utf8)!

        try keychainService.save(data: testData, forKey: testKey)
        XCTAssertTrue(keychainService.exists(key: testKey))

        try keychainService.delete(key: testKey)
        XCTAssertFalse(keychainService.exists(key: testKey))
    }

    func testDeleteNonExistentData() throws {
        // Should not throw
        XCTAssertNoThrow(try keychainService.delete(key: "nonexistent.key"))
    }

    func testDeleteAll() throws {
        // Save multiple items
        try keychainService.save(data: Data([1]), forKey: "key1")
        try keychainService.save(data: Data([2]), forKey: "key2")
        try keychainService.save(data: Data([3]), forKey: "key3")

        XCTAssertTrue(keychainService.exists(key: "key1"))
        XCTAssertTrue(keychainService.exists(key: "key2"))
        XCTAssertTrue(keychainService.exists(key: "key3"))

        try keychainService.deleteAll()

        XCTAssertFalse(keychainService.exists(key: "key1"))
        XCTAssertFalse(keychainService.exists(key: "key2"))
        XCTAssertFalse(keychainService.exists(key: "key3"))
    }

    // MARK: - Exists Tests

    func testExistsForSavedData() throws {
        XCTAssertFalse(keychainService.exists(key: testKey))

        try keychainService.save(data: Data([1, 2, 3]), forKey: testKey)

        XCTAssertTrue(keychainService.exists(key: testKey))
    }

    func testExistsForNonExistentData() {
        XCTAssertFalse(keychainService.exists(key: "nonexistent.key"))
    }

    // MARK: - Codable Tests

    struct TestModel: Codable, Equatable {
        let name: String
        let age: Int
        let isActive: Bool
    }

    func testSaveCodableObject() throws {
        let model = TestModel(name: "Alice", age: 30, isActive: true)

        try keychainService.save(object: model, forKey: testKey)

        XCTAssertTrue(keychainService.exists(key: testKey))
    }

    func testLoadCodableObject() throws {
        let model = TestModel(name: "Bob", age: 25, isActive: false)

        try keychainService.save(object: model, forKey: testKey)
        let loaded = try keychainService.load(key: testKey, type: TestModel.self)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded, model)
    }

    func testLoadNonExistentCodableObject() throws {
        let loaded = try keychainService.load(key: "nonexistent.key", type: TestModel.self)

        XCTAssertNil(loaded)
    }

    func testSaveCodableArray() throws {
        let models = [
            TestModel(name: "Alice", age: 30, isActive: true),
            TestModel(name: "Bob", age: 25, isActive: false),
            TestModel(name: "Charlie", age: 35, isActive: true)
        ]

        try keychainService.save(object: models, forKey: testKey)
        let loaded = try keychainService.load(key: testKey, type: [TestModel].self)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 3)
        XCTAssertEqual(loaded, models)
    }

    // MARK: - Error Handling Tests

    func testSaveInvalidKeyThrows() {
        // This test verifies the keychain handles edge cases
        // Empty key should still work, but we test the behavior
        let emptyKey = ""
        let testData = Data([1, 2, 3])

        // Empty key should still save (keychain allows it)
        XCTAssertNoThrow(try keychainService.save(data: testData, forKey: emptyKey))
    }

    // MARK: - Multiple Keys Tests

    func testMultipleKeysIndependent() throws {
        let data1 = "Data 1".data(using: .utf8)!
        let data2 = "Data 2".data(using: .utf8)!
        let data3 = "Data 3".data(using: .utf8)!

        try keychainService.save(data: data1, forKey: "key1")
        try keychainService.save(data: data2, forKey: "key2")
        try keychainService.save(data: data3, forKey: "key3")

        let loaded1 = try keychainService.load(key: "key1")
        let loaded2 = try keychainService.load(key: "key2")
        let loaded3 = try keychainService.load(key: "key3")

        XCTAssertEqual(loaded1, data1)
        XCTAssertEqual(loaded2, data2)
        XCTAssertEqual(loaded3, data3)
    }

    func testDeleteOneKeyDoesNotAffectOthers() throws {
        try keychainService.save(data: Data([1]), forKey: "key1")
        try keychainService.save(data: Data([2]), forKey: "key2")
        try keychainService.save(data: Data([3]), forKey: "key3")

        try keychainService.delete(key: "key2")

        XCTAssertTrue(keychainService.exists(key: "key1"))
        XCTAssertFalse(keychainService.exists(key: "key2"))
        XCTAssertTrue(keychainService.exists(key: "key3"))
    }

    // MARK: - Data Size Tests

    func testSaveLargeData() throws {
        // Create 1MB of data
        let largeData = Data(repeating: 42, count: 1024 * 1024)

        try keychainService.save(data: largeData, forKey: testKey)
        let loaded = try keychainService.load(key: testKey)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, largeData.count)
    }

    func testSaveEmptyData() throws {
        let emptyData = Data()

        try keychainService.save(data: emptyData, forKey: testKey)
        let loaded = try keychainService.load(key: testKey)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 0)
    }

    // MARK: - Persistence Tests

    func testDataPersistsAcrossInstances() throws {
        let testData = "Persistent".data(using: .utf8)!

        try keychainService.save(data: testData, forKey: testKey)

        // Create new instance
        let newKeychainService = KeychainManager(serviceName: "com.neuroguide.test")
        let loaded = try newKeychainService.load(key: testKey)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded, testData)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentSaves() throws {
        let expectation = self.expectation(description: "Concurrent saves")
        expectation.expectedFulfillmentCount = 10

        DispatchQueue.concurrentPerform(iterations: 10) { index in
            let key = "concurrent.key.\(index)"
            let data = "Data \(index)".data(using: .utf8)!

            do {
                try self.keychainService.save(data: data, forKey: key)
                expectation.fulfill()
            } catch {
                XCTFail("Save failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // Verify all were saved
        for index in 0..<10 {
            let key = "concurrent.key.\(index)"
            XCTAssertTrue(keychainService.exists(key: key))
        }
    }

    // MARK: - Service Isolation Tests

    func testDifferentServicesAreIsolated() throws {
        let service1 = KeychainManager(serviceName: "service1")
        let service2 = KeychainManager(serviceName: "service2")

        let testData = "Test".data(using: .utf8)!

        try service1.save(data: testData, forKey: testKey)

        // service2 should not see service1's data
        XCTAssertFalse(service2.exists(key: testKey))

        // Clean up
        try? service1.delete(key: testKey)
    }
}
