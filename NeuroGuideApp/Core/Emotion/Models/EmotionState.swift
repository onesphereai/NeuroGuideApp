//
//  EmotionState.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation
import SwiftUI

/// Six emotion states recognized by NeuroGuide
/// Neurodiversity-affirming, non-diagnostic labels
enum EmotionLabel: String, Codable, CaseIterable {
    case joy = "joy"
    case calm = "calm"
    case frustration = "frustration"
    case overwhelm = "overwhelm"
    case focused = "focused"
    case dysregulated = "dysregulated"

    var displayName: String {
        switch self {
        case .joy:
            return "Joy"
        case .calm:
            return "Calm"
        case .frustration:
            return "Frustration"
        case .overwhelm:
            return "Overwhelm"
        case .focused:
            return "Focused"
        case .dysregulated:
            return "Dysregulated"
        }
    }

    var description: String {
        switch self {
        case .joy:
            return "Happy, delighted, or excited"
        case .calm:
            return "Peaceful, relaxed, or content"
        case .frustration:
            return "Annoyed, irritated, or struggling"
        case .overwhelm:
            return "Too much to process, need a break"
        case .focused:
            return "Concentrating, engaged in activity"
        case .dysregulated:
            return "Difficulty self-regulating"
        }
    }

    /// Non-diagnostic phrasing for display
    var displayPhrase: String {
        switch self {
        case .joy:
            return "seems to be feeling joyful"
        case .calm:
            return "seems to be feeling calm"
        case .frustration:
            return "seems to be feeling frustrated"
        case .overwhelm:
            return "seems to be feeling overwhelmed"
        case .focused:
            return "seems to be focused"
        case .dysregulated:
            return "may be having difficulty regulating"
        }
    }

    var icon: String {
        switch self {
        case .joy:
            return "face.smiling"
        case .calm:
            return "leaf.fill"
        case .frustration:
            return "exclamationmark.triangle"
        case .overwhelm:
            return "exclamationmark.octagon"
        case .focused:
            return "eye.fill"
        case .dysregulated:
            return "waveform.path.ecg"
        }
    }

    var color: Color {
        switch self {
        case .joy:
            return .yellow
        case .calm:
            return .green
        case .frustration:
            return .orange
        case .overwhelm:
            return .red
        case .focused:
            return .blue
        case .dysregulated:
            return .purple
        }
    }
}

/// Emotion classification result from ML model
struct EmotionClassification: Codable, Equatable {
    let primary: EmotionLabel
    let secondary: EmotionLabel?
    let confidence: ConfidenceScore
    let timestamp: Date
    let features: EmotionFeatures?

    init(
        primary: EmotionLabel,
        secondary: EmotionLabel? = nil,
        confidence: ConfidenceScore,
        timestamp: Date = Date(),
        features: EmotionFeatures? = nil
    ) {
        self.primary = primary
        self.secondary = secondary
        self.confidence = confidence
        self.timestamp = timestamp
        self.features = features
    }

    /// Display text for UI (non-diagnostic)
    var displayText: String {
        if confidence.level == .low {
            return "Uncertain - trust your instincts"
        }

        if let secondary = secondary {
            return "Could be \(primary.displayName) or \(secondary.displayName)"
        }

        return "Child \(primary.displayPhrase)"
    }

    /// Multiple states are possible
    var hasMultipleStates: Bool {
        return secondary != nil
    }
}

/// Extracted features from facial expression analysis
struct EmotionFeatures: Codable, Equatable {
    let facialActionUnits: [Int: Double]?  // AU number -> intensity
    let expressionIntensity: Double         // 0-1
    let signalQuality: Double               // 0-1, clarity of detection
    let temporalStability: Double           // 0-1, consistency over time
    let mouthOpenness: Double               // 0-1, how open the mouth is
    let eyeOpenness: Double                 // 0-1, how open the eyes are
    let browPosition: Double                // 0-1, brow position (0=lowered, 1=raised)

    init(
        facialActionUnits: [Int: Double]? = nil,
        expressionIntensity: Double,
        signalQuality: Double,
        temporalStability: Double,
        mouthOpenness: Double,
        eyeOpenness: Double,
        browPosition: Double
    ) {
        self.facialActionUnits = facialActionUnits
        self.expressionIntensity = expressionIntensity
        self.signalQuality = signalQuality
        self.temporalStability = temporalStability
        self.mouthOpenness = mouthOpenness
        self.eyeOpenness = eyeOpenness
        self.browPosition = browPosition
    }

    /// Overall quality score for confidence calculation
    var qualityScore: Double {
        return (signalQuality + temporalStability) / 2.0
    }
}

/// Displayable emotion state for UI
struct DisplayableEmotionState {
    let classification: EmotionClassification
    let showValidationPrompt: Bool
    let lastValidation: Date?

    var displayText: String {
        return classification.displayText
    }

    var primaryEmotion: EmotionLabel {
        return classification.primary
    }

    var confidence: ConfidenceLevel {
        return classification.confidence.level
    }
}
