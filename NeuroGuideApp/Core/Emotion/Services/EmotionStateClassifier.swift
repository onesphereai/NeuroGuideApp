//
//  EmotionStateClassifier.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation
import CoreGraphics
import Combine

/// Classifies 6 emotion states from facial expressions
/// Neurodiversity-aware with profile-based adjustments
@MainActor
class EmotionStateClassifier: EmotionStateClassifierService, ObservableObject {
    // MARK: - Singleton

    static let shared = EmotionStateClassifier()

    // MARK: - Published Properties

    @Published private(set) var currentEmotion: EmotionClassification?
    @Published private(set) var emotionHistory: [EmotionClassification] = []

    // MARK: - Private Properties

    private let facialExpressionService: FacialExpressionService
    private let profileManager: EmotionProfileManager
    private let maxHistorySize = 10

    // MARK: - Initialization

    init(
        facialExpressionService: FacialExpressionService = .shared,
        profileManager: EmotionProfileManager = .shared
    ) {
        self.facialExpressionService = facialExpressionService
        self.profileManager = profileManager
    }

    // MARK: - EmotionStateClassifierService

    /// Classify emotion from image
    func classifyEmotion(from image: CGImage) async throws -> EmotionClassification {
        // Get facial expression analysis
        let expressionResult = try await facialExpressionService.detectExpression(in: image)

        // Classify emotion from expression
        let classification = classifyEmotionState(from: expressionResult.expression)

        // Update state
        currentEmotion = classification
        emotionHistory.append(classification)

        // Trim history
        if emotionHistory.count > maxHistorySize {
            emotionHistory.removeFirst()
        }

        return classification
    }

    /// Get current emotion state
    func getCurrentEmotion() -> EmotionClassification? {
        return currentEmotion
    }

    /// Clear emotion history
    func clearHistory() {
        emotionHistory.removeAll()
        currentEmotion = nil
    }

    // MARK: - Emotion Classification

    /// Classify emotion state from facial expression analysis
    private func classifyEmotionState(from expression: ExpressionAnalysis) -> EmotionClassification {
        // Extract features
        let features = EmotionFeatures(
            expressionIntensity: expression.overallIntensity,
            signalQuality: expression.faceConfidence,
            temporalStability: calculateTemporalStability() ?? 0.5,
            mouthOpenness: expression.mouthOpenness,
            eyeOpenness: expression.eyeOpenness,
            browPosition: expression.browPosition
        )

        // Calculate scores for each emotion
        let scores = calculateEmotionScores(features: features)

        // Find primary emotion (highest score)
        let sortedEmotions = scores.sorted { $0.value > $1.value }
        let primary = sortedEmotions[0].key
        let primaryScore = sortedEmotions[0].value

        // Secondary emotion if close
        var secondary: EmotionLabel?
        if sortedEmotions.count > 1 {
            let secondaryScore = sortedEmotions[1].value
            if abs(primaryScore - secondaryScore) < 0.15 {
                secondary = sortedEmotions[1].key
            }
        }

        // Determine confidence level
        let confidence = determineConfidence(
            primaryScore: primaryScore,
            allScores: scores,
            faceConfidence: expression.faceConfidence
        )

        return EmotionClassification(
            primary: primary,
            secondary: secondary,
            confidence: confidence,
            timestamp: Date(),
            features: features
        )
    }

    /// Calculate scores for all emotion states
    private func calculateEmotionScores(features: EmotionFeatures) -> [EmotionLabel: Double] {
        var scores: [EmotionLabel: Double] = [:]

        // Joy: Raised brows, open mouth, high intensity
        scores[.joy] = calculateJoyScore(features: features)

        // Calm: Neutral features, low intensity
        scores[.calm] = calculateCalmScore(features: features)

        // Frustration: Furrowed brows, moderate intensity
        scores[.frustration] = calculateFrustrationScore(features: features)

        // Overwhelm: Variable features, can show shutdown or high distress
        scores[.overwhelm] = calculateOverwhelmScore(features: features)

        // Focused: Steady features, minimal movement
        scores[.focused] = calculateFocusedScore(features: features)

        // Dysregulated: High intensity, extreme features
        scores[.dysregulated] = calculateDysregulatedScore(features: features)

        return scores
    }

    // MARK: - Emotion Score Calculations

    private func calculateJoyScore(features: EmotionFeatures) -> Double {
        var score = 0.0

        // Raised brows (happiness indicator)
        if features.browPosition > 0.6 {
            score += 0.3
        }

        // Open mouth (smiling/laughing)
        if features.mouthOpenness > 0.4 {
            score += 0.3
        }

        // Moderate to high intensity
        if features.expressionIntensity > 0.5 {
            score += 0.2
        }

        // Wide eyes (positive excitement)
        if features.eyeOpenness > 0.6 {
            score += 0.2
        }

        return min(score, 1.0)
    }

    private func calculateCalmScore(features: EmotionFeatures) -> Double {
        var score = 0.0

        // Low expression intensity (relaxed)
        if features.expressionIntensity < 0.4 {
            score += 0.4
        }

        // Neutral brows
        if features.browPosition > 0.4 && features.browPosition < 0.6 {
            score += 0.3
        }

        // Relaxed mouth
        if features.mouthOpenness < 0.3 {
            score += 0.2
        }

        // Normal eye openness
        if features.eyeOpenness > 0.4 && features.eyeOpenness < 0.7 {
            score += 0.1
        }

        return min(score, 1.0)
    }

