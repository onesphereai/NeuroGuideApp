//
//  ContentFilteringManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 4 - Content Library & Management
//

import Foundation

/// Implementation of ContentFilteringService
/// Validates content against red-flag terms and filters by context
@MainActor
class ContentFilteringManager: ContentFilteringService {
    // MARK: - Singleton

    static let shared = ContentFilteringManager()

    // MARK: - Dependencies

    private let contentLibrary: ContentLibraryService

    // MARK: - Initialization

    init(contentLibrary: ContentLibraryService = ContentLibraryManager.shared) {
        self.contentLibrary = contentLibrary
    }

    // MARK: - ContentFilteringService Implementation

    func filterContent(arousalBand: ArousalBand?, emotionState: String?, age: Int?) async throws -> [ContentItem] {
        var allContent = try await contentLibrary.getAllContent()

        // Filter by arousal band
        if let band = arousalBand {
            allContent = allContent.filter { item in
                item.isRelevantForArousalBand(band)
            }
        }

        // Filter by emotion state
        if let emotion = emotionState {
            allContent = allContent.filter { item in
                guard let emotions = item.emotionStates else { return true }
                return emotions.contains(where: { $0.lowercased() == emotion.lowercased() })
            }
        }

        // Filter by age
        if let childAge = age {
            allContent = allContent.filter { item in
                item.isAppropriateForAge(childAge)
            }
        }

        return allContent
    }

    func filterBySensoryProfile(profile: SensoryPreferences) async throws -> [ContentItem] {
        let allContent = try await contentLibrary.getAllContent()

        return allContent.filter { item in
            // If item has no sensory profile tags, include it
            guard let sensoryProfiles = item.sensoryProfiles else { return true }

            // Check for matches with the child's sensory preferences
            var matches = false

            // Touch
            if profile.touch == .seeking && sensoryProfiles.contains("tactile-seeking") {
                matches = true
            }
            if profile.touch == .avoiding && sensoryProfiles.contains("tactile-avoiding") {
                matches = true
            }

            // Sound
            if profile.sound == .seeking && sensoryProfiles.contains("auditory-seeking") {
                matches = true
            }
            if profile.sound == .avoiding && sensoryProfiles.contains("auditory-avoiding") {
                matches = true
            }

            // Movement
            if profile.movement == .seeking && sensoryProfiles.contains("vestibular-seeking") {
                matches = true
            }
            if profile.movement == .avoiding && sensoryProfiles.contains("vestibular-avoiding") {
                matches = true
            }

            // If no specific matches but item is general, include it
            if !matches && sensoryProfiles.contains("general") {
                matches = true
            }

            return matches
        }
    }

    func validateContent(text: String) -> ContentValidationResult {
        let lowercaseText = text.lowercased()
        var flaggedTerms: [String] = []
        var suggestions: [String: String] = [:]
        var maxSeverity: ValidationSeverity = .none

        // Check for red-flag terms
        for redFlagTerm in RedFlagTerm.allTerms {
            let term = redFlagTerm.term.lowercased()

            // Use word boundary detection to avoid false positives
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: term))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowercaseText.startIndex..., in: lowercaseText)
                if regex.firstMatch(in: lowercaseText, range: range) != nil {
                    flaggedTerms.append(redFlagTerm.term)
                    suggestions[redFlagTerm.term] = redFlagTerm.alternative

                    // Track highest severity
                    if redFlagTerm.severity == .error {
                        maxSeverity = .error
                    } else if redFlagTerm.severity == .warning && maxSeverity == .none {
                        maxSeverity = .warning
                    }
                }
            }
        }

        // Determine if content is valid
        let isValid = maxSeverity != .error

        return ContentValidationResult(
            isValid: isValid,
            flaggedTerms: flaggedTerms,
            suggestions: suggestions,
            severity: maxSeverity
        )
    }

    func getRedFlagTerms() -> [String] {
        return RedFlagTerm.allTermStrings
    }

    func getAlternative(for term: String) -> String? {
        return RedFlagTerm.alternatives[term.lowercased()]
    }
}
