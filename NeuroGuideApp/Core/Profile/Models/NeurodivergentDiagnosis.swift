//
//  NeurodivergentDiagnosis.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-11-01.
//  Unit 3 - Child Profile & Personalization (Diagnosis Support)
//

import Foundation

/// Neurodivergent diagnosis types
/// Used to personalize baseline expectations and arousal band calibration
enum NeurodivergentDiagnosis: String, Codable, CaseIterable, Identifiable {
    case autism = "autism"
    case adhd = "adhd"
    case spd = "spd"  // Sensory Processing Disorder
    case multiple = "multiple"
    case other = "other"
    case preferNotToSpecify = "prefer_not_to_specify"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .autism:
            return "Autism Spectrum Disorder (ASD)"
        case .adhd:
            return "ADHD"
        case .spd:
            return "Sensory Processing Disorder (SPD)"
        case .multiple:
            return "Multiple Diagnoses"
        case .other:
            return "Other"
        case .preferNotToSpecify:
            return "Prefer not to specify"
        }
    }

    var description: String {
        switch self {
        case .autism:
            return "Autism Spectrum Disorder - differences in social communication, sensory processing, and behavior patterns"
        case .adhd:
            return "ADHD - differences in attention, activity levels, and impulse control"
        case .spd:
            return "Sensory Processing Disorder - difficulties processing sensory information"
        case .multiple:
            return "Multiple neurodivergent diagnoses"
        case .other:
            return "Other neurodivergent conditions"
        case .preferNotToSpecify:
            return "You can skip this step and still use all features"
        }
    }

    /// Icon/emoji for visual representation
    var icon: String {
        switch self {
        case .autism:
            return "🧩"
        case .adhd:
            return "⚡"
        case .spd:
            return "👂"
        case .multiple:
            return "🌈"
        case .other:
            return "✨"
        case .preferNotToSpecify:
            return "🔒"
        }
    }
}

/// Container for diagnosis information in child profile
struct DiagnosisInfo: Codable, Equatable {
    var primaryDiagnosis: NeurodivergentDiagnosis
    var additionalDiagnoses: [NeurodivergentDiagnosis]
    var notes: String?
    var professionallyDiagnosed: Bool

    init(
        primaryDiagnosis: NeurodivergentDiagnosis,
        additionalDiagnoses: [NeurodivergentDiagnosis] = [],
        notes: String? = nil,
        professionallyDiagnosed: Bool = false
    ) {
        self.primaryDiagnosis = primaryDiagnosis
        self.additionalDiagnoses = additionalDiagnoses
        self.notes = notes
        self.professionallyDiagnosed = professionallyDiagnosed
    }

    /// Get all diagnoses (primary + additional)
    var allDiagnoses: [NeurodivergentDiagnosis] {
        var all = [primaryDiagnosis]
        all.append(contentsOf: additionalDiagnoses)
        return all
    }

    /// Check if a specific diagnosis is present
    func hasDiagnosis(_ diagnosis: NeurodivergentDiagnosis) -> Bool {
        return allDiagnoses.contains(diagnosis)
    }

    /// Summary text for display
    var summaryText: String {
        if primaryDiagnosis == .preferNotToSpecify {
            return "Not specified"
        }

        if additionalDiagnoses.isEmpty {
            return primaryDiagnosis.displayName
        } else {
            return "\(primaryDiagnosis.displayName) + \(additionalDiagnoses.count) more"
        }
    }
}

/// Diagnosis-specific baseline expectations
/// These are clinical norms that help contextualize behavior
struct DiagnosisBaselines {
    let diagnosis: NeurodivergentDiagnosis

    // Movement expectations
    var typicalMovementEnergy: ClosedRange<Double>
    var commonStimBehaviors: [String]
    var stimIsRegulatory: Bool  // Is stimming typically regulatory rather than distress?

    // Vocal expectations
    var typicalVocalVariability: Double  // How much pitch/volume varies
    var echolaliaCommon: Bool
    var scriptingCommon: Bool

    // Expression expectations
    var flatAffectTypical: Bool
    var maskedEmotionsCommon: Bool
    var delayedEmotionalResponse: Bool

    // Arousal band adjustments
    var arousalThresholdAdjustments: ArousalThresholdAdjustments

