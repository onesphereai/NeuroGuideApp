//
//  ModelRequirements.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation

/// Requirements for running an ML model
struct ModelRequirements {

    // MARK: - Properties

    /// Minimum iOS version required
    let minimumIOSVersion: OperatingSystemVersion

    /// Whether Neural Engine is required
    let requiresNeuralEngine: Bool

    /// Minimum memory required in bytes
    let minimumMemoryBytes: Int64

    /// Expected model size in bytes
    let modelSizeBytes: Int64

    /// Recommended model quality for this device
    let recommendedQuality: ModelQuality

    /// Whether GPU acceleration is required
    let requiresGPU: Bool

    /// Expected inference frequency (inferences per second)
    let expectedInferenceFrequency: Double

    // MARK: - Computed Properties

    /// Minimum memory in megabytes
    var minimumMemoryMB: Double {
        return Double(minimumMemoryBytes) / 1_048_576.0
    }

    /// Model size in megabytes
    var modelSizeMB: Double {
        return Double(modelSizeBytes) / 1_048_576.0
    }

    // MARK: - Initialization

    init(
        minimumIOSVersion: OperatingSystemVersion = OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0),
        requiresNeuralEngine: Bool = false,
        minimumMemoryBytes: Int64 = 100 * 1024 * 1024, // 100MB default
        modelSizeBytes: Int64 = 10 * 1024 * 1024, // 10MB default
        recommendedQuality: ModelQuality = .medium,
        requiresGPU: Bool = false,
        expectedInferenceFrequency: Double = 1.0
    ) {
        self.minimumIOSVersion = minimumIOSVersion
        self.requiresNeuralEngine = requiresNeuralEngine
        self.minimumMemoryBytes = minimumMemoryBytes
        self.modelSizeBytes = modelSizeBytes
        self.recommendedQuality = recommendedQuality
        self.requiresGPU = requiresGPU
        self.expectedInferenceFrequency = expectedInferenceFrequency
    }

    // MARK: - Predefined Requirements

    /// Requirements for pose detection model
    static var poseDetection: ModelRequirements {
        return ModelRequirements(
            minimumIOSVersion: OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0),
            requiresNeuralEngine: false,
            minimumMemoryBytes: 50 * 1024 * 1024, // 50MB
            modelSizeBytes: 5 * 1024 * 1024, // 5MB
            recommendedQuality: .medium,
            requiresGPU: true,
            expectedInferenceFrequency: 20.0 // 20 fps
        )
    }

    /// Requirements for vocal affect model
    static var vocalAffect: ModelRequirements {
        return ModelRequirements(
            minimumIOSVersion: OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0),
            requiresNeuralEngine: false,
            minimumMemoryBytes: 30 * 1024 * 1024, // 30MB
            modelSizeBytes: 8 * 1024 * 1024, // 8MB
            recommendedQuality: .medium,
            requiresGPU: false,
            expectedInferenceFrequency: 10.0 // 10 Hz
        )
    }

    /// Requirements for facial expression model
    static var facialExpression: ModelRequirements {
        return ModelRequirements(
            minimumIOSVersion: OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0),
            requiresNeuralEngine: true,
            minimumMemoryBytes: 80 * 1024 * 1024, // 80MB
            modelSizeBytes: 15 * 1024 * 1024, // 15MB
            recommendedQuality: .high,
            requiresGPU: true,
            expectedInferenceFrequency: 5.0 // 5 fps
        )
    }

    /// Requirements for parent stress model
    static var parentStress: ModelRequirements {
        return ModelRequirements(
            minimumIOSVersion: OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0),
            requiresNeuralEngine: false,
            minimumMemoryBytes: 60 * 1024 * 1024, // 60MB
            modelSizeBytes: 12 * 1024 * 1024, // 12MB
            recommendedQuality: .medium,
            requiresGPU: false,
            expectedInferenceFrequency: 2.0 // 2 Hz
        )
    }

    /// Requirements for test model
    static var test: ModelRequirements {
        return ModelRequirements(
            minimumIOSVersion: OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0),
            requiresNeuralEngine: false,
            minimumMemoryBytes: 50 * 1024 * 1024, // 50MB
            modelSizeBytes: 10 * 1024 * 1024, // 10MB
            recommendedQuality: .medium,
            requiresGPU: false,
            expectedInferenceFrequency: 1.0 // 1 Hz
        )
    }
}
