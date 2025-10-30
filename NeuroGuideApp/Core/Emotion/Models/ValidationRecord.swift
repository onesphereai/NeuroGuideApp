//
//  ValidationRecord.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation

/// Record of parent validation (confirming or correcting emotion prediction)
struct ValidationRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let childID: UUID
    let timestamp: Date
    let predicted: EmotionLabel
    let actual: EmotionLabel
    let wasCorrect: Bool
    let confidence: ConfidenceLevel

    init(
        id: UUID = UUID(),
        childID: UUID,
        timestamp: Date = Date(),
        predicted: EmotionLabel,
        actual: EmotionLabel,
        confidence: ConfidenceLevel
    ) {
        self.id = id
        self.childID = childID
        self.timestamp = timestamp
        self.predicted = predicted
        self.actual = actual
        self.wasCorrect = (predicted == actual)
        self.confidence = confidence
    }

    /// Whether this was a correction (parent disagreed)
    var wasCorrection: Bool {
        return !wasCorrect
    }
}

/// Statistics on model improvement from validation
struct CalibrationStats: Codable, Equatable {
    let totalValidations: Int
    let correctPredictions: Int
    let accuracyByEmotion: [EmotionLabel: Double]
    let improvementRate: Double  // Accuracy improvement over time

    /// Overall accuracy from validations
    var accuracy: Double {
        guard totalValidations > 0 else { return 0.0 }
        return Double(correctPredictions) / Double(totalValidations)
    }

    /// Formatted accuracy for display
    var formattedAccuracy: String {
        return "\(Int(accuracy * 100))%"
    }

    /// Whether model is improving
    var isImproving: Bool {
        return improvementRate > 0.0
    }

    /// User-friendly message about calibration
    var statusMessage: String {
        if totalValidations < 10 {
            return "Learning your child's expressions... (\(totalValidations)/10 needed for calibration)"
        } else if isImproving {
            return "Model is improving! Current accuracy: \(formattedAccuracy)"
        } else {
            return "Model calibrated. Accuracy: \(formattedAccuracy)"
        }
    }
}

/// Calibration status for a child's emotion model
enum CalibrationStatus: Codable, Equatable {
    case notStarted
    case learning(sessionCount: Int, validationCount: Int)
    case calibrated(lastUpdate: Date, accuracy: Double)
    case needsRecalibration(reason: String)

    var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .learning(let sessionCount, let validationCount):
            return "Learning (\(sessionCount) sessions, \(validationCount) validations)"
        case .calibrated(_, let accuracy):
            return "Calibrated (\(Int(accuracy * 100))% accurate)"
        case .needsRecalibration:
            return "Needs Recalibration"
        }
    }

    var description: String {
        switch self {
        case .notStarted:
            return "Model needs baseline data from 3-5 sessions"
        case .learning(let sessionCount, _):
            let remaining = max(0, 3 - sessionCount)
            if remaining > 0 {
                return "Model is learning your child's expressions. \(remaining) more sessions needed."
            } else {
                return "Model is learning your child's expressions. Keep validating to improve accuracy!"
            }
        case .calibrated(let lastUpdate, _):
            let formatter = RelativeDateTimeFormatter()
            let relative = formatter.localizedString(for: lastUpdate, relativeTo: Date())
            return "Model was calibrated \(relative)"
        case .needsRecalibration(let reason):
            return reason
        }
    }

    var icon: String {
        switch self {
        case .notStarted:
            return "circle.dashed"
        case .learning:
            return "arrow.triangle.2.circlepath"
        case .calibrated:
            return "checkmark.circle.fill"
        case .needsRecalibration:
            return "exclamationmark.triangle"
        }
    }

    /// Whether model is ready for production use
    var isReady: Bool {
        if case .calibrated = self {
            return true
        }
        return false
    }
}

/// Calibration data stored for a child
struct CalibrationData: Codable, Equatable {
    let childID: UUID
    var status: CalibrationStatus
    var validationRecords: [ValidationRecord]
    var baselineSessionCount: Int
    var lastRecalibration: Date?

    init(
        childID: UUID,
        status: CalibrationStatus = .notStarted,
        validationRecords: [ValidationRecord] = [],
        baselineSessionCount: Int = 0,
        lastRecalibration: Date? = nil
    ) {
        self.childID = childID
        self.status = status
        self.validationRecords = validationRecords
        self.baselineSessionCount = baselineSessionCount
        self.lastRecalibration = lastRecalibration
    }

    /// Add validation record
    mutating func addValidation(_ record: ValidationRecord) {
        validationRecords.append(record)
        updateStatus()
    }

    /// Increment session count
    mutating func incrementSessionCount() {
        baselineSessionCount += 1
        updateStatus()
    }

    /// Update calibration status based on current data
    private mutating func updateStatus() {
        let validationCount = validationRecords.count

        if baselineSessionCount >= 3 && validationCount >= 10 {
            // Calculate accuracy
            let correct = validationRecords.filter { $0.wasCorrect }.count
            let accuracy = Double(correct) / Double(validationCount)

            status = .calibrated(lastUpdate: Date(), accuracy: accuracy)
            lastRecalibration = Date()
        } else {
            status = .learning(sessionCount: baselineSessionCount, validationCount: validationCount)
        }
    }

    /// Reset calibration (start over)
    mutating func reset() {
        status = .notStarted
        validationRecords.removeAll()
        baselineSessionCount = 0
        lastRecalibration = nil
    }
}
