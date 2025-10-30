//
//  DeviceCapabilityServiceTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure Tests
//

import XCTest
@testable import NeuroGuideApp

final class DeviceCapabilityServiceTests: XCTestCase {

    var deviceCapability: DeviceCapabilityService!

    override func setUp() {
        super.setUp()
        deviceCapability = DeviceCapabilityManager.shared
    }

    override func tearDown() {
        deviceCapability = nil
        super.tearDown()
    }

    // MARK: - Device Info Tests

    func testGetDeviceInfo() {
        let deviceInfo = deviceCapability.getDeviceInfo()

        XCTAssertFalse(deviceInfo.modelIdentifier.isEmpty)
        XCTAssertFalse(deviceInfo.modelName.isEmpty)
        XCTAssertGreaterThan(deviceInfo.totalMemoryBytes, 0)
        XCTAssertGreaterThan(deviceInfo.cpuCoreCount, 0)
    }

    func testGetDeviceModel() {
        let model = deviceCapability.getDeviceModel()
        XCTAssertFalse(model.isEmpty, "Device model should not be empty")
    }

    func testSupportsNeuralEngine() {
        let hasNeuralEngine = deviceCapability.supportsNeuralEngine()
        // Should return true or false (no crash)
        XCTAssertNotNil(hasNeuralEngine)
    }

    func testGetPerformanceTier() {
        let tier = deviceCapability.getPerformanceTier()
        XCTAssertTrue([.high, .medium, .low].contains(tier))
    }

    func testGetDeviceFamily() {
        let family = deviceCapability.getDeviceFamily()
        // Should be iPhone, iPad, or simulator
        XCTAssertNotNil(family)
    }

    // MARK: - Recommended Model Quality Tests

    func testGetRecommendedModelQuality() {
        let quality = deviceCapability.getRecommendedModelQuality()
        XCTAssertTrue([.high, .medium, .low].contains(quality))
    }

    // MARK: - Model Requirements Tests

    func testCanRunModel() {
        let requirements = ModelRequirements.test
        let canRun = deviceCapability.canRunModel(requirements: requirements)
        // Should be able to run test model on any device
        XCTAssertTrue(canRun)
    }

    func testCanRunModelWithHighRequirements() {
        let requirements = ModelRequirements(
            minimumIOSVersion: OperatingSystemVersion(majorVersion: 99, minorVersion: 0, patchVersion: 0),
            requiresNeuralEngine: true,
            minimumMemoryBytes: 1024 * 1024 * 1024 * 100, // 100GB (impossible)
            modelSizeBytes: 1024 * 1024 * 1024,
            recommendedQuality: .high,
            requiresGPU: true,
            expectedInferenceFrequency: 1.0
        )

        let canRun = deviceCapability.canRunModel(requirements: requirements)
        XCTAssertFalse(canRun, "Should not be able to run impossible requirements")
    }

    // MARK: - Minimum Requirements Tests

    func testMeetsMinimumRequirements() {
        let meets = deviceCapability.meetsMinimumRequirements()
        // Should meet minimum requirements on any test device/simulator
        XCTAssertTrue(meets)
    }

    // MARK: - Memory Tests

    func testGetTotalMemory() {
        let totalMemory = deviceCapability.getTotalMemory()
        XCTAssertGreaterThan(totalMemory, 0)
        XCTAssertGreaterThan(totalMemory, 1024 * 1024 * 500) // At least 500MB
    }

    func testGetAvailableMemory() {
        let availableMemory = deviceCapability.getAvailableMemory()
        XCTAssertGreaterThan(availableMemory, 0)
    }

    func testAvailableMemoryLessThanTotal() {
        let total = deviceCapability.getTotalMemory()
        let available = deviceCapability.getAvailableMemory()
        XCTAssertLessThanOrEqual(available, total)
    }
}
