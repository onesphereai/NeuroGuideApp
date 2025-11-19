//
//  DiagnosisAwareArousalAdjuster.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-11-01.
//  Unit 3 - Child Profile & Personalization (Diagnosis-Aware Arousal Detection)
//

import Foundation

/// Service for adjusting arousal band classification based on diagnosis and baseline
/// This ensures neurodivergent traits are not misinterpreted as dysregulation
class DiagnosisAwareArousalAdjuster {
    // MARK: - Singleton

    static let shared = DiagnosisAwareArousalAdjuster()

    private init() {}

    // MARK: - Arousal Adjustment

    /// Adjust raw arousal features based on child's profile
    /// - Parameters:
    ///   - rawFeatures: Unadjusted features from ML detection
    ///   - profile: Child profile with diagnosis and baseline
    /// - Returns: Adjusted features that account for diagnosis
    func adjustFeatures(
        rawFeatures: RawArousalFeatures,
        for profile: ChildProfile
    ) -> AdjustedArousalFeatures {
        // Get diagnosis adjustments
        let adjustments = profile.getArousalThresholdAdjustments()

        // Get baseline if available
        let baseline = profile.baselineCalibration

        // Adjust movement features
        let adjustedMovement = adjustMovementFeatures(
            raw: rawFeatures.movementEnergy,
            baseline: baseline?.movementBaseline,
            adjustments: adjustments,
            profile: profile
        )

        // Adjust vocal features
        let adjustedVocal = adjustVocalFeatures(
            rawPitch: rawFeatures.vocalPitch,
            rawVolume: rawFeatures.vocalVolume,
            baseline: baseline?.vocalBaseline,
            adjustments: adjustments
        )

        // Adjust expression features
        let adjustedExpression = adjustExpressionFeatures(
            raw: rawFeatures.facialTension,
            baseline: baseline?.expressionBaseline,
            adjustments: adjustments,
            profile: profile
        )

        return AdjustedArousalFeatures(
            movementScore: adjustedMovement,
            vocalScore: adjustedVocal,
            expressionScore: adjustedExpression,
            originalFeatures: rawFeatures,
            appliedAdjustments: adjustments
        )
    }

    // MARK: - Movement Adjustment

    private func adjustMovementFeatures(
        raw movementEnergy: Double,
        baseline: MovementBaseline?,
        adjustments: ArousalThresholdAdjustments,
        profile: ChildProfile
    ) -> Double {
        var adjusted = movementEnergy

        // If we have a baseline, compare to it
        if let baseline = baseline {
            // Check if within baseline range (accounting for diagnosis)
            if baseline.isWithinBaseline(movementEnergy, adjustments: adjustments) {
                // Movement is within expected range - reduce arousal signal
                adjusted *= 0.5
            }

            // Check if this matches common stim behaviors
            if baseline.stimIsRegulatory && !baseline.commonStimBehaviors.isEmpty {
                // Stimming is typically regulatory for this child
                // Don't interpret as distress unless very elevated
                adjusted *= 0.7
            }
        } else {
            // No baseline - use diagnosis-based adjustments
            adjusted /= adjustments.movementThresholdMultiplier
        }

        // Special handling for autism diagnosis
        if let diagnosisInfo = profile.diagnosisInfo,
           diagnosisInfo.hasDiagnosis(.autism) {
            // For autism, higher baseline movement is expected
            // Only trigger on *changes* from baseline, not absolute levels
            adjusted *= 0.8
        }

        return max(0.0, min(1.0, adjusted))
    }

    // MARK: - Vocal Adjustment

