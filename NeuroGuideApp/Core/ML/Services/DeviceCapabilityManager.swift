//
//  DeviceCapabilityManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation
import UIKit

/// Implementation of DeviceCapabilityService
class DeviceCapabilityManager: DeviceCapabilityService {

    // MARK: - Singleton

    static let shared = DeviceCapabilityManager()

    // MARK: - Private Properties

    private var cachedDeviceInfo: DeviceInfo?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func getDeviceInfo() -> DeviceInfo {
        if let cached = cachedDeviceInfo {
            return cached
        }

        let info = DeviceInfo(
            modelIdentifier: getDeviceModel(),
            modelName: getDeviceModelName(),
            iosVersion: getIOSVersion(),
            hasNeuralEngine: supportsNeuralEngine(),
            totalMemoryBytes: getTotalMemory(),
            availableMemoryBytes: getAvailableMemory(),
            processorType: getProcessorType(),
            cpuCoreCount: getCPUCoreCount(),
            supportsGPU: true, // All iOS devices support Metal/GPU
            performanceTier: getPerformanceTier()
        )

        cachedDeviceInfo = info
        return info
    }

    func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    func supportsNeuralEngine() -> Bool {
        let modelIdentifier = getDeviceModel()

        // Neural Engine available on A11 Bionic and newer (iPhone 8 and later)
        // For NeuroGuide, we target A13 (iPhone 11) and newer
        if modelIdentifier.hasPrefix("iPhone") {
            // Extract major version number
            if let versionString = modelIdentifier.components(separatedBy: "iPhone").last,
               let majorVersion = Int(versionString.components(separatedBy: ",").first ?? "") {
                // iPhone 11 (A13) is iPhone12,x
                // iPhone 12 (A14) is iPhone13,x
                // iPhone 13 (A15) is iPhone14,x
                return majorVersion >= 12
            }
        }

        // For simulator, assume Neural Engine support
        if modelIdentifier.contains("x86_64") || modelIdentifier.contains("arm64") {
            return true
        }

        return false
    }

    func getRecommendedModelQuality() -> ModelQuality {
        let tier = getPerformanceTier()
        return tier == .high ? .high : (tier == .medium ? .medium : .low)
    }

    func canRunModel(requirements: ModelRequirements) -> Bool {
        let deviceInfo = getDeviceInfo()

        // Check iOS version
        let currentVersion = deviceInfo.iosVersion
        let requiredVersion = requirements.minimumIOSVersion
        if currentVersion.majorVersion < requiredVersion.majorVersion {
            return false
        }
        if currentVersion.majorVersion == requiredVersion.majorVersion &&
           currentVersion.minorVersion < requiredVersion.minorVersion {
            return false
        }

        // Check Neural Engine requirement
        if requirements.requiresNeuralEngine && !deviceInfo.hasNeuralEngine {
            return false
        }

        // Check memory requirement
        if deviceInfo.availableMemoryBytes < requirements.minimumMemoryBytes {
            return false
        }

        // Check GPU requirement
        if requirements.requiresGPU && !deviceInfo.supportsGPU {
            return false
        }

        return true
    }

    func getPerformanceTier() -> PerformanceTier {
        let modelIdentifier = getDeviceModel()

        if modelIdentifier.hasPrefix("iPhone") {
            if let versionString = modelIdentifier.components(separatedBy: "iPhone").last,
               let majorVersion = Int(versionString.components(separatedBy: ",").first ?? "") {
                // iPhone 13+ (A15 or newer): High
                if majorVersion >= 14 {
                    return .high
                }
                // iPhone 12 (A14): Medium
                else if majorVersion == 13 {
                    return .medium
                }
                // iPhone 11 (A13): Low but acceptable
                else if majorVersion == 12 {
                    return .low
                }
            }
        }

        // For simulator or unknown, assume medium tier
        return .medium
    }

    func getDeviceFamily() -> DeviceFamily {
        let modelIdentifier = getDeviceModel()

        if modelIdentifier.hasPrefix("iPhone") {
            return .iPhone
        } else if modelIdentifier.hasPrefix("iPad") {
            return .iPad
        } else if modelIdentifier.hasPrefix("iPod") {
            return .iPodTouch
        } else if modelIdentifier.contains("x86_64") || modelIdentifier.contains("arm64") {
            return .simulator
        }

        return .unknown
    }

    func meetsMinimumRequirements() -> Bool {
        let deviceInfo = getDeviceInfo()

        // Minimum: iPhone 11 (A13), iOS 15+
        if deviceInfo.iosVersion.majorVersion < 15 {
            return false
        }

        let tier = deviceInfo.performanceTier
        return tier == .high || tier == .medium || tier == .low
    }

    func getTotalMemory() -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }

    func getAvailableMemory() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let totalMemory = getTotalMemory()
            let usedMemory = Int64(info.resident_size)
            return max(0, totalMemory - usedMemory)
        }

        // Fallback: assume 500MB available
        return 500 * 1024 * 1024
    }

    // MARK: - Private Methods

    private func getDeviceModelName() -> String {
        let identifier = getDeviceModel()

        // Map identifiers to human-readable names
        let modelMap: [String: String] = [
            // iPhone 11 series (A13)
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone12,8": "iPhone SE (2nd gen)",

            // iPhone 12 series (A14)
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",

            // iPhone 13 series (A15)
            "iPhone14,2": "iPhone 13",
            "iPhone14,3": "iPhone 13 Pro",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13 Pro Max",
            "iPhone14,6": "iPhone SE (3rd gen)",

            // iPhone 14 series (A15/A16)
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",

            // iPhone 15 series (A16/A17)
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",

            // Simulator
            "x86_64": "Simulator (Intel)",
            "arm64": "Simulator (Apple Silicon)"
        ]

        return modelMap[identifier] ?? identifier
    }

    private func getIOSVersion() -> OperatingSystemVersion {
        return ProcessInfo.processInfo.operatingSystemVersion
    }

    private func getProcessorType() -> String {
        let modelIdentifier = getDeviceModel()

        if modelIdentifier.hasPrefix("iPhone") {
            if let versionString = modelIdentifier.components(separatedBy: "iPhone").last,
               let majorVersion = Int(versionString.components(separatedBy: ",").first ?? "") {
                // Map to processor types
                switch majorVersion {
                case 16...:
                    return "A17 Pro or newer"
                case 15:
                    return "A16 Bionic"
                case 14:
                    return "A15 Bionic"
                case 13:
                    return "A14 Bionic"
                case 12:
                    return "A13 Bionic"
                default:
                    return "A12 or older"
                }
            }
        }

        return "Unknown"
    }

    private func getCPUCoreCount() -> Int {
        return ProcessInfo.processInfo.activeProcessorCount
    }
}
