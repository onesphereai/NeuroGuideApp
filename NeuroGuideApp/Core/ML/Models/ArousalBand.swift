//
//  ArousalBand.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 2 - ML Foundation (Partial - needed for Unit 4)
//

import Foundation

/// Arousal band classification
/// Represents the child's current physiological arousal level
enum ArousalBand: String, Codable, CaseIterable {
    case shutdown = "shutdown"  // Under-aroused, withdrawn
    case green = "green"        // Regulated, calm
    case yellow = "yellow"      // Elevated, early warning
    case orange = "orange"      // High arousal, needs support
    case red = "red"            // Crisis, safety concern

    var displayName: String {
        switch self {
        case .shutdown:
            return "Shutdown"
        case .green:
            return "Green (Calm)"
        case .yellow:
            return "Yellow (Alert)"
        case .orange:
            return "Orange (High)"
        case .red:
            return "Red (Crisis)"
        }
    }

    var description: String {
        switch self {
        case .shutdown:
            return "Under-aroused, withdrawn, low energy"
        case .green:
            return "Regulated, calm, ready to learn"
        case .yellow:
            return "Elevated arousal, early warning signs"
        case .orange:
            return "High arousal, needs immediate support"
        case .red:
            return "Crisis state, safety is priority"
        }
    }

    var color: String {
        return self.rawValue
    }

    /// Get coaching strategies for this arousal band
    var coachingFocus: String {
        switch self {
        case .shutdown:
            return "Alerting and engagement"
        case .green:
            return "Maintenance and prevention"
        case .yellow:
            return "Early intervention and de-escalation"
        case .orange:
            return "Immediate calming and regulation"
        case .red:
            return "Safety and crisis management"
        }
    }
}
