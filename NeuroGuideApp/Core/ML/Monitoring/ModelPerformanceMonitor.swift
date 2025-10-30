//
//  ModelPerformanceMonitor.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation
import Combine

/// Protocol for monitoring ML model performance
protocol ModelPerformanceMonitorProtocol {

    /// Start monitoring performance
    func startMonitoring()

    /// Stop monitoring performance
    func stopMonitoring()

    /// Record an inference event
    /// - Parameter metrics: Performance metrics from the inference
    func recordInference(_ metrics: ModelPerformanceMetrics)

    /// Get current battery impact estimate (percentage per 30 minutes)
    func getCurrentBatteryImpact() -> Double

    /// Get inference latency for a specific model type
    /// - Parameter modelType: The model type to query
    /// - Returns: Latest inference latency
    func getInferenceLatency(modelType: MLModelType) -> TimeInterval?

    /// Get memory usage for current ML operations
    /// - Returns: Memory usage in bytes
    func getMemoryUsage() -> Int64

    /// Check if performance degradation is recommended
    /// - Returns: True if app should degrade performance (e.g., lower frame rate)
    func shouldDegradePerformance() -> Bool

    /// Get performance statistics for a model
    /// - Parameter modelType: The model type to query
    /// - Returns: Aggregated statistics
    func getStatistics(for modelType: MLModelType) -> PerformanceStatistics?

    /// Get all active performance alerts
    /// - Returns: Array of current alerts
    func getActiveAlerts() -> [PerformanceAlert]

    /// Publisher for performance alerts
    var alertPublisher: AnyPublisher<PerformanceAlert, Never> { get }
}