    private func adjustVocalFeatures(
        rawPitch: Double?,
        rawVolume: Double?,
        baseline: VocalBaseline?,
        adjustments: ArousalThresholdAdjustments
    ) -> Double {
        guard let pitch = rawPitch, let volume = rawVolume else {
            return 0.0
        }

        var arousalScore = 0.0

        if let baseline = baseline {
            // Calculate deviation from baseline
            let pitchDeviation = abs(pitch - baseline.averagePitch) / baseline.averagePitch
            let volumeDeviation = abs(volume - baseline.averageVolume) / baseline.averageVolume

            // Weight deviations
            arousalScore = (pitchDeviation * 0.4 + volumeDeviation * 0.6)

            // If echolalia or scripting is common, reduce weight of vocal changes
            if baseline.echolaliaPresent || baseline.scriptingPresent {
                arousalScore *= 0.7
            }
        } else {
            // No baseline - use normalized values
            arousalScore = (min(pitch / 500.0, 1.0) * 0.4 + min(volume / 100.0, 1.0) * 0.6)
        }

        // Apply diagnosis adjustment
        arousalScore /= adjustments.vocalThresholdMultiplier

        return max(0.0, min(1.0, arousalScore))
    }

    // MARK: - Expression Adjustment

    private func adjustExpressionFeatures(
        raw facialTension: Double?,
        baseline: ExpressionBaseline?,
        adjustments: ArousalThresholdAdjustments,
        profile: ChildProfile
    ) -> Double {
        guard let tension = facialTension else {
            return 0.0
        }

        var adjusted = tension

        // Apply expression sensitivity from diagnosis
        adjusted *= adjustments.expressionSensitivity

        // If flat affect is typical, reduce reliance on facial cues
        if let baseline = baseline, baseline.flatAffectNormal {
            adjusted *= 0.5
        }

        // Special handling for autism (masked emotions common)
        if let diagnosisInfo = profile.diagnosisInfo,
           diagnosisInfo.hasDiagnosis(.autism) {
            // Reduce weight of facial expression in arousal detection
            adjusted *= 0.6
        }

        return max(0.0, min(1.0, adjusted))
    }

    // MARK: - Band Classification

    /// Classify arousal band from adjusted features
    func classifyArousalBand(features: AdjustedArousalFeatures) -> ArousalBand {
        // Compute weighted arousal score
        let arousalScore = (
            features.movementScore * 0.5 +
            features.vocalScore * 0.3 +
            features.expressionScore * 0.2
        )

        // Classify into bands
        switch arousalScore {
        case 0.0..<0.15:
            return .shutdown
        case 0.15..<0.4:
            return .green
        case 0.4..<0.6:
            return .yellow
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Feature Types

/// Raw features from ML detection (unadjusted)
struct RawArousalFeatures {
    var movementEnergy: Double  // 0.0-1.0
    var vocalPitch: Double?      // Hz
    var vocalVolume: Double?     // dB
    var facialTension: Double?   // 0.0-1.0
}

/// Adjusted features accounting for diagnosis and baseline
struct AdjustedArousalFeatures {
    var movementScore: Double     // 0.0-1.0 (adjusted)
    var vocalScore: Double        // 0.0-1.0 (adjusted)
    var expressionScore: Double   // 0.0-1.0 (adjusted)

    var originalFeatures: RawArousalFeatures
    var appliedAdjustments: ArousalThresholdAdjustments

    /// Overall arousal score
    var overallScore: Double {
        return (
            movementScore * 0.5 +
            vocalScore * 0.3 +
            expressionScore * 0.2
        )
    }

    /// Get explanation of adjustments applied
    var adjustmentExplanation: String {
        var explanations: [String] = []

        if appliedAdjustments.movementThresholdMultiplier > 1.0 {
            explanations.append("Higher movement threshold applied (\(String(format: "%.1fx", appliedAdjustments.movementThresholdMultiplier)))")
        }

        if appliedAdjustments.vocalThresholdMultiplier > 1.0 {
            explanations.append("Higher vocal threshold applied (\(String(format: "%.1fx", appliedAdjustments.vocalThresholdMultiplier)))")
        }

        if appliedAdjustments.expressionSensitivity < 1.0 {
            explanations.append("Reduced expression sensitivity (\(String(format: "%.0f%%", appliedAdjustments.expressionSensitivity * 100)))")
        }

        return explanations.isEmpty ? "No adjustments" : explanations.joined(separator: ", ")
    }
}
