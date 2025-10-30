//
//  PerformanceMonitorTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure Tests
//

import XCTest
@testable import NeuroGuideApp

final class PerformanceMonitorTests: XCTestCase {

    var performanceMonitor: PerformanceMonitor!

    override func setUp() {
        super.setUp()
        performanceMonitor = PerformanceMonitor.shared
    }

    override func tearDown() {
        performanceMonitor.stopMonitoring()
        performanceMonitor = nil
        super.tearDown()
    }

    // MARK: - Monitoring Tests

    func testStartMonitoring() {
        performanceMonitor.startMonitoring()
        // Should not crash
        XCTAssertTrue(true)
    }

    func testStopMonitoring() {
        performanceMonitor.startMonitoring()
        performanceMonitor.stopMonitoring()
        // Should not crash
        XCTAssertTrue(true)
    }

    func testRecordInference() {
        performanceMonitor.startMonitoring()

        let metrics = ModelPerformanceMetrics(
            modelType: .test,
            inferenceLatency: 0.05,
            memoryUsage: 50 * 1024 * 1024,
            batteryImpact: 0.01
        )

        performanceMonitor.recordInference(metrics)

        // Check that metrics were recorded
        let latency = performanceMonitor.getInferenceLatency(modelType: .test)
        XCTAssertNotNil(latency)
        XCTAssertEqual(latency, 0.05, accuracy: 0.001)
    }

    // MARK: - Battery Impact Tests

    func testGetCurrentBatteryImpact() {
        performanceMonitor.startMonitoring()

        // Record some inferences
        for _ in 0..<10 {
            let metrics = ModelPerformanceMetrics(
                modelType: .test,
                inferenceLatency: 0.05,
                memoryUsage: 50 * 1024 * 1024,
                batteryImpact: 0.01
            )
            performanceMonitor.recordInference(metrics)
        }

        let batteryImpact = performanceMonitor.getCurrentBatteryImpact()
        XCTAssertGreaterThanOrEqual(batteryImpact, 0.0)
    }

    // MARK: - Memory Tests

    func testGetMemoryUsage() {
        let memoryUsage = performanceMonitor.getMemoryUsage()
        XCTAssertGreaterThan(memoryUsage, 0)
    }

    // MARK: - Performance Degradation Tests

    func testShouldDegradePerformance() {
        performanceMonitor.startMonitoring()
        let shouldDegrade = performanceMonitor.shouldDegradePerformance()
        // Should return true or false without crashing
        XCTAssertNotNil(shouldDegrade)
    }

    // MARK: - Statistics Tests

    func testGetStatistics() {
        performanceMonitor.startMonitoring()

        // Record multiple inferences
        for i in 0..<20 {
            let metrics = ModelPerformanceMetrics(
                modelType: .test,
                inferenceLatency: 0.05 + Double(i) * 0.001, // Varying latency
                memoryUsage: 50 * 1024 * 1024,
                batteryImpact: 0.01
            )
            performanceMonitor.recordInference(metrics)
        }

        let stats = performanceMonitor.getStatistics(for: .test)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.sampleCount, 20)
        XCTAssertGreaterThan(stats?.averageLatency ?? 0, 0)
        XCTAssertGreaterThan(stats?.p95Latency ?? 0, 0)
    }

    func testStatisticsTargetCompliance() {
        performanceMonitor.startMonitoring()

        // Record metrics that meet target
        for _ in 0..<10 {
            let metrics = ModelPerformanceMetrics(
                modelType: .test,
                inferenceLatency: 0.05, // Under 200ms target
                memoryUsage: 50 * 1024 * 1024,
                batteryImpact: 0.01
            )
            performanceMonitor.recordInference(metrics)
        }

        let stats = performanceMonitor.getStatistics(for: .test)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.targetComplianceRate, 100.0, accuracy: 0.1)
    }

    // MARK: - Alerts Tests

    func testGetActiveAlerts() {
        performanceMonitor.startMonitoring()
        let alerts = performanceMonitor.getActiveAlerts()
        // Should return an array (possibly empty)
        XCTAssertNotNil(alerts)
    }
}