    private func calculateFrustrationScore(features: EmotionFeatures) -> Double {
        var score = 0.0

        // Furrowed brows (lowered, tense)
        if features.browPosition < 0.4 {
            score += 0.4
        }

        // Moderate intensity
        if features.expressionIntensity > 0.4 && features.expressionIntensity < 0.7 {
            score += 0.3
        }

        // Tense mouth
        if features.mouthOpenness < 0.3 {
            score += 0.2
        }

        // Focused eyes (not wide, not narrow)
        if features.eyeOpenness > 0.3 && features.eyeOpenness < 0.6 {
            score += 0.1
        }

        return min(score, 1.0)
    }

    private func calculateOverwhelmScore(features: EmotionFeatures) -> Double {
        var score = 0.0

        // Can show as shutdown (very low intensity)
        if features.expressionIntensity < 0.2 {
            score += 0.3
        }

        // Or high distress (very high intensity)
        if features.expressionIntensity > 0.8 {
            score += 0.3
        }

        // Wide eyes (distress)
        if features.eyeOpenness > 0.7 {
            score += 0.2
        }

        // Open mouth (crying/distress)
        if features.mouthOpenness > 0.6 {
            score += 0.2
        }

        return min(score, 1.0)
    }

    private func calculateFocusedScore(features: EmotionFeatures) -> Double {
        var score = 0.0

        // Low to moderate intensity (not expressing much)
        if features.expressionIntensity > 0.2 && features.expressionIntensity < 0.5 {
            score += 0.4
        }

        // Steady brows (not raised or lowered)
        if features.browPosition > 0.4 && features.browPosition < 0.6 {
            score += 0.3
        }

        // Normal eye openness (steady gaze)
        if features.eyeOpenness > 0.4 && features.eyeOpenness < 0.6 {
            score += 0.2
        }

        // Neutral mouth
        if features.mouthOpenness < 0.3 {
            score += 0.1
        }

        return min(score, 1.0)
    }

    private func calculateDysregulatedScore(features: EmotionFeatures) -> Double {
        var score = 0.0

        // Very high intensity (extreme expression)
        if features.expressionIntensity > 0.8 {
            score += 0.4
        }

        // Extreme brow position (very high or very low)
        if features.browPosition < 0.2 || features.browPosition > 0.8 {
            score += 0.3
        }

        // Wide open mouth (crying, yelling)
        if features.mouthOpenness > 0.7 {
            score += 0.2
        }

        // Wide eyes (distress)
        if features.eyeOpenness > 0.7 {
            score += 0.1
        }

        return min(score, 1.0)
    }

    // MARK: - Confidence Calculation

    private func determineConfidence(
        primaryScore: Double,
        allScores: [EmotionLabel: Double],
        faceConfidence: Double
    ) -> ConfidenceScore {
        // Base confidence on primary score and face detection confidence
        let baseConfidence = (primaryScore + faceConfidence) / 2.0

        // Calculate ambiguity (how close are other emotions)
        let sortedScores = allScores.values.sorted(by: >)
        let topTwo = sortedScores.prefix(2)
        let ambiguity = topTwo.count > 1 ? abs(topTwo[0] - topTwo[1]) : 1.0

        // Adjust confidence based on ambiguity
        let adjustedConfidence = baseConfidence * ambiguity

        // Determine confidence level
        let level: ConfidenceLevel
        if adjustedConfidence < 0.5 {
            level = .low
        } else if adjustedConfidence < 0.75 {
            level = .medium
        } else {
            level = .high
        }

        return ConfidenceScore(
            level: level,
            probability: adjustedConfidence,
            signalQuality: faceConfidence,
            temporalStability: calculateTemporalStability()
        )
    }

    /// Calculate temporal stability from recent history
    private func calculateTemporalStability() -> Double? {
        guard emotionHistory.count >= 3 else { return nil }

        let recentEmotions = emotionHistory.suffix(3)
        let primaryEmotions = recentEmotions.map { $0.primary }

        // Count most common emotion
        var counts: [EmotionLabel: Int] = [:]
        for emotion in primaryEmotions {
            counts[emotion, default: 0] += 1
        }

        let maxCount = counts.values.max() ?? 0
        return Double(maxCount) / Double(primaryEmotions.count)
    }
}

// MARK: - Neurodiversity-Aware Adjustments

extension EmotionStateClassifier {
    /// Apply profile-based adjustments to classification
    func applyProfileAdjustments(
        _ classification: EmotionClassification,
        profile: EmotionExpressionProfile
    ) -> EmotionClassification {
        var adjusted = classification

        // Adjust confidence for flat affect
        if profile.hasFlatAffect {
            // Lower confidence threshold since expressions may be subtle
            let adjustment = profile.flatAffectAdjustment
            adjusted = adjustConfidence(classification, multiplier: adjustment)
        }

        // Consider custom expressions
        let customExpressions = profile.getExpressions(for: classification.primary)
        if !customExpressions.isEmpty {
            // If parent has noted custom expressions for this emotion,
            // slightly boost confidence
            adjusted = adjustConfidence(classification, multiplier: 1.1)
        }

        return adjusted
    }

    private func adjustConfidence(
        _ classification: EmotionClassification,
        multiplier: Double
    ) -> EmotionClassification {
        let newProbability = min(classification.confidence.probability * multiplier, 1.0)

        let newLevel: ConfidenceLevel
        if newProbability < 0.5 {
            newLevel = .low
        } else if newProbability < 0.75 {
            newLevel = .medium
        } else {
            newLevel = .high
        }

        let newConfidence = ConfidenceScore(
            level: newLevel,
            probability: newProbability,
            signalQuality: classification.confidence.signalQuality,
            temporalStability: classification.confidence.temporalStability
        )

        return EmotionClassification(
            primary: classification.primary,
            secondary: classification.secondary,
            confidence: newConfidence,
            timestamp: classification.timestamp,
            features: classification.features
        )
    }
}
