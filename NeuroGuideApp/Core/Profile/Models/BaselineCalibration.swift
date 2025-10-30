//
//  BaselineCalibration.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation

/// Baseline calibration data captured during a calm moment
/// Used to personalize arousal band and emotion classification
struct BaselineCalibration: Codable {
    let calibratedAt: Date
    var movementBaseline: MovementBaseline
    var vocalBaseline: VocalBaseline
    var expressionBaseline: ExpressionBaseline?
    var notes: String?

    init(
        calibratedAt: Date = Date(),
        movementBaseline: MovementBaseline,
        vocalBaseline: VocalBaseline,
        expressionBaseline: ExpressionBaseline? = nil,
        notes: String? = nil
    ) {
        self.calibratedAt = calibratedAt
        self.movementBaseline = movementBaseline
        self.vocalBaseline = vocalBaseline
        self.expressionBaseline = expressionBaseline
        self.notes = notes
    }

    /// Check if calibration is stale (older than 30 days)
    func isStale() -> Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return calibratedAt < thirtyDaysAgo
    }
}

/// Movement baseline captured during calm state
struct MovementBaseline: Codable {
    var averageMovementEnergy: Double // 0.0-1.0 scale
    var typicalPosture: String?
    var commonStimBehaviors: [String] // e.g., ["hand flapping", "rocking"]

    init(
        averageMovementEnergy: Double = 0.0,
        typicalPosture: String? = nil,
        commonStimBehaviors: [String] = []
    ) {
        self.averageMovementEnergy = averageMovementEnergy
        self.typicalPosture = typicalPosture
        self.commonStimBehaviors = commonStimBehaviors
    }
}

/// Vocal baseline captured during calm state
struct VocalBaseline: Codable {
    var averagePitch: Double // Hz
    var averageVolume: Double // dB
    var typicalCadence: String? // e.g., "slow and deliberate"
    var echolaliaPresent: Bool
    var scriptingPresent: Bool

    init(
        averagePitch: Double = 0.0,
        averageVolume: Double = 0.0,
        typicalCadence: String? = nil,
        echolaliaPresent: Bool = false,
        scriptingPresent: Bool = false
    ) {
        self.averagePitch = averagePitch
        self.averageVolume = averageVolume
        self.typicalCadence = typicalCadence
        self.echolaliaPresent = echolaliaPresent
        self.scriptingPresent = scriptingPresent
    }
}

/// Expression baseline captured during calm state
struct ExpressionBaseline: Codable {
    var neutralExpression: String? // Description of neutral expression
    var flatAffectNormal: Bool // Is flat affect typical for this child?

    init(
        neutralExpression: String? = nil,
        flatAffectNormal: Bool = false
    ) {
        self.neutralExpression = neutralExpression
        self.flatAffectNormal = flatAffectNormal
    }
}
