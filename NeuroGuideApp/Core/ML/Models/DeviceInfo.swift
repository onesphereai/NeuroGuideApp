//
//  DeviceInfo.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation
import UIKit

/// Device capability information
struct DeviceInfo {

    // MARK: - Properties

    /// Device model identifier (e.g., "iPhone14,2")
    let modelIdentifier: String

    /// Human-readable device name (e.g., "iPhone 13 Pro")
    let modelName: String

    /// iOS version
    let iosVersion: OperatingSystemVersion

    /// Whether device has Neural Engine
    let hasNeuralEngine: Bool

    /// Total device memory in bytes
    let totalMemoryBytes: Int64

    /// Available memory in bytes
    let availableMemoryBytes: Int64

    /// Processor type (e.g., "A15 Bionic")
    let processorType: String

    /// Number of CPU cores
    let cpuCoreCount: Int

    /// Whether device supports GPU acceleration
    let supportsGPU: Bool

    /// Device performance tier
    let performanceTier: PerformanceTier

    // MARK: - Computed Properties

    /// Total memory in megabytes
    var totalMemoryMB: Double {
        return Double(totalMemoryBytes) / 1_048_576.0
    }

    /// Available memory in megabytes
    var availableMemoryMB: Double {
        return Double(availableMemoryBytes) / 1_048_576.0
    }

    /// iOS version as string
    var iosVersionString: String {
        return "\(iosVersion.majorVersion).\(iosVersion.minorVersion).\(iosVersion.patchVersion)"
    }

    /// Recommended model quality based on device capabilities
    var recommendedModelQuality: ModelQuality {
        switch performanceTier {
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }
}

/// Device performance tiers
enum PerformanceTier: String {
    case high = "high"       // iPhone 13+, A15 or newer
    case medium = "medium"   // iPhone 12, A14
    case low = "low"        // iPhone 11, A13

    var displayName: String {
        switch self {
        case .high:
            return "High Performance"
        case .medium:
            return "Medium Performance"
        case .low:
            return "Lower Performance"
        }
    }

    var description: String {
        switch self {
        case .high:
            return "Latest devices with optimal ML performance"
        case .medium:
            return "Recent devices with good ML performance"
        case .low:
            return "Older devices with acceptable ML performance"
        }
    }

    /// Typical devices in this tier
    var exampleDevices: [String] {
        switch self {
        case .high:
            return ["iPhone 13", "iPhone 14", "iPhone 15", "iPhone 16"]
        case .medium:
            return ["iPhone 12", "iPhone 12 Pro"]
        case .low:
            return ["iPhone 11", "iPhone 11 Pro"]
        }
    }
}

/// Device model families
enum DeviceFamily: String {
    case iPhone
    case iPad
    case iPodTouch
    case simulator
    case unknown

    var displayName: String {
        return self.rawValue
    }
}