    /// Get diagnosis-specific baselines
    static func baselines(for diagnosis: NeurodivergentDiagnosis) -> DiagnosisBaselines {
        switch diagnosis {
        case .autism:
            return DiagnosisBaselines(
                diagnosis: .autism,
                typicalMovementEnergy: 0.2...0.8,  // Wide range
                commonStimBehaviors: [
                    "Hand flapping",
                    "Rocking",
                    "Spinning",
                    "Finger movements",
                    "Body swaying"
                ],
                stimIsRegulatory: true,
                typicalVocalVariability: 0.3,  // Lower variability
                echolaliaCommon: true,
                scriptingCommon: true,
                flatAffectTypical: true,
                maskedEmotionsCommon: true,
                delayedEmotionalResponse: true,
                arousalThresholdAdjustments: ArousalThresholdAdjustments(
                    movementThresholdMultiplier: 1.5,  // Higher threshold for movement = more movement needed to trigger yellow
                    vocalThresholdMultiplier: 1.3,
                    expressionSensitivity: 0.7  // Less sensitive to facial expression changes
                )
            )

        case .adhd:
            return DiagnosisBaselines(
                diagnosis: .adhd,
                typicalMovementEnergy: 0.5...0.95,  // Higher baseline
                commonStimBehaviors: [
                    "Fidgeting",
                    "Leg bouncing",
                    "Pacing",
                    "Tapping"
                ],
                stimIsRegulatory: true,
                typicalVocalVariability: 0.6,  // Higher variability
                echolaliaCommon: false,
                scriptingCommon: false,
                flatAffectTypical: false,
                maskedEmotionsCommon: false,
                delayedEmotionalResponse: false,
                arousalThresholdAdjustments: ArousalThresholdAdjustments(
                    movementThresholdMultiplier: 2.0,  // Much higher threshold
                    vocalThresholdMultiplier: 1.5,
                    expressionSensitivity: 1.0
                )
            )

        case .spd:
            return DiagnosisBaselines(
                diagnosis: .spd,
                typicalMovementEnergy: 0.1...0.9,  // Very wide range (seeking vs avoiding)
                commonStimBehaviors: [
                    "Rocking",
                    "Jumping",
                    "Pressure-seeking",
                    "Withdrawal"
                ],
                stimIsRegulatory: true,
                typicalVocalVariability: 0.5,
                echolaliaCommon: false,
                scriptingCommon: false,
                flatAffectTypical: false,
                maskedEmotionsCommon: false,
                delayedEmotionalResponse: false,
                arousalThresholdAdjustments: ArousalThresholdAdjustments(
                    movementThresholdMultiplier: 1.3,
                    vocalThresholdMultiplier: 1.2,
                    expressionSensitivity: 0.9
                )
            )

        case .multiple, .other, .preferNotToSpecify:
            // Default/neutral baselines
            return DiagnosisBaselines(
                diagnosis: diagnosis,
                typicalMovementEnergy: 0.3...0.7,
                commonStimBehaviors: [],
                stimIsRegulatory: false,
                typicalVocalVariability: 0.5,
                echolaliaCommon: false,
                scriptingCommon: false,
                flatAffectTypical: false,
                maskedEmotionsCommon: false,
                delayedEmotionalResponse: false,
                arousalThresholdAdjustments: ArousalThresholdAdjustments(
                    movementThresholdMultiplier: 1.0,
                    vocalThresholdMultiplier: 1.0,
                    expressionSensitivity: 1.0
                )
            )
        }
    }
}

/// Adjustments to arousal band thresholds based on diagnosis
struct ArousalThresholdAdjustments: Codable, Equatable {
    /// Multiplier for movement-based arousal thresholds
    /// > 1.0 means more movement needed to trigger higher bands
    var movementThresholdMultiplier: Double

    /// Multiplier for vocal-based arousal thresholds
    var vocalThresholdMultiplier: Double

    /// Sensitivity to facial expression changes (0.0-1.0)
    /// Lower = less sensitive (useful for flat affect)
    var expressionSensitivity: Double

    init(
        movementThresholdMultiplier: Double = 1.0,
        vocalThresholdMultiplier: Double = 1.0,
        expressionSensitivity: Double = 1.0
    ) {
        self.movementThresholdMultiplier = movementThresholdMultiplier
        self.vocalThresholdMultiplier = vocalThresholdMultiplier
        self.expressionSensitivity = expressionSensitivity
    }
}
