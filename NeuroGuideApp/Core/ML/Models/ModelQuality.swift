//
//  ModelQuality.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation

/// Quality level for ML models (affects accuracy vs performance tradeoff)
enum ModelQuality: String, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    /// Human-readable description
    var displayName: String {
        switch self {
        case .high:
            return "High Quality"
        case .medium:
            return "Medium Quality"
        case .low:
            return "Low Quality"
        }
    }

    /// Description of what this quality level means
    var description: String {
        switch self {
        case .high:
            return "Full model with highest accuracy. Requires newer devices."
        case .medium:
            return "Quantized model with good accuracy. Works on most devices."
        case .low:
            return "Highly optimized model. Best for older devices."
        }
    }

    /// Expected accuracy relative to high quality (0.0 to 1.0)
    var relativeAccuracy: Double {
        switch self {
        case .high:
            return 1.0
        case .medium:
            return 0.95
        case .low:
            return 0.85
        }
    }

    /// Expected inference speedup relative to high quality
    var relativeSpeed: Double {
        switch self {
        case .high:
            return 1.0
        case .medium:
            return 1.3  // 30% faster
        case .low:
            return 1.8  // 80% faster
        }
    }

    /// Recommended minimum device
    var minimumDevice: String {
        switch self {
        case .high:
            return "iPhone 13+"
        case .medium:
            return "iPhone 12+"
        case .low:
            return "iPhone 11+"
        }
    }
}

/// Model format types
enum ModelFormat: String {
    case coreML = "mlmodel"
    case coreMLPackage = "mlpackage"
    case coreMLCompiled = "mlmodelc"

    var fileExtension: String {
        return self.rawValue
    }
}

/// Model optimization level
enum ModelOptimization: String {
    case float32 = "float32"     // Full precision
    case float16 = "float16"     // Half precision
    case int8 = "int8"          // 8-bit quantization
    case int4 = "int4"          // 4-bit quantization (aggressive)

    var displayName: String {
        switch self {
        case .float32:
            return "Full Precision (FP32)"
        case .float16:
            return "Half Precision (FP16)"
        case .int8:
            return "8-bit Quantized"
        case .int4:
            return "4-bit Quantized"
        }
    }

    /// Typical model size reduction
    var sizeReduction: Double {
        switch self {
        case .float32:
            return 1.0   // Baseline
        case .float16:
            return 0.5   // 50% smaller
        case .int8:
            return 0.25  // 75% smaller
        case .int4:
            return 0.125 // 87.5% smaller
        }
    }
}
