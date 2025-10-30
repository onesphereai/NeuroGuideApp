//
//  ConfidenceLevel.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation
import SwiftUI

/// Confidence level for emotion predictions
/// Prevents over-trust by showing uncertainty
enum ConfidenceLevel: String, Codable, CaseIterable {
    case low = "low"           // <50%
    case medium = "medium"     // 50-75%
    case high = "high"         // >75%

    var displayName: String {
        switch self {
        case .low:
            return "Low Confidence"
        case .medium:
            return "Medium Confidence"
        case .high:
            return "High Confidence"
        }
    }

    var description: String {
        switch self {
        case .low:
            return "The model is uncertain. Trust your instincts."
        case .medium:
            return "The model is moderately confident."
        case .high:
            return "The model is confident in this prediction."
        }
    }

    var color: Color {
        switch self {
        case .low:
            return .gray
        case .medium:
            return .orange
        case .high:
            return .green
        }
    }

    var icon: String {
        switch self {
        case .low:
            return "questionmark.circle"
        case .medium:
            return "exclamationmark.circle"
        case .high:
            return "checkmark.circle"
        }
    }

    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        switch self {
        case .low:
            return "Low confidence - uncertain prediction"
        case .medium:
            return "Medium confidence - moderately certain"
        case .high:
            return "High confidence - confident prediction"
        }
    }

    /// Create confidence level from probability score
    static func from(probability: Double) -> ConfidenceLevel {
        if probability < 0.50 {
            return .low
        } else if probability < 0.75 {
            return .medium
        } else {
            return .high
        }
    }

    /// Create confidence level from quality metrics
    static func from(signalQuality: Double, temporalStability: Double, modelConfidence: Double) -> ConfidenceLevel {
        // Weighted combination
        let combined = (signalQuality * 0.3) + (temporalStability * 0.2) + (modelConfidence * 0.5)

        return from(probability: combined)
    }
}

/// Confidence score with detailed breakdown
struct ConfidenceScore: Codable, Equatable {
    let level: ConfidenceLevel
    let probability: Double          // 0-1
    let signalQuality: Double?       // 0-1, optional
    let temporalStability: Double?   // 0-1, optional
    let modelAgreement: Double?      // 0-1, optional

    init(
        level: ConfidenceLevel,
        probability: Double,
        signalQuality: Double? = nil,
        temporalStability: Double? = nil,
        modelAgreement: Double? = nil
    ) {
        self.level = level
        self.probability = probability
        self.signalQuality = signalQuality
        self.temporalStability = temporalStability
        self.modelAgreement = modelAgreement
    }

    /// Display text for UI
    var displayText: String {
        return level.displayName
    }

    /// Show warning for low confidence
    var shouldShowUncertaintyWarning: Bool {
        return level == .low
    }

    /// Message to show user
    var userMessage: String {
        if level == .low {
            return "I'm not sure about this. Trust your instincts - you know your child best!"
        } else if level == .medium {
            return "This is my best guess based on what I can see."
        } else {
            return "I'm confident in this prediction, but remember - you know your child best."
        }
    }
}
