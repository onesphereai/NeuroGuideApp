//
//  ArousalBand.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 2 - ML Foundation (Partial - needed for Unit 4)
//  Updated: 2025-10-31 - Added Unit 7 multi-tier display extensions
//

import Foundation
import SwiftUI

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

// MARK: - Unit 7 Multi-Tier Display Extensions

extension ArousalBand {
    /// Emoji representation for stabilized display
    var emoji: String {
        switch self {
        case .shutdown:
            return "😴"
        case .green:
            return "🟢"
        case .yellow:
            return "🟡"
        case .orange:
            return "🟠"
        case .red:
            return "🔴"
        }
    }

    /// Parent-friendly description for stabilized display
    var stabilizedDescription: String {
        switch self {
        case .shutdown:
            return "Very low arousal. Your child may need gentle engagement or alerting activities."
        case .green:
            return "Calm and regulated. Your child is in their optimal arousal zone for learning and interaction."
        case .yellow:
            return "Slightly elevated arousal. Monitor for early signs and consider calming activities."
        case .orange:
            return "Heightened arousal. Your child may benefit from calming strategies now."
        case .red:
            return "High arousal. Prioritize safety and co-regulation. Your calm presence matters most."
        }
    }

    /// SwiftUI Color for UI elements
    var swiftUIColor: Color {
        switch self {
        case .shutdown:
            return Color(hex: "1E3A8A") ?? .blue  // Deep blue
        case .green:
            return Color(hex: "10B981") ?? .green  // Soft green
        case .yellow:
            return Color(hex: "F59E0B") ?? .yellow  // Warm amber
        case .orange:
            return Color(hex: "F97316") ?? .orange  // Coral orange
        case .red:
            return Color(hex: "EF4444") ?? .red  // Alert red
        }
    }

    /// Ambient indicator pulse frequency (in seconds)
    var pulseFrequency: TimeInterval {
        switch self {
        case .shutdown:
            return 3.0  // Slow pulse
        case .green:
            return 0.0  // Steady glow (no pulse)
        case .yellow:
            return 2.0  // Subtle pulse
        case .orange:
            return 1.5  // Moderate pulse
        case .red:
            return 1.0  // Stronger pulse
        }
    }
}
