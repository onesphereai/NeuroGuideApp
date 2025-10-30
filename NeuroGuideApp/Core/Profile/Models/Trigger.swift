//
//  Trigger.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation

/// Known trigger that may cause dysregulation
struct Trigger: Codable, Identifiable, Equatable {
    let id: UUID
    var description: String
    var category: TriggerCategory
    var createdAt: Date

    init(id: UUID = UUID(), description: String, category: TriggerCategory) {
        self.id = id
        self.description = description
        self.category = category
        self.createdAt = Date()
    }
}

/// Categories of triggers
enum TriggerCategory: String, Codable, CaseIterable {
    case sensory = "Sensory"
    case social = "Social"
    case routine = "Routine"
    case environmental = "Environmental"
    case other = "Other"

    var icon: String {
        switch self {
        case .sensory: return "waveform.path.ecg"
        case .social: return "person.2.fill"
        case .routine: return "calendar"
        case .environmental: return "building.2.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .sensory: return "Related to sensory input (sounds, textures, lights)"
        case .social: return "Related to social interactions or expectations"
        case .routine: return "Related to changes in routine or schedule"
        case .environmental: return "Related to environment (crowds, new places)"
        case .other: return "Other types of triggers"
        }
    }
}
