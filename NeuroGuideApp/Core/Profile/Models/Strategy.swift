//
//  Strategy.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation
import SwiftUI

/// Soothing or co-regulation strategy that has been effective
struct Strategy: Codable, Identifiable, Equatable {
    let id: UUID
    var description: String
    var category: StrategyCategory
    var effectivenessRating: Double // 0.0-5.0 (exponential moving average)
    var usageCount: Int
    var lastUsed: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        description: String,
        category: StrategyCategory,
        effectivenessRating: Double = 0.0
    ) {
        self.id = id
        self.description = description
        self.category = category
        self.effectivenessRating = effectivenessRating
        self.usageCount = 0
        self.lastUsed = nil
        self.createdAt = Date()
    }

    /// Record usage of this strategy with a helpfulness rating (1-5)
    mutating func recordUsage(rating: Int) {
        usageCount += 1
        lastUsed = Date()

        // Update effectiveness rating using exponential moving average
        let newRating = Double(rating)
        if effectivenessRating == 0.0 {
            effectivenessRating = newRating
        } else {
            // Weight: 70% historical, 30% new rating
            effectivenessRating = (effectivenessRating * 0.7) + (newRating * 0.3)
        }
    }
}

/// Categories of soothing strategies
enum StrategyCategory: String, Codable, CaseIterable {
    case sensory = "Sensory Input"
    case environmental = "Environmental"
    case communication = "Communication"
    case coRegulation = "Co-Regulation"
    case transition = "Transition Support"
    case other = "Other"

    var icon: String {
        switch self {
        case .sensory: return "waveform.path"
        case .environmental: return "house.fill"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .coRegulation: return "heart.fill"
        case .transition: return "arrow.left.arrow.right"
        case .other: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .sensory: return .purple
        case .environmental: return .green
        case .communication: return .blue
        case .coRegulation: return .pink
        case .transition: return .orange
        case .other: return .gray
        }
    }

    var description: String {
        switch self {
        case .sensory: return "Sensory activities (deep pressure, movement, etc.)"
        case .environmental: return "Environmental changes (dimming lights, quiet space)"
        case .communication: return "Communication supports (visual aids, emotion cards)"
        case .coRegulation: return "Parent-child co-regulation (breathing together, presence)"
        case .transition: return "Transition support (visual schedules, countdowns)"
        case .other: return "Other helpful strategies"
        }
    }
}
