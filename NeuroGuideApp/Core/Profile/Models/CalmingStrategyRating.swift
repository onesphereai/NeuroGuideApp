//
//  CalmingStrategyRating.swift
//  NeuroGuide
//
//  Created for AT-19: Co-Regulation Q2 Rating
//  Comprehensive calming strategy rating with ML metadata
//

import Foundation

/// Individual calming strategy rating with ML-required metadata
struct CalmingStrategyRating: Codable, Identifiable {
    var id: UUID = UUID()
    var strategyName: String
    var rating: Int? // 1-5, nil if not tried
    var category: CalmingStrategyCategory
    var subtype: String?
    var example: String?
    var severityModulation: SeverityModulation?
    var expectedCalmingTime: CalmingTime?
    var ageApplicability: AgeRange
    var sensorySystemInvolved: [SensorySystem]
    var lastUpdated: Date = Date()
    
    /// Check if this strategy has been rated by the user
    var hasBeenRated: Bool {
        return rating != nil
    }
    
    /// Check if this is a custom user-created strategy
    var isCustom: Bool {
        return category == .other
    }
    
    /// Create a custom strategy with default ML metadata
    static func createCustomStrategy(name: String, example: String?) -> CalmingStrategyRating {
        return CalmingStrategyRating(
            strategyName: name,
            rating: nil,
            category: .other,
            subtype: "User-defined",
            example: example,
            severityModulation: .varies,
            expectedCalmingTime: .moderate,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.visual, .auditory, .tactile, .interoceptive]
        )
    }
}

// MARK: - Supporting Enums

/// Category of calming strategy for ML classification
enum CalmingStrategyCategory: String, Codable, CaseIterable {
    case sensoryInput = "Sensory Input"
    case environmental = "Environmental"
    case communication = "Communication"
    case coRegulation = "Co-Regulation"
    case transition = "Transition Support"
    case movement = "Movement"
    case presence = "Presence & Proximity"
    case routine = "Routine & Structure"
    case other = "Other"
}

/// Severity modulation - which arousal levels this strategy helps with
enum SeverityModulation: String, Codable {
    case low = "Low arousal"
    case moderate = "Moderate arousal"
    case high = "High arousal"
    case varies = "Varies by context"
}

/// Expected time for strategy to achieve calming effect
enum CalmingTime: String, Codable {
    case immediate = "0-2 minutes"
    case quick = "2-5 minutes"
    case moderate = "5-15 minutes"
    case extended = "15+ minutes"
}

/// Age applicability for strategy effectiveness
enum AgeRange: String, Codable {
    case infant = "0-2 years"
    case toddler = "2-5 years"
    case earlyChild = "5-8 years"
    case middleChild = "8-12 years"
    case teen = "12-18 years"
    case allAges = "All ages"
}

/// Sensory systems involved in the strategy
enum SensorySystem: String, Codable, CaseIterable {
    case tactile = "Tactile (touch)"
    case proprioceptive = "Proprioceptive (body awareness)"
    case vestibular = "Vestibular (balance/movement)"
    case auditory = "Auditory (sound)"
    case visual = "Visual (sight)"
    case olfactory = "Olfactory (smell)"
    case gustatory = "Gustatory (taste)"
    case interoceptive = "Interoceptive (internal sensations)"
}
