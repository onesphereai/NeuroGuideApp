//
//  ParentStateObservation.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System (Parent State Detection)
//

import Foundation

/// Parent emotional/regulatory state
enum ParentState: String, Codable, CaseIterable {
    case calm           // Regulated, calm presence
    case stressed       // Showing signs of stress/frustration
    case coRegulating   // Actively co-regulating with child
    case dysregulated   // Dysregulated, needs support

    var displayName: String {
        switch self {
        case .calm:
            return "Calm"
        case .stressed:
            return "Stressed"
        case .coRegulating:
            return "Co-Regulating"
        case .dysregulated:
            return "Dysregulated"
        }
    }

    var description: String {
        switch self {
        case .calm:
            return "Parent is calm and regulated"
        case .stressed:
            return "Parent showing signs of stress"
        case .coRegulating:
            return "Parent actively helping child regulate"
        case .dysregulated:
            return "Parent may need support"
        }
    }

    var icon: String {
        switch self {
        case .calm:
            return "figure.mind.and.body"
        case .stressed:
            return "exclamationmark.triangle"
        case .coRegulating:
            return "figure.2.and.child.holdinghands"
        case .dysregulated:
            return "exclamationmark.octagon"
        }
    }
}

/// Parent state observation recorded during session
struct ParentStateObservation: Identifiable, Codable, Equatable {
    let id: UUID
    let sessionID: UUID
    let timestamp: Date
    let state: ParentState
    let confidence: Double // 0-1
    let source: ObservationSource

    // Detected features
    let facialTension: Double?       // 0-1, facial muscle tension
    let vocalStress: Double?         // 0-1, stress in voice
    let bodyLanguage: Double?        // 0-1, body posture/movement
    let engagementLevel: Double?     // 0-1, engagement with child

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        timestamp: Date = Date(),
        state: ParentState,
        confidence: Double,
        source: ObservationSource,
        facialTension: Double? = nil,
        vocalStress: Double? = nil,
        bodyLanguage: Double? = nil,
        engagementLevel: Double? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.state = state
        self.confidence = confidence
        self.source = source
        self.facialTension = facialTension
        self.vocalStress = vocalStress
        self.bodyLanguage = bodyLanguage
        self.engagementLevel = engagementLevel
    }
}

/// Source of observation
enum ObservationSource: String, Codable {
    case mlModel        // ML model detection
    case manual         // Manual input
    case fallback       // Fallback/simulation
}

/// Parent state detection result
struct ParentStateClassification {
    let state: ParentState
    let confidence: Double
    let features: ParentStateFeatures
    let timestamp: Date

    init(
        state: ParentState,
        confidence: Double,
        features: ParentStateFeatures,
        timestamp: Date = Date()
    ) {
        self.state = state
        self.confidence = confidence
        self.features = features
        self.timestamp = timestamp
    }
}

/// Extracted features from parent video/audio
struct ParentStateFeatures {
    let facialTension: Double       // 0-1, detected from facial landmarks
    let vocalStress: Double         // 0-1, detected from voice
    let bodyLanguage: Double        // 0-1, detected from pose
    let engagementLevel: Double     // 0-1, attention/proximity to child

    /// Calculate overall stress level
    var stressLevel: Double {
        let weights: (facial: Double, vocal: Double, body: Double) = (0.4, 0.4, 0.2)

        let stress = (facialTension * weights.facial) +
                     (vocalStress * weights.vocal) +
                     (bodyLanguage * weights.body)

        return min(max(stress, 0.0), 1.0)
    }

    /// Determine if parent is actively engaging with child
    var isEngaging: Bool {
        return engagementLevel > 0.6
    }
}
