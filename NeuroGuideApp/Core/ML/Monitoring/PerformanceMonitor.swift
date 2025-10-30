//
//  PerformanceMonitor.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation
import Combine
import UIKit

/// Implementation of ModelPerformanceMonitor
class PerformanceMonitor: ModelPerformanceMonitorProtocol {

    // MARK: - Singleton

    static let shared = PerformanceMonitor()

    // MARK: - Private Properties

    private var isMonitoring = false
    private var metricsHistory: [MLModelType: [ModelPerformanceMetrics]] = [:]
    private var historyLock = NSLock()
    private let maxHistorySize = 100 // Keep last 100 inferences per model
    private var startTime: Date?
    private var totalBatteryImpact: Double = 0.0
    private let alertSubject = PassthroughSubject<PerformanceAlert, Never>()
    private var activeAlerts: Set<PerformanceAlert> = []

    // Battery impact target: < 10% per 30 minutes
    private let batteryImpactTarget: Double = 10.0

    // Memory threshold for degradation: 500MB
    private let memoryDegradationThreshold: Int64 = 500 * 1024 * 1024

    // MARK: - Public Properties

    var alertPublisher: AnyPublisher<PerformanceAlert, Never> {
        return alertSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        startTime = Date()
        totalBatteryImpact = 0.0
        metricsHistory.removeAll()
        activeAlerts.removeAll()

        print("📊 Performance monitoring started")
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        isMonitoring = false

        // Print summary
        if let start = startTime {
            let duration = Date().timeIntervalSince(start)
            let batteryPer30Min = (totalBatteryImpact / duration) * 1800 // Extrapolate to 30 min
            print("📊 Performance monitoring stopped")
            print("   Duration: \(String(format: "%.1f", duration))s")
            print("   Battery impact: \(String(format: "%.2f", batteryPer30Min))% per 30min")
        }
    }

    func recordInference(_ metrics: ModelPerformanceMetrics) {
        guard isMonitoring else { return }

        historyLock.lock()
        defer { historyLock.unlock() }

        // Add to history
        var history = metricsHistory[metrics.modelType] ?? []
        history.append(metrics)

        // Keep only recent history
        if history.count > maxHistorySize {
            history.removeFirst(history.count - maxHistorySize)
        }

        metricsHistory[metrics.modelType] = history

        // Update battery impact
        totalBatteryImpact += metrics.batteryImpact

        // Check for alerts
        checkForAlerts(metrics: metrics)
    }

    func getCurrentBatteryImpact() -> Double {
        guard let start = startTime else { return 0.0 }

        let duration = Date().timeIntervalSince(start)
        guard duration > 0 else { return 0.0 }

        // Extrapolate to 30 minutes
        return (totalBatteryImpact / duration) * 1800
    }

    func getInferenceLatency(modelType: MLModelType) -> TimeInterval? {
        historyLock.lock()
        defer { historyLock.unlock() }

        return metricsHistory[modelType]?.last?.inferenceLatency
    }

    func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    func shouldDegradePerformance() -> Bool {
        // Check battery impact
        let batteryImpact = getCurrentBatteryImpact()
        if batteryImpact > batteryImpactTarget * 1.5 { // 15% per 30min
            return true
        }

        // Check memory usage
        let memoryUsage = getMemoryUsage()
        if memoryUsage > memoryDegradationThreshold {
            return true
        }

        // Check battery level
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel < 0.2 { // Less than 20%
            return true
        }

        return false
    }

    func getStatistics(for modelType: MLModelType) -> PerformanceStatistics? {
        historyLock.lock()
        defer { historyLock.unlock() }

        guard let history = metricsHistory[modelType], !history.isEmpty else {
            return nil
        }

        // Calculate statistics
        let latencies = history.map { $0.inferenceLatency }.sorted()
        let memoryUsages = history.map { $0.memoryUsage }

        let averageLatency = latencies.reduce(0, +) / Double(latencies.count)
        let medianLatency = latencies[latencies.count / 2]
        let p95Index = Int(Double(latencies.count) * 0.95)
        let p95Latency = latencies[min(p95Index, latencies.count - 1)]
        let maxLatency = latencies.last ?? 0
        let minLatency = latencies.first ?? 0

        let averageMemory = memoryUsages.reduce(0, +) / Int64(memoryUsages.count)
        let peakMemory = memoryUsages.max() ?? 0

        let totalBattery = history.map { $0.batteryImpact }.reduce(0, +)
        let meetsTarget = history.filter { $0.meetsLatencyTarget }.count

        return PerformanceStatistics(
            modelType: modelType,
            sampleCount: history.count,
            averageLatency: averageLatency,
            medianLatency: medianLatency,
            p95Latency: p95Latency,
            maxLatency: maxLatency,
            minLatency: minLatency,
            averageMemoryUsage: averageMemory,
            peakMemoryUsage: peakMemory,
            totalBatteryImpact: totalBattery,
            inferencesMetTarget: meetsTarget
        )
    }

    func getActiveAlerts() -> [PerformanceAlert] {
        return Array(activeAlerts)
    }

    // MARK: - Private Methods

    private func checkForAlerts(metrics: ModelPerformanceMetrics) {
        // Check latency
        if !metrics.meetsLatencyTarget {
            let alert = PerformanceAlert.latencyExceeded(
                modelType: metrics.modelType,
                actual: metrics.inferenceLatency,
                target: metrics.modelType.latencyTarget
            )
            addAlert(alert)
        }

        // Check memory
        if metrics.memoryUsageMB > 100 { // > 100MB
            let alert = PerformanceAlert.highMemoryUsage(
                modelType: metrics.modelType,
                usageMB: metrics.memoryUsageMB
            )
            addAlert(alert)
        }

        // Check battery
        let batteryPer30Min = getCurrentBatteryImpact()
        if batteryPer30Min > batteryImpactTarget {
            let alert = PerformanceAlert.excessiveBatteryDrain(percentPer30Min: batteryPer30Min)
            addAlert(alert)
        }

        // Check for degradation recommendation
        if shouldDegradePerformance() {
            let alert = PerformanceAlert.performanceDegradation(
                modelType: metrics.modelType,
                reason: "High resource usage detected"
            )
            addAlert(alert)
        }
    }

    private func addAlert(_ alert: PerformanceAlert) {
        if !activeAlerts.contains(alert) {
            activeAlerts.insert(alert)
            alertSubject.send(alert)
            print("⚠️ Performance Alert: \(alert.message)")
        }
    }
}

// Make PerformanceAlert hashable for Set
extension PerformanceAlert: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(message)
    }
}
