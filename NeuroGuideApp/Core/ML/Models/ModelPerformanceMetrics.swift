//
//  ModelPerformanceMetrics.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation

/// Performance metrics for ML model inference
struct ModelPerformanceMetrics {

    // MARK: - Properties

    /// Type of model these metrics apply to
    let modelType: MLModelType

    /// Inference latency in seconds
    let inferenceLatency: TimeInterval

    /// Memory usage in bytes
    let memoryUsage: Int64

    /// Estimated battery impact as percentage (0.0 to 100.0)
    let batteryImpact: Double

    /// Timestamp when metrics were captured
    let timestamp: Date

    /// Whether the inference met the latency target
    var meetsLatencyTarget: Bool {
        return inferenceLatency <= modelType.latencyTarget
    }

    /// Memory usage in megabytes
    var memoryUsageMB: Double {
        return Double(memoryUsage) / 1_048_576.0 // Convert bytes to MB
    }

    /// Latency in milliseconds
    var latencyMs: Double {
        return inferenceLatency * 1000.0
    }

    // MARK: - Initialization

    init(
        modelType: MLModelType,
        inferenceLatency: TimeInterval,
        memoryUsage: Int64,
        batteryImpact: Double,
        timestamp: Date = Date()
    ) {
        self.modelType = modelType
        self.inferenceLatency = inferenceLatency
        self.memoryUsage = memoryUsage
        self.batteryImpact = batteryImpact
        self.timestamp = timestamp
    }
}

/// Aggregated performance statistics
struct PerformanceStatistics {

    // MARK: - Properties

    /// Model type
    let modelType: MLModelType

    /// Number of inferences included in statistics
    let sampleCount: Int

    /// Average latency
    let averageLatency: TimeInterval

    /// Median latency
    let medianLatency: TimeInterval

    /// 95th percentile latency
    let p95Latency: TimeInterval

    /// Maximum latency observed
    let maxLatency: TimeInterval

    /// Minimum latency observed
    let minLatency: TimeInterval

    /// Average memory usage in bytes
    let averageMemoryUsage: Int64

    /// Peak memory usage in bytes
    let peakMemoryUsage: Int64

    /// Total battery impact
    let totalBatteryImpact: Double

    /// Percentage of inferences that met latency target
    var targetComplianceRate: Double {
        return (Double(inferencesMetTarget) / Double(sampleCount)) * 100.0
    }

    /// Number of inferences that met target
    let inferencesMetTarget: Int

    // MARK: - Computed Properties

    /// Average latency in milliseconds
    var averageLatencyMs: Double {
        return averageLatency * 1000.0
    }

    /// P95 latency in milliseconds
    var p95LatencyMs: Double {
        return p95Latency * 1000.0
    }

    /// Average memory in megabytes
    var averageMemoryMB: Double {
        return Double(averageMemoryUsage) / 1_048_576.0
    }

    /// Peak memory in megabytes
    var peakMemoryMB: Double {
        return Double(peakMemoryUsage) / 1_048_576.0
    }
}

/// Performance alert types
enum PerformanceAlert: Equatable {
    case latencyExceeded(modelType: MLModelType, actual: TimeInterval, target: TimeInterval)
    case highMemoryUsage(modelType: MLModelType, usageMB: Double)
    case excessiveBatteryDrain(percentPer30Min: Double)
    case performanceDegradation(modelType: MLModelType, reason: String)

    var severity: AlertSeverity {
        switch self {
        case .latencyExceeded:
            return .warning
        case .highMemoryUsage:
            return .warning
        case .excessiveBatteryDrain:
            return .critical
        case .performanceDegradation:
            return .info
        }
    }

    var message: String {
        switch self {
        case .latencyExceeded(let modelType, let actual, let target):
            return "\(modelType.displayName) latency exceeded: \(Int(actual * 1000))ms (target: \(Int(target * 1000))ms)"
        case .highMemoryUsage(let modelType, let usageMB):
            return "\(modelType.displayName) high memory usage: \(String(format: "%.1f", usageMB))MB"
        case .excessiveBatteryDrain(let percent):
            return "Battery drain exceeds target: \(String(format: "%.1f", percent))% per 30min"
        case .performanceDegradation(let modelType, let reason):
            return "\(modelType.displayName) degraded: \(reason)"
        }
    }
}

enum AlertSeverity {
    case info
    case warning
    case critical
}
