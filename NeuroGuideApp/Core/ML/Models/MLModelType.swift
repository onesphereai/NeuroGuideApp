//
//  MLModelType.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation

/// Types of ML models supported by NeuroGuide
enum MLModelType: String, CaseIterable {
    case poseDetection = "pose_detection"
    case vocalAffect = "vocal_affect"
    case facialExpression = "facial_expression"
    case parentStress = "parent_stress"
    case test = "test_model"

    /// Human-readable name for the model
    var displayName: String {
        switch self {
        case .poseDetection:
            return "Pose Detection"
        case .vocalAffect:
            return "Vocal Affect Analysis"
        case .facialExpression:
            return "Facial Expression"
        case .parentStress:
            return "Parent Stress Detection"
        case .test:
            return "Test Model"
        }
    }

    /// Expected inference latency target in milliseconds
    var latencyTarget: TimeInterval {
        switch self {
        case .poseDetection:
            return 0.050 // 50ms
        case .vocalAffect:
            return 0.100 // 100ms
        case .facialExpression:
            return 0.200 // 200ms
        case .parentStress:
            return 0.200 // 200ms
        case .test:
            return 0.200 // 200ms
        }
    }

    /// Model file name (without extension)
    var modelFileName: String {
        switch self {
        case .poseDetection:
            return "PoseDetectionModel"
        case .vocalAffect:
            return "VocalAffectModel"
        case .facialExpression:
            return "FacialExpressionModel"
        case .parentStress:
            return "ParentStressModel"
        case .test:
            return "MobileNetV2" // Test model
        }
    }

    /// Whether this model is currently available
    var isAvailable: Bool {
        // For now, only test model is available
        // Other models will be added in future bolts
        switch self {
        case .test:
            return true
        case .poseDetection, .vocalAffect, .facialExpression, .parentStress:
            return false // Will be implemented in future bolts
        }
    }
}

/// Categories for grouping models
enum MLModelCategory: String {
    case movement = "Movement Analysis"
    case audio = "Audio Analysis"
    case visual = "Visual Analysis"
    case multimodal = "Multimodal Analysis"
    case testing = "Testing & Validation"

    /// Models in this category
    func models() -> [MLModelType] {
        switch self {
        case .movement:
            return [.poseDetection]
        case .audio:
            return [.vocalAffect]
        case .visual:
            return [.facialExpression]
        case .multimodal:
            return [.parentStress]
        case .testing:
            return [.test]
        }
    }
}
