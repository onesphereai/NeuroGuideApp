//
//  CommunicationMode.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation

/// Communication modes for children with varying verbal abilities
enum CommunicationMode: String, Codable, CaseIterable {
    case verbal = "Verbal"
    case minimallyVerbal = "Minimally Verbal"
    case nonVerbal = "Non-verbal"
    case usesAAC = "Uses AAC Device"
    case other = "Other"

    var description: String {
        switch self {
        case .verbal:
            return "Uses spoken language to communicate"
        case .minimallyVerbal:
            return "Uses some words or short phrases"
        case .nonVerbal:
            return "Communicates without spoken language"
        case .usesAAC:
            return "Uses augmentative and alternative communication device"
        case .other:
            return "Other communication method"
        }
    }

    var icon: String {
        switch self {
        case .verbal: return "bubble.left.fill"
        case .minimallyVerbal: return "text.bubble.fill"
        case .nonVerbal: return "hand.wave.fill"
        case .usesAAC: return "ipad.and.arrow.forward"
        case .other: return "ellipsis.bubble.fill"
        }
    }
}
