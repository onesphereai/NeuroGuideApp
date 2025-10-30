//
//  EmotionExpressionProfile.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation

/// Neurodivergent-aware emotion expression profile
/// Helps model understand how this child uniquely expresses emotions
struct EmotionExpressionProfile: Codable, Equatable {
    let childID: UUID

    // MARK: - General Expression Patterns

    /// Child has flat affect (less visible facial expressions)
    var hasFlatAffect: Bool

    /// Child uses echolalia or scripting
    var usesEcholalia: Bool

    /// Child stims when happy/excited
    var stimsWhenHappy: Bool

    /// Child stims when distressed/overwhelmed
    var stimsWhenDistressed: Bool

    /// Child has alexithymia (difficulty identifying own emotions)
    var hasAlexithymia: Bool

    /// Child is non-speaking or minimally speaking
    var isNonSpeaking: Bool

    // MARK: - Emotion-Specific Expressions

    /// How child typically shows joy (free text)
    var joyExpressions: [String]

    /// How child typically shows calm (free text)
    var calmExpressions: [String]

    /// How child typically shows frustration (free text)
    var frustrationExpressions: [String]

    /// How child typically shows overwhelm (free text)
    var overwhelmExpressions: [String]

    /// How child typically shows focus (free text)
    var focusedExpressions: [String]

    /// How child shows dysregulation (free text)
    var dysregulatedExpressions: [String]

    // MARK: - Initialization

    init(
        childID: UUID,
        hasFlatAffect: Bool = false,
        usesEcholalia: Bool = false,
        stimsWhenHappy: Bool = false,
        stimsWhenDistressed: Bool = false,
        hasAlexithymia: Bool = false,
        isNonSpeaking: Bool = false,
        joyExpressions: [String] = [],
        calmExpressions: [String] = [],
        frustrationExpressions: [String] = [],
        overwhelmExpressions: [String] = [],
        focusedExpressions: [String] = [],
        dysregulatedExpressions: [String] = []
    ) {
        self.childID = childID
        self.hasFlatAffect = hasFlatAffect
        self.usesEcholalia = usesEcholalia
        self.stimsWhenHappy = stimsWhenHappy
        self.stimsWhenDistressed = stimsWhenDistressed
        self.hasAlexithymia = hasAlexithymia
        self.isNonSpeaking = isNonSpeaking
        self.joyExpressions = joyExpressions
        self.calmExpressions = calmExpressions
        self.frustrationExpressions = frustrationExpressions
        self.overwhelmExpressions = overwhelmExpressions
        self.focusedExpressions = focusedExpressions
        self.dysregulatedExpressions = dysregulatedExpressions
    }

    // MARK: - Computed Properties

    /// Whether profile has been set up (at least one field filled)
    var isComplete: Bool {
        return hasFlatAffect ||
               usesEcholalia ||
               stimsWhenHappy ||
               stimsWhenDistressed ||
               hasAlexithymia ||
               isNonSpeaking ||
               !joyExpressions.isEmpty ||
               !calmExpressions.isEmpty ||
               !frustrationExpressions.isEmpty ||
               !overwhelmExpressions.isEmpty ||
               !focusedExpressions.isEmpty ||
               !dysregulatedExpressions.isEmpty
    }

    /// Get expressions for a specific emotion
    func getExpressions(for emotion: EmotionLabel) -> [String] {
        switch emotion {
        case .joy:
            return joyExpressions
        case .calm:
            return calmExpressions
        case .frustration:
            return frustrationExpressions
        case .overwhelm:
            return overwhelmExpressions
        case .focused:
            return focusedExpressions
        case .dysregulated:
            return dysregulatedExpressions
        }
    }

    /// Add expression for an emotion
    mutating func addExpression(_ expression: String, for emotion: EmotionLabel) {
        switch emotion {
        case .joy:
            joyExpressions.append(expression)
        case .calm:
            calmExpressions.append(expression)
        case .frustration:
            frustrationExpressions.append(expression)
        case .overwhelm:
            overwhelmExpressions.append(expression)
        case .focused:
            focusedExpressions.append(expression)
        case .dysregulated:
            dysregulatedExpressions.append(expression)
        }
    }

    /// Remove expression for an emotion
    mutating func removeExpression(_ expression: String, for emotion: EmotionLabel) {
        switch emotion {
        case .joy:
            joyExpressions.removeAll { $0 == expression }
        case .calm:
            calmExpressions.removeAll { $0 == expression }
        case .frustration:
            frustrationExpressions.removeAll { $0 == expression }
        case .overwhelm:
            overwhelmExpressions.removeAll { $0 == expression }
        case .focused:
            focusedExpressions.removeAll { $0 == expression }
        case .dysregulated:
            dysregulatedExpressions.removeAll { $0 == expression }
        }
    }

    // MARK: - Model Adjustments

    /// Adjustment factor for flat affect
    /// Returns lower confidence threshold for facial expressions
    var flatAffectAdjustment: Double {
        return hasFlatAffect ? 0.7 : 1.0  // 30% lower threshold
    }

    /// Whether stimming should be considered for emotion detection
    var shouldDetectStimming: Bool {
        return stimsWhenHappy || stimsWhenDistressed
    }

    /// Whether vocal analysis should be weighted differently
    var vocalAnalysisWeight: Double {
        if isNonSpeaking {
            return 0.0  // Don't use vocal analysis
        } else if usesEcholalia {
            return 0.5  // Reduced weight
        } else {
            return 1.0  // Normal weight
        }
    }
}

/// Common emotion expression patterns (suggestions for parents)
struct CommonExpressionPatterns {
    static let joy: [String] = [
        "Smiling or laughing",
        "Flapping hands or jumping",
        "Increased vocal volume",
        "Seeking proximity to preferred people",
        "Repetitive movements (stimming)"
    ]

    static let calm: [String] = [
        "Relaxed body posture",
        "Steady breathing",
        "Engaged in preferred activity",
        "Minimal facial expression (can be calm!)",
        "Self-soothing behaviors"
    ]

    static let frustration: [String] = [
        "Furrowed brow",
        "Clenched fists or jaw",
        "Increased vocal volume or tone",
        "Repetitive questioning",
        "Rigid body posture"
    ]

    static let overwhelm: [String] = [
        "Covering ears or eyes",
        "Withdrawing from interaction",
        "Increased stimming",
        "Seeking sensory input (pressure, movement)",
        "Shutting down or becoming very quiet"
    ]

    static let focused: [String] = [
        "Intense concentration on activity",
        "Minimal response to interruptions",
        "Steady body posture",
        "May appear 'zoned out' but is engaged",
        "Self-soothing movements while concentrating"
    ]

    static let dysregulated: [String] = [
        "Difficulty transitioning between activities",
        "Extreme emotional responses",
        "Physical dysregulation (pacing, rocking intensely)",
        "Sensory seeking or avoiding behaviors",
        "May appear distressed but can't communicate why"
    ]

    static func getSuggestions(for emotion: EmotionLabel) -> [String] {
        switch emotion {
        case .joy:
            return joy
        case .calm:
            return calm
        case .frustration:
            return frustration
        case .overwhelm:
            return overwhelm
        case .focused:
            return focused
        case .dysregulated:
            return dysregulated
        }
    }
}
