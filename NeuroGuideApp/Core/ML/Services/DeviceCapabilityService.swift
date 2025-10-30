//
//  DeviceCapabilityService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation

/// Protocol for detecting device capabilities and recommending ML model configurations
protocol DeviceCapabilityService {

    /// Get current device information
    func getDeviceInfo() -> DeviceInfo

    /// Get device model identifier (e.g., "iPhone14,2")
    func getDeviceModel() -> String

    /// Check if device supports Neural Engine
    func supportsNeuralEngine() -> Bool

    /// Get recommended model quality for current device
    func getRecommendedModelQuality() -> ModelQuality

    /// Check if device can run a model with given requirements
    func canRunModel(requirements: ModelRequirements) -> Bool

    /// Get device performance tier
    func getPerformanceTier() -> PerformanceTier

    /// Get device family (iPhone, iPad, etc.)
    func getDeviceFamily() -> DeviceFamily

    /// Check if device meets minimum requirements for NeuroGuide
    func meetsMinimumRequirements() -> Bool

    /// Get total device memory in bytes
    func getTotalMemory() -> Int64

    /// Get available device memory in bytes
    func getAvailableMemory() -> Int64
}
