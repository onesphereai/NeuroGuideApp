//
//  EmergencyResourceTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 1.3 - Settings & Help System Tests
//

import XCTest
@testable import NeuroGuideApp

final class EmergencyResourceTests: XCTestCase {

    // MARK: - Default Resources Tests

    func testDefaultResourcesExist() {
        let resources = EmergencyResource.defaultResources
        XCTAssertFalse(resources.isEmpty)
        XCTAssertGreaterThanOrEqual(resources.count, 5)
    }

    func testNationalSuicidePreventionLifeline() {
        let resource = EmergencyResource.nationalSuicidePreventionLifeline

        XCTAssertEqual(resource.name, "988 Suicide & Crisis Lifeline")
        XCTAssertEqual(resource.phoneNumber, "988")
        XCTAssertEqual(resource.category, .crisis)
        XCTAssertEqual(resource.availability, "24/7")
        XCTAssertFalse(resource.isNeurodiversityFocused)
    }

    func testAutismCrisisLine() {
        let resource = EmergencyResource.autismCrisisLine

        XCTAssertTrue(resource.name.contains("Autism"))
        XCTAssertEqual(resource.category, .autism)
        XCTAssertTrue(resource.isNeurodiversityFocused)
    }

    func testCrisisTextLine() {
        let resource = EmergencyResource.crisisTextLine

        XCTAssertTrue(resource.name.contains("Text"))
        XCTAssertEqual(resource.phoneNumber, "741741")
        XCTAssertEqual(resource.category, .crisis)
    }

    // MARK: - Category Tests

    func testResourceCategories() {
        let categories = EmergencyResource.ResourceCategory.allCases
        XCTAssertEqual(categories.count, 4)
        XCTAssertTrue(categories.contains(.crisis))
        XCTAssertTrue(categories.contains(.autism))
        XCTAssertTrue(categories.contains(.mental))
        XCTAssertTrue(categories.contains(.local))
    }

    func testGroupedByCategory() {
        let grouped = EmergencyResource.groupedByCategory()

        XCTAssertNotNil(grouped[.crisis])
        XCTAssertNotNil(grouped[.autism])

        // Verify crisis resources
        let crisisResources = grouped[.crisis] ?? []
        XCTAssertGreaterThan(crisisResources.count, 0)

        // Verify autism resources
        let autismResources = grouped[.autism] ?? []
        XCTAssertGreaterThan(autismResources.count, 0)
        XCTAssertTrue(autismResources.allSatisfy { $0.isNeurodiversityFocused })
    }

    // MARK: - Equatable Tests

    func testResourceEquality() {
        let resource1 = EmergencyResource.nationalSuicidePreventionLifeline
        let resource2 = EmergencyResource.nationalSuicidePreventionLifeline

        XCTAssertEqual(resource1, resource2)
    }

    func testResourceInequality() {
        let resource1 = EmergencyResource.nationalSuicidePreventionLifeline
        let resource2 = EmergencyResource.crisisTextLine

        XCTAssertNotEqual(resource1, resource2)
    }

    // MARK: - Identifiable Tests

    func testUniqueIDs() {
        let resources = EmergencyResource.defaultResources
        let ids = resources.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All resource IDs should be unique")
    }
}

// MARK: - EmergencyResourcesManager Tests

final class EmergencyResourcesManagerTests: XCTestCase {

    var manager: EmergencyResourcesManager!

    override func setUp() {
        super.setUp()
        manager = EmergencyResourcesManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertTrue(manager.localContacts.isEmpty)
        XCTAssertFalse(manager.allResources.isEmpty)
    }

    func testAllResourcesIncludesDefaults() {
        let allResources = manager.allResources
        let defaultResources = EmergencyResource.defaultResources

        XCTAssertGreaterThanOrEqual(allResources.count, defaultResources.count)
    }

    // MARK: - Add Local Contact Tests

    func testAddLocalContact() {
        let initialCount = manager.localContacts.count

        manager.addLocalContact(
            name: "Test Hospital",
            phoneNumber: "555-0100",
            description: "Local emergency hospital"
        )

        XCTAssertEqual(manager.localContacts.count, initialCount + 1)

        let addedContact = manager.localContacts.first
        XCTAssertNotNil(addedContact)
        XCTAssertEqual(addedContact?.name, "Test Hospital")
        XCTAssertEqual(addedContact?.phoneNumber, "555-0100")
        XCTAssertEqual(addedContact?.category, .local)
    }

    func testAddMultipleLocalContacts() {
        manager.addLocalContact(
            name: "Contact 1",
            phoneNumber: "555-0101",
            description: "First contact"
        )

        manager.addLocalContact(
            name: "Contact 2",
            phoneNumber: "555-0102",
            description: "Second contact"
        )

        XCTAssertEqual(manager.localContacts.count, 2)
    }

    // MARK: - Remove Local Contact Tests

    func testRemoveLocalContact() {
        manager.addLocalContact(
            name: "Test Contact",
            phoneNumber: "555-0100",
            description: "To be removed"
        )

        guard let contactToRemove = manager.localContacts.first else {
            XCTFail("Contact not added")
            return
        }

        manager.removeLocalContact(contactToRemove)

        XCTAssertTrue(manager.localContacts.isEmpty)
    }

    func testRemoveSpecificContact() {
        manager.addLocalContact(
            name: "Contact 1",
            phoneNumber: "555-0101",
            description: "First"
        )

        manager.addLocalContact(
            name: "Contact 2",
            phoneNumber: "555-0102",
            description: "Second"
        )

        guard let firstContact = manager.localContacts.first else {
            XCTFail("Contacts not added")
            return
        }

        manager.removeLocalContact(firstContact)

        XCTAssertEqual(manager.localContacts.count, 1)
        XCTAssertEqual(manager.localContacts.first?.name, "Contact 2")
    }

    // MARK: - Resources By Category Tests

    func testResourcesByCategoryIncludesLocal() {
        manager.addLocalContact(
            name: "Local Hospital",
            phoneNumber: "555-0100",
            description: "Local resource"
        )

        let byCategory = manager.resourcesByCategory

        XCTAssertNotNil(byCategory[.local])
        XCTAssertEqual(byCategory[.local]?.count, 1)
    }

    func testResourcesByCategoryPreservesDefaults() {
        let byCategory = manager.resourcesByCategory

        // Should have crisis resources
        XCTAssertNotNil(byCategory[.crisis])
        XCTAssertGreaterThan(byCategory[.crisis]?.count ?? 0, 0)

        // Should have autism resources
        XCTAssertNotNil(byCategory[.autism])
        XCTAssertGreaterThan(byCategory[.autism]?.count ?? 0, 0)
    }
}
