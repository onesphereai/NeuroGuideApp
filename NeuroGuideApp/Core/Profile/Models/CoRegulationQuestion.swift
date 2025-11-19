//
//  CoRegulationQuestion.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Enum representing the 10 questions in the co-regulation assessment
//

import Foundation

/// Represents each question in the co-regulation assessment questionnaire
enum CoRegulationQuestion: Int, CaseIterable, Identifiable {
    case currentPractices = 1
    case calmingStrategies = 2
    case parentSelfRegulation = 3
    case communicationApproach = 4
    case physicalProximity = 5
    case recoveryTime = 6
    case postRegulationConnection = 7
    case parentConfidence = 8
    case supportNeeds = 9
    case specificScenarios = 10

    var id: Int { rawValue }

    /// Display title for the question
    var title: String {
        switch self {
        case .currentPractices:
            return "Current Practices"
        case .calmingStrategies:
            return "Calming Strategies"
        case .parentSelfRegulation:
            return "Your Self-Regulation"
        case .communicationApproach:
            return "Communication"
        case .physicalProximity:
            return "Physical Proximity"
        case .recoveryTime:
            return "Recovery Time"
        case .postRegulationConnection:
            return "Reconnection"
        case .parentConfidence:
            return "Your Confidence"
        case .supportNeeds:
            return "Support Needs"
        case .specificScenarios:
            return "Specific Scenarios"
        }
    }

    /// Full question text
    var questionText: String {
        switch self {
        case .currentPractices:
            return "When your child becomes overwhelmed or dysregulated, how do you usually respond?"
        case .calmingStrategies:
            return "Rate which strategies have helped your child return to calm (1-5 scale)"
        case .parentSelfRegulation:
            return "When your child is overwhelmed, how do you usually manage your own emotions?"
        case .communicationApproach:
            return "When your child is upset, what type of communication helps them most?"
        case .physicalProximity:
            return "When your child is overwhelmed, what do they usually seek from you?"
        case .recoveryTime:
            return "After a tough moment, how long does it usually take for your child to feel calm again?"
        case .postRegulationConnection:
            return "After your child has calmed, how do they usually reconnect with you?"
        case .parentConfidence:
            return "How confident do you feel supporting your child during tough moments?"
        case .supportNeeds:
            return "What would help you feel more confident supporting your child?"
        case .specificScenarios:
            return "What typically helps in these situations?"
        }
    }

    /// Helper text displayed below the question
    var helperText: String? {
        switch self {
        case .currentPractices:
            return "Select all that apply. No judgment — every parent does their best."
        case .calmingStrategies:
            return "Rate each one from 1–5 (1 = not helpful, 5 = very helpful). Tap a star again to mark 'Haven't tried'."
        case .parentSelfRegulation:
            return "Choose all that apply. No right or wrong answers — every parent is doing their best."
        case .communicationApproach:
            return "Choose the option that feels closest — every child is different."
        case .physicalProximity:
            return "Choose the one that feels true most of the time."
        case .recoveryTime:
            return "Choose the option that fits most of the time."
        case .postRegulationConnection:
            return "Choose all that apply — every child reconnects in their own way."
        case .parentConfidence:
            return nil
        case .supportNeeds:
            return "Choose all that apply — you're not alone in this."
        case .specificScenarios:
            return "Optional - share what works in common challenging moments"
        }
    }

    /// Whether this question is optional
    var isOptional: Bool {
        self == .specificScenarios
    }

    /// Total number of questions
    static var totalCount: Int {
        allCases.count
    }

    /// Get next question
    var next: CoRegulationQuestion? {
        guard let nextIndex = CoRegulationQuestion(rawValue: rawValue + 1) else {
            return nil
        }
        return nextIndex
    }

    /// Get previous question
    var previous: CoRegulationQuestion? {
        guard rawValue > 1,
              let prevIndex = CoRegulationQuestion(rawValue: rawValue - 1) else {
            return nil
        }
        return prevIndex
    }

    /// Check if this is the first question
    var isFirst: Bool {
        self == .currentPractices
    }

    /// Check if this is the last question
    var isLast: Bool {
        self == .specificScenarios
    }

    /// Progress indicator text (e.g., "1/10")
    var progressText: String {
        "\(rawValue)/\(Self.totalCount)"
    }
}
