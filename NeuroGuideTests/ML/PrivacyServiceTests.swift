//
//  PrivacyServiceTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure Tests
//

import XCTest
@testable import NeuroGuideApp

final class PrivacyServiceTests: XCTestCase {

    var privacyService: PrivacyServiceProtocol!

    override func setUp() {
        super.setUp()
        privacyService = PrivacyManager.shared
    }

    override func tearDown() {
        privacyService.stopNetworkMonitoring()
        privacyService = nil
        super.tearDown()
    }

    // MARK: - Privacy Status Tests

    func testIsDataProcessedLocally() {
        let isLocal = privacyService.isDataProcessedLocally()
        XCTAssertTrue(isLocal, "Data should be processed locally by default")
    }

    func testGetDataStorageLocation() {
        let location = privacyService.getDataStorageLocation()
        XCTAssertEqual(location, .local, "Data should be stored locally by default")
    }

    func testGetPrivacyStatus() {
        let status = privacyService.getPrivacyStatus()
        XCTAssertTrue(status.isProcessedLocally)
        XCTAssertEqual(status.storageLocation, .local)
    }

    func testShowPrivacyBadge() {
        let badge = privacyService.showPrivacyBadge()
        XCTAssertFalse(badge.isEmpty)
        XCTAssertTrue(badge.contains("Processing Locally") || badge.contains("Privacy"))
    }

    // MARK: - Privacy Verification Tests

    func testVerifyPrivacyStatus() {
        let result = privacyService.verifyPrivacyStatus()
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.complianceLevel)
        XCTAssertNotNil(result.status)
    }

    func testPrivacyVerificationCompliance() {
        let result = privacyService.verifyPrivacyStatus()
        // Should be fully compliant by default
        XCTAssertTrue(result.isPassing)
        XCTAssertEqual(result.complianceLevel, .full)
    }

    // MARK: - Network Monitoring Tests

    func testStartNetworkMonitoring() {
        privacyService.startNetworkMonitoring()
        // Should not crash
        XCTAssertTrue(true)
    }

    func testStopNetworkMonitoring() {
        privacyService.startNetworkMonitoring()
        privacyService.stopNetworkMonitoring()
        // Should not crash
        XCTAssertTrue(true)
    }

    func testWasNetworkActivityDetected() {
        privacyService.startNetworkMonitoring()
        let detected = privacyService.wasNetworkActivityDetected()
        // Should return false initially
        XCTAssertFalse(detected)
    }

    // MARK: - Storage Location Tests

    func testStorageLocationIsPrivacyCompliant() {
        let location = privacyService.getDataStorageLocation()
        XCTAssertTrue(location.isPrivacyCompliant)
    }
}
