//
//  ContentFiltering.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 4 - Content Library & Management
//

import Foundation

/// Result of content validation against red-flag terms
struct ContentValidationResult {
    let isValid: Bool
    let flaggedTerms: [String]
    let suggestions: [String: String]  // term -> suggestion
    let severity: ValidationSeverity

    var hasWarnings: Bool {
        return !flaggedTerms.isEmpty
    }

    var detailedMessage: String {
        if isValid && flaggedTerms.isEmpty {
            return "Content passes all validation checks"
        }

        var message = "Found \(flaggedTerms.count) potential issue(s):\n"
        for term in flaggedTerms {
            if let suggestion = suggestions[term] {
                message += "• '\(term)' → Consider: '\(suggestion)'\n"
            } else {
                message += "• '\(term)' flagged\n"
            }
        }
        return message
    }
}

enum ValidationSeverity {
    case none      // No issues
    case warning   // Minor concerns
    case error     // Major concerns, should not publish
}

/// Red-flag terms and their neurodiversity-affirming alternatives
struct RedFlagTerm {
    let term: String
    let alternative: String
    let reason: String
    let severity: ValidationSeverity

    static let allTerms: [RedFlagTerm] = [
        // Pathologizing language
        RedFlagTerm(
            term: "tantrum",
            alternative: "meltdown",
            reason: "Pathologizes autistic distress",
            severity: .error
        ),
        RedFlagTerm(
            term: "non-compliant",
            alternative: "communicating needs differently",
            reason: "Implies defiance rather than communication",
            severity: .error
        ),
        RedFlagTerm(
            term: "fix",
            alternative: "support",
            reason: "Implies something is broken",
            severity: .error
        ),
        RedFlagTerm(
            term: "cure",
            alternative: "accept and support",
            reason: "Neurodivergence is not a disease",
            severity: .error
        ),
        RedFlagTerm(
            term: "normal",
            alternative: "neurotypical",
            reason: "Implies neurodivergence is abnormal",
            severity: .warning
        ),
        RedFlagTerm(
            term: "defiant",
            alternative: "asserting boundaries",
            reason: "Misinterprets boundary-setting as defiance",
            severity: .error
        ),
        RedFlagTerm(
            term: "behaviors",
            alternative: "communication or regulation attempts",
            reason: "Reframes actions as purposeful communication",
            severity: .warning
        ),

        // ABA language
        RedFlagTerm(
            term: "compliance",
            alternative: "cooperation",
            reason: "ABA language, implies forced obedience",
            severity: .error
        ),
        RedFlagTerm(
            term: "extinction",
            alternative: "gradual reduction with support",
            reason: "ABA technique, ignoring distress",
            severity: .error
        ),
        RedFlagTerm(
            term: "reinforcement schedule",
            alternative: "encouragement pattern",
            reason: "ABA jargon, dehumanizing",
            severity: .error
        ),
        RedFlagTerm(
            term: "shaping",
            alternative: "supporting skill development",
            reason: "ABA term, implies molding behavior",
            severity: .warning
        ),

        // Harmful practices
        RedFlagTerm(
            term: "restraint",
            alternative: "safety support",
            reason: "Physical restraint can be traumatic",
            severity: .error
        ),
        RedFlagTerm(
            term: "time out",
            alternative: "safe space",
            reason: "Punishment vs. regulation support",
            severity: .warning
        ),
        RedFlagTerm(
            term: "withhold",
            alternative: "adjust access",
            reason: "Implies punishment through deprivation",
            severity: .error
        ),

        // Deficit framing
        RedFlagTerm(
            term: "suffer from autism",
            alternative: "is autistic",
            reason: "Pathologizes identity",
            severity: .error
        ),
        RedFlagTerm(
            term: "lacks",
            alternative: "experiences differently",
            reason: "Deficit-focused language",
            severity: .warning
        ),
        RedFlagTerm(
            term: "can't",
            alternative: "needs support to",
            reason: "Assumes inability rather than different support needs",
            severity: .warning
        )
    ]

    /// Get all red-flag terms as a dictionary for quick lookup
    static var termDictionary: [String: RedFlagTerm] {
        var dict: [String: RedFlagTerm] = [:]
        for term in allTerms {
            dict[term.term.lowercased()] = term
        }
        return dict
    }

    /// Get all red-flag term strings
    static var allTermStrings: [String] {
        return allTerms.map { $0.term.lowercased() }
    }

    /// Get alternatives dictionary
    static var alternatives: [String: String] {
        var dict: [String: String] = [:]
        for term in allTerms {
            dict[term.term.lowercased()] = term.alternative
        }
        return dict
    }
}

/// Context for filtering content
struct ContentFilterContext {
    let ageRange: ClosedRange<Int>?
    let arousalBand: ArousalBand?
    let emotionState: String?
    let sensoryPreferences: SensoryPreferences?
    let tags: [String]?

    init(
        ageRange: ClosedRange<Int>? = nil,
        arousalBand: ArousalBand? = nil,
        emotionState: String? = nil,
        sensoryPreferences: SensoryPreferences? = nil,
        tags: [String]? = nil
    ) {
        self.ageRange = ageRange
        self.arousalBand = arousalBand
        self.emotionState = emotionState
        self.sensoryPreferences = sensoryPreferences
        self.tags = tags
    }

    /// Create context from a child profile
    static func from(profile: ChildProfile, arousalBand: ArousalBand? = nil, emotionState: String? = nil) -> ContentFilterContext {
        return ContentFilterContext(
            ageRange: profile.age...profile.age,
            arousalBand: arousalBand,
            emotionState: emotionState,
            sensoryPreferences: profile.sensoryPreferences,
            tags: nil
        )
    }
}
