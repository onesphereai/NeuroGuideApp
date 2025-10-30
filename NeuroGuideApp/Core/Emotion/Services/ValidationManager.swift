//
//  ValidationManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation
import Combine

/// Manager for parent validation of emotion predictions
/// Tracks validations to improve model accuracy over time
@MainActor
class ValidationManager: ValidationService, ObservableObject {
    // MARK: - Singleton

    static let shared = ValidationManager()

    // MARK: - Published Properties

    @Published private(set) var validationHistory: [UUID: [ValidationRecord]] = [:]
    @Published private(set) var calibrationStats: [UUID: CalibrationStats] = [:]

    // MARK: - Private Properties

    private let storage: EmotionStorageService
    private let validationKey = "EmotionValidationHistory"
    private let statsKey = "CalibrationStats"
    private let promptFrequency = 5 // Show validation prompt every 5 predictions
    private var predictionCount = 0

    // MARK: - Initialization

    init(storage: EmotionStorageService = UserDefaults.standard) {
        self.storage = storage
        loadData()
    }

    // MARK: - ValidationService

    /// Submit validation (parent confirms or corrects)
    func submitValidation(predicted: EmotionLabel, actual: EmotionLabel, childID: UUID) async throws {
        let wasCorrect = predicted == actual

        let record = ValidationRecord(
            id: UUID(),
            childID: childID,
            timestamp: Date(),
            predicted: predicted,
            actual: actual,
            confidence: .medium // Would come from the prediction
        )

        // Add to history
        if validationHistory[childID] == nil {
            validationHistory[childID] = []
        }
        validationHistory[childID]?.append(record)

        // Update calibration stats
        updateCalibrationStats(for: childID)

        // Save to storage
        try await save()

        print("✅ Validation recorded: \(predicted) → \(actual) (\(wasCorrect ? "correct" : "incorrect"))")
    }

    /// Get validation history for child
    func getValidationHistory(childID: UUID) async throws -> [ValidationRecord] {
        return validationHistory[childID] ?? []
    }

    /// Get model improvement statistics
    func getImprovementStats(childID: UUID) async throws -> CalibrationStats {
        if let stats = calibrationStats[childID] {
            return stats
        }

        // Return empty stats
        return CalibrationStats(
            totalValidations: 0,
            correctPredictions: 0,
            accuracyByEmotion: [:],
            improvementRate: 0.0
        )
    }

    /// Whether validation prompt should be shown
    func shouldShowValidationPrompt() -> Bool {
        predictionCount += 1
        return predictionCount % promptFrequency == 0
    }

    // MARK: - Calibration Stats

    private func updateCalibrationStats(for childID: UUID) {
        guard let records = validationHistory[childID], !records.isEmpty else {
            return
        }

        let totalValidations = records.count
        let correctPredictions = records.filter { $0.wasCorrect }.count

        // Calculate accuracy by emotion
        var accuracyByEmotion: [EmotionLabel: Double] = [:]
        for emotion in EmotionLabel.allCases {
            let emotionRecords = records.filter { $0.predicted == emotion }
            if !emotionRecords.isEmpty {
                let correct = emotionRecords.filter { $0.wasCorrect }.count
                accuracyByEmotion[emotion] = Double(correct) / Double(emotionRecords.count)
            }
        }

        // Calculate improvement rate (comparing first half to second half)
        let improvementRate = calculateImprovementRate(records: records)

        let stats = CalibrationStats(
            totalValidations: totalValidations,
            correctPredictions: correctPredictions,
            accuracyByEmotion: accuracyByEmotion,
            improvementRate: improvementRate
        )

        calibrationStats[childID] = stats
    }

    private func calculateImprovementRate(records: [ValidationRecord]) -> Double {
        guard records.count >= 10 else { return 0.0 }

        let midpoint = records.count / 2
        let firstHalf = records.prefix(midpoint)
        let secondHalf = records.suffix(records.count - midpoint)

        let firstHalfAccuracy = Double(firstHalf.filter { $0.wasCorrect }.count) / Double(firstHalf.count)
        let secondHalfAccuracy = Double(secondHalf.filter { $0.wasCorrect }.count) / Double(secondHalf.count)

        return secondHalfAccuracy - firstHalfAccuracy
    }

    // MARK: - Storage

    private func loadData() {
        // Load validation history
        if let data = storage.data(forKey: validationKey),
           let decoded = try? JSONDecoder().decode([UUID: [ValidationRecord]].self, from: data) {
            validationHistory = decoded
            print("📊 Loaded validation history for \(decoded.keys.count) children")
        }

        // Load calibration stats
        if let data = storage.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode([UUID: CalibrationStats].self, from: data) {
            calibrationStats = decoded
        }
    }

    private func save() async throws {
        // Save validation history
        let historyData = try JSONEncoder().encode(validationHistory)
        storage.set(historyData, forKey: validationKey)

        // Save calibration stats
        let statsData = try JSONEncoder().encode(calibrationStats)
        storage.set(statsData, forKey: statsKey)
    }
}

// MARK: - Validation Prompt Logic

extension ValidationManager {
    /// Get pending validation for a prediction
    func createValidationPrompt(
        for classification: EmotionClassification,
        childID: UUID
    ) -> ValidationPrompt {
        return ValidationPrompt(
            id: UUID(),
            childID: childID,
            classification: classification,
            timestamp: Date()
        )
    }
}

/// Validation prompt to show to parent
struct ValidationPrompt: Identifiable {
    let id: UUID
    let childID: UUID
    let classification: EmotionClassification
    let timestamp: Date
}
