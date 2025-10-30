//
//  SensoryPreferences.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation

/// Sensory preferences for a child across six senses
struct SensoryPreferences: Codable {
    var touch: SensoryProfile = .neutral
    var sound: SensoryProfile = .neutral
    var sight: SensoryProfile = .neutral
    var movement: SensoryProfile = .neutral
    var taste: SensoryProfile = .neutral
    var smell: SensoryProfile = .neutral
    var specificTriggers: [String] = []

    func get(for sense: SenseType) -> SensoryProfile {
        switch sense {
        case .touch: return touch
        case .sound: return sound
        case .sight: return sight
        case .movement: return movement
        case .taste: return taste
        case .smell: return smell
        }
    }

    mutating func set(for sense: SenseType, profile: SensoryProfile) {
        switch sense {
        case .touch: touch = profile
        case .sound: sound = profile
        case .sight: sight = profile
        case .movement: movement = profile
        case .taste: taste = profile
        case .smell: smell = profile
        }
    }
}

/// Types of senses for sensory profiling
enum SenseType: String, CaseIterable, Codable {
    case touch, sound, sight, movement, taste, smell

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .touch: return "hand.raised.fill"
        case .sound: return "speaker.wave.2.fill"
        case .sight: return "eye.fill"
        case .movement: return "figure.walk"
        case .taste: return "mouth.fill"
        case .smell: return "nose.fill"
        }
    }

    var description: String {
        switch self {
        case .touch: return "Physical touch and textures"
        case .sound: return "Sounds and noise levels"
        case .sight: return "Visual input and lighting"
        case .movement: return "Movement and vestibular input"
        case .taste: return "Food tastes and textures"
        case .smell: return "Scents and odors"
        }
    }
}

/// Sensory profile for a specific sense
enum SensoryProfile: String, Codable, CaseIterable {
    case seeking = "Seeking"
    case avoiding = "Avoiding"
    case neutral = "Neutral"

    var description: String {
        switch self {
        case .seeking: return "Seeks out this sensory input"
        case .avoiding: return "Avoids or is sensitive to this input"
        case .neutral: return "No strong preference"
        }
    }

    var color: String {
        switch self {
        case .seeking: return "blue"
        case .avoiding: return "orange"
        case .neutral: return "gray"
        }
    }
}
