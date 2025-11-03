//
//  ChildProfile.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation

/// Complete child profile containing all personalization data
/// This is the core data structure that informs all app features
struct ChildProfile: Codable, Identifiable {
    // MARK: - Basic Information

    let id: UUID
    var name: String
    var age: Int // 1-50 years
    var pronouns: String?
    var photoData: Data? // Optional photo stored locally
    var diagnosisInfo: DiagnosisInfo?  // Neurodivergent diagnosis (optional)

    // MARK: - Personalization Data

    var sensoryPreferences: SensoryPreferences
    var communicationMode: CommunicationMode
    var communicationNotes: String?
    var triggers: [Trigger]
    var soothingStrategies: [Strategy]
    var alexithymiaSettings: AlexithymiaSettings
    var baselineCalibration: BaselineCalibration?
    var coRegulationHistory: CoRegulationHistory
    var emotionExpressionProfile: EmotionExpressionProfile?  // Unit 6 - Emotion Interface
    var profileColor: String  // Hex color for spectrum visualization (Unit 5 - Live Coach)

    // MARK: - Metadata

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        pronouns: String? = nil,
        photoData: Data? = nil,
        diagnosisInfo: DiagnosisInfo? = nil,
        profileColor: String = "#4A90E2"  // Default blue
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.pronouns = pronouns
        self.photoData = photoData
        self.diagnosisInfo = diagnosisInfo
        self.profileColor = profileColor
        self.sensoryPreferences = SensoryPreferences()
        self.communicationMode = .verbal
        self.communicationNotes = nil
        self.triggers = []
        self.soothingStrategies = []
        self.alexithymiaSettings = AlexithymiaSettings()
        self.baselineCalibration = nil
        self.coRegulationHistory = CoRegulationHistory()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Helper Methods

extension ChildProfile {
    /// Check if profile has minimum required information
    func isComplete() -> Bool {
        return !name.isEmpty && age >= 2 && age <= 8
    }

    /// Check if baseline calibration is needed
    func needsCalibration() -> Bool {
        if let baseline = baselineCalibration {
            return baseline.isStale()
        }
        return true
    }

    /// Update the timestamp
    mutating func updateTimestamp() {
        updatedAt = Date()
    }

    /// Add a trigger
    mutating func addTrigger(_ trigger: Trigger) {
        triggers.append(trigger)
        updateTimestamp()
    }

    /// Remove a trigger
    mutating func removeTrigger(id: UUID) {
        triggers.removeAll { $0.id == id }
        updateTimestamp()
    }

    /// Add a strategy
    mutating func addStrategy(_ strategy: Strategy) {
        soothingStrategies.append(strategy)
        updateTimestamp()
    }

    /// Remove a strategy
    mutating func removeStrategy(id: UUID) {
        soothingStrategies.removeAll { $0.id == id }
        updateTimestamp()
    }

    /// Update strategy effectiveness
    mutating func updateStrategyEffectiveness(id: UUID, rating: Int) {
        if let index = soothingStrategies.firstIndex(where: { $0.id == id }) {
            soothingStrategies[index].recordUsage(rating: rating)
            updateTimestamp()
        }
    }

    /// Get top strategies (by effectiveness and usage)
    func getTopStrategies(limit: Int = 5) -> [Strategy] {
        return soothingStrategies
            .sorted { strategy1, strategy2 in
                // Sort by effectiveness first, then usage count
                if strategy1.effectivenessRating != strategy2.effectivenessRating {
                    return strategy1.effectivenessRating > strategy2.effectivenessRating
                }
                return strategy1.usageCount > strategy2.usageCount
            }
            .prefix(limit)
            .map { $0 }
    }

    /// Get sensory-safe strategies (respects sensory avoiding preferences)
    func getSensorySafeStrategies() -> [Strategy] {
        return soothingStrategies.filter { strategy in
            switch strategy.category {
            case .sensory:
                // Check if strategy aligns with sensory preferences
                // For now, include all sensory strategies
                // TODO: Add more sophisticated filtering based on strategy details
                return true
            default:
                return true
            }
        }
    }

    /// Get diagnosis-specific baseline expectations
    func getDiagnosisBaselines() -> DiagnosisBaselines? {
        guard let diagnosis = diagnosisInfo?.primaryDiagnosis else {
            return nil
        }
        return DiagnosisBaselines.baselines(for: diagnosis)
    }

    /// Get arousal threshold adjustments based on diagnosis
    func getArousalThresholdAdjustments() -> ArousalThresholdAdjustments {
        return getDiagnosisBaselines()?.arousalThresholdAdjustments ?? ArousalThresholdAdjustments()
    }
}

// MARK: - Computed Properties

extension ChildProfile {
    /// Display name with pronouns if available
    var displayName: String {
        if let pronouns = pronouns, !pronouns.isEmpty {
            return "\(name) (\(pronouns))"
        }
        return name
    }

    /// Age group for content filtering
    var ageGroup: AgeGroup {
        switch age {
        case 1...3: return .toddler
        case 4...5: return .preschool
        case 6...12: return .earlyElementary
        default: return .earlyElementary // Fallback for older ages
        }
    }

    /// Summary of sensory profile
    var sensoryProfileSummary: String {
        var seeking: [String] = []
        var avoiding: [String] = []

        for sense in SenseType.allCases {
            let profile = sensoryPreferences.get(for: sense)
            switch profile {
            case .seeking:
                seeking.append(sense.displayName)
            case .avoiding:
                avoiding.append(sense.displayName)
            case .neutral:
                break
            }
        }

        var summary: [String] = []
        if !seeking.isEmpty {
            summary.append("Seeks: \(seeking.joined(separator: ", "))")
        }
        if !avoiding.isEmpty {
            summary.append("Avoids: \(avoiding.joined(separator: ", "))")
        }

        return summary.isEmpty ? "No strong sensory preferences noted" : summary.joined(separator: " | ")
    }
}

// MARK: - Supporting Types

enum AgeGroup: String, Codable {
    case toddler = "Toddler (2-3)"
    case preschool = "Preschool (4-5)"
    case earlyElementary = "Early Elementary (6-8)"
}
