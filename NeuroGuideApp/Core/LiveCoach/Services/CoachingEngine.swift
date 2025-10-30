//
//  CoachingEngine.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach: Context-Aware Coaching Suggestion Generation
//

import Foundation

/// Generates neurodiversity-affirming coaching suggestions based on context
class CoachingEngine {

    // MARK: - Properties

    private var useLLM: Bool = true  // Enable LLM-powered suggestions if available
    private var childName: String?

    // MARK: - Configuration

    func configure(useLLM: Bool, childName: String?) {
        self.useLLM = useLLM
        self.childName = childName
    }

    // MARK: - Main Suggestion Generation

    /// Generate prioritized coaching suggestions based on current context
    func generateSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel
    ) async -> [CoachingSuggestion] {
        // Try LLM-powered suggestions first (if enabled and available)
        if useLLM, #available(iOS 18.0, *) {
            let llmSuggestions = await generateLLMSuggestions(
                arousalBand: arousalBand,
                behaviors: behaviors,
                environmentContext: environmentContext,
                parentStress: parentStress
            )

            if !llmSuggestions.isEmpty {
                return llmSuggestions
            }
        }

        // Fallback to rule-based suggestions
        return await generateRuleBasedSuggestions(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress
        )
    }

    // MARK: - LLM-Powered Suggestions

    @available(iOS 18.0, *)
    private func generateLLMSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel
    ) async -> [CoachingSuggestion] {
        let llmService = LLMCoachingService.shared

        let suggestionsText = await llmService.generateSuggestions(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress,
            childName: childName
        )

        // Convert text suggestions to CoachingSuggestion objects
        return suggestionsText.enumerated().map { index, text in
            let priority: CoachingSuggestion.Priority = index == 0 ? .high : .medium
            let category: CoachingSuggestion.SuggestionCategory = determineCategoryFromText(text)

            return CoachingSuggestion(
                text: text,
                category: category,
                priority: priority,
                sourceAttribution: "AI-powered coaching"
            )
        }
    }

    /// Determine suggestion category from text content
    private func determineCategoryFromText(_ text: String) -> CoachingSuggestion.SuggestionCategory {
        let lowercased = text.lowercased()

        if lowercased.contains("breath") || lowercased.contains("your") || lowercased.contains("yourself") {
            return .parentSupport
        } else if lowercased.contains("noise") || lowercased.contains("light") || lowercased.contains("environment") {
            return .environmental
        } else if lowercased.contains("safety") || lowercased.contains("hazard") {
            return .deescalation
        } else if lowercased.contains("sensory") || lowercased.contains("headphones") {
            return .sensory
        } else {
            return .regulation
        }
    }

    // MARK: - Rule-Based Suggestions

    private func generateRuleBasedSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel
    ) async -> [CoachingSuggestion] {
        var suggestions: [CoachingSuggestion] = []

        // 1. Parent support (HIGHEST PRIORITY if parent stress is high)
        if parentStress == .high {
            suggestions.append(contentsOf: generateParentSupportSuggestions())
        }

        // 2. Behavior-specific suggestions
        for behavior in behaviors {
            suggestions.append(contentsOf: generateBehaviorSuggestions(
                behavior: behavior,
                arousal: arousalBand
            ))
        }

        // 3. Environmental suggestions
        suggestions.append(contentsOf: generateEnvironmentalSuggestions(
            context: environmentContext
        ))

        // 4. Arousal-based suggestions
        suggestions.append(contentsOf: generateArousalBasedSuggestions(
            arousalBand: arousalBand
        ))

        // 5. Remove duplicates and prioritize
        let uniqueSuggestions = removeDuplicates(suggestions)
        let prioritized = prioritizeSuggestions(uniqueSuggestions)

        // 6. Limit to top 3 suggestions (avoid overwhelming parent)
        return Array(prioritized.prefix(3))
    }

    // MARK: - Parent Support Suggestions

    private func generateParentSupportSuggestions() -> [CoachingSuggestion] {
        return [
            CoachingSuggestion(
                text: "Take a breath. Your calm helps them regulate.",
                category: .parentSupport,
                priority: .high,
                sourceAttribution: "Co-regulation research"
            ),
            CoachingSuggestion(
                text: "It's okay to step back for a moment. Put your oxygen mask on first.",
                category: .parentSupport,
                priority: .high
            )
        ]
    }

    // MARK: - Behavior-Specific Suggestions

    private func generateBehaviorSuggestions(
        behavior: ChildBehavior,
        arousal: ArousalBand
    ) -> [CoachingSuggestion] {
        let behaviorSuggestions = behavior.suggestions(arousal: arousal)

        return behaviorSuggestions.prefix(2).map { text in
            let priority: CoachingSuggestion.Priority

            // High priority for safety-related behaviors
            if behavior == .meltdown || behavior == .escalating {
                priority = .high
            } else if behavior == .coveringEars || behavior == .retreating {
                priority = .medium
            } else {
                priority = .low
            }

            let category: CoachingSuggestion.SuggestionCategory
            if behavior == .meltdown {
                category = .deescalation
            } else if behavior == .coveringEars || behavior == .seekingPressure {
                category = .sensory
            } else {
                category = .regulation
            }

            return CoachingSuggestion(
                text: text,
                category: category,
                priority: priority,
                sourceAttribution: "Neurodiversity-affirming practices"
            )
        }
    }

    // MARK: - Environmental Suggestions

    private func generateEnvironmentalSuggestions(
        context: EnvironmentContext
    ) -> [CoachingSuggestion] {
        var suggestions: [CoachingSuggestion] = []

        // Lighting suggestions
        if !context.lightingLevel.isOptimal {
            let suggestion = context.lightingLevel.suggestion
            if !suggestion.isEmpty {
                suggestions.append(CoachingSuggestion(
                    text: suggestion,
                    category: .environmental,
                    priority: context.lightingLevel == .flickering ? .high : .medium
                ))
            }
        }

        // Noise suggestions
        if !context.noiseLevel.isOptimal {
            let suggestion = context.noiseLevel.suggestion
            if !suggestion.isEmpty {
                suggestions.append(CoachingSuggestion(
                    text: suggestion,
                    category: .environmental,
                    priority: context.noiseLevel == .veryLoud ? .high : .medium
                ))
            }
        }

        // Visual complexity suggestions
        if let complexitySuggestion = context.visualComplexity.suggestion {
            suggestions.append(CoachingSuggestion(
                text: complexitySuggestion,
                category: .environmental,
                priority: .medium
            ))
        }

        // Crowd density suggestions
        if let crowd = context.crowdDensity, crowd == .crowded {
            suggestions.append(CoachingSuggestion(
                text: "Space is crowded. Consider moving to less populated area.",
                category: .environmental,
                priority: .medium
            ))
        }

        return suggestions
    }

    // MARK: - Arousal-Based Suggestions

    private func generateArousalBasedSuggestions(
        arousalBand: ArousalBand
    ) -> [CoachingSuggestion] {
        switch arousalBand {
        case .shutdown:
            return [
                CoachingSuggestion(
                    text: "Try alerting activities like jumping or dancing.",
                    category: .general,
                    priority: .medium,
                    sourceAttribution: "Alerting strategies"
                ),
                CoachingSuggestion(
                    text: "Engage with preferred sensory input.",
                    category: .sensory,
                    priority: .medium
                )
            ]

        case .green:
            return [
                CoachingSuggestion(
                    text: "Child is regulated. Maintain current environment and routine.",
                    category: .general,
                    priority: .low,
                    sourceAttribution: "Regulation support"
                )
            ]

        case .yellow:
            return [
                CoachingSuggestion(
                    text: "Arousal is building. Offer movement break or reduce demands.",
                    category: .prevention,
                    priority: .medium,
                    sourceAttribution: "Preventive intervention"
                ),
                CoachingSuggestion(
                    text: "Give 5-minute warning before any transitions.",
                    category: .prevention,
                    priority: .medium
                ),
                CoachingSuggestion(
                    text: "This is NOT a crisis yet - preventive support can help.",
                    category: .prevention,
                    priority: .low
                )
            ]

        case .orange:
            return [
                CoachingSuggestion(
                    text: "High arousal detected. Move to quieter space if possible.",
                    category: .deescalation,
                    priority: .high
                ),
                CoachingSuggestion(
                    text: "Offer deep pressure or weighted item.",
                    category: .sensory,
                    priority: .high
                ),
                CoachingSuggestion(
                    text: "Reduce demands and sensory input.",
                    category: .deescalation,
                    priority: .medium
                )
            ]

        case .red:
            return [
                CoachingSuggestion(
                    text: "Reduce sensory input immediately. Give space. Stay calm.",
                    category: .deescalation,
                    priority: .high,
                    sourceAttribution: "Crisis de-escalation"
                ),
                CoachingSuggestion(
                    text: "Minimize talking. Your calm presence is more helpful than words.",
                    category: .deescalation,
                    priority: .high
                ),
                CoachingSuggestion(
                    text: "Remove demands and expectations right now.",
                    category: .deescalation,
                    priority: .high
                )
            ]
        }
    }

    // MARK: - Helper Functions

    /// Remove duplicate suggestions
    private func removeDuplicates(_ suggestions: [CoachingSuggestion]) -> [CoachingSuggestion] {
        var seen = Set<String>()
        var unique: [CoachingSuggestion] = []

        for suggestion in suggestions {
            if !seen.contains(suggestion.text) {
                seen.insert(suggestion.text)
                unique.append(suggestion)
            }
        }

        return unique
    }

    /// Prioritize suggestions by priority and category
    private func prioritizeSuggestions(_ suggestions: [CoachingSuggestion]) -> [CoachingSuggestion] {
        return suggestions.sorted { first, second in
            // First: Sort by priority (high > medium > low)
            if first.priority.rawValue != second.priority.rawValue {
                return first.priority.rawValue > second.priority.rawValue
            }

            // Second: Within same priority, prioritize certain categories
            let categoryOrder: [CoachingSuggestion.SuggestionCategory] = [
                .parentSupport,     // Parent's well-being first
                .deescalation,      // Safety second
                .sensory,           // Immediate sensory needs third
                .environmental,     // Environment modifications
                .prevention,        // Preventive measures
                .regulation,        // Support regulation
                .recovery,          // Recovery support
                .communication,     // Communication support
                .general            // General advice last
            ]

            guard let firstIndex = categoryOrder.firstIndex(of: first.category),
                  let secondIndex = categoryOrder.firstIndex(of: second.category) else {
                return false
            }

            return firstIndex < secondIndex
        }
    }
}

// MARK: - Context-Specific Coaching Scenarios

extension CoachingEngine {

    /// Generate coaching for specific common scenarios
    func generateScenarioSuggestions(scenario: CommonScenario) -> [CoachingSuggestion] {
        switch scenario {
        case .transitionDifficulty:
            return [
                CoachingSuggestion(
                    text: "Give 5-minute warning. Use visual timer if available.",
                    category: .prevention,
                    priority: .high
                ),
                CoachingSuggestion(
                    text: "Offer transition object (can bring one toy to next activity).",
                    category: .communication,
                    priority: .medium
                ),
                CoachingSuggestion(
                    text: "Connection over compliance. Respect their need to finish.",
                    category: .general,
                    priority: .low
                )
            ]

        case .sensoryOverload:
            return [
                CoachingSuggestion(
                    text: "Leave overwhelming environment NOW or move to quiet space.",
                    category: .sensory,
                    priority: .high
                ),
                CoachingSuggestion(
                    text: "Offer noise-canceling headphones, dim lights, reduce talking.",
                    category: .sensory,
                    priority: .high
                ),
                CoachingSuggestion(
                    text: "This is sensory overwhelm, not misbehavior. Respond with support.",
                    category: .general,
                    priority: .medium
                )
            ]

        case .meltdownInProgress:
            return [
                CoachingSuggestion(
                    text: "SAFETY FIRST: Remove hazards, give space unless danger.",
                    category: .deescalation,
                    priority: .high
                ),
                CoachingSuggestion(
                    text: "Your calm is critical. Breathe. Don't reason or restrain.",
                    category: .parentSupport,
                    priority: .high
                ),
                CoachingSuggestion(
                    text: "This will pass. No consequences during meltdown.",
                    category: .deescalation,
                    priority: .medium
                )
            ]

        case .joyfulStimming:
            return [
                CoachingSuggestion(
                    text: "This is joyful expression! Allow stimming - no intervention needed.",
                    category: .regulation,
                    priority: .low
                ),
                CoachingSuggestion(
                    text: "Ensure safe space for movement. Celebrate their joy with them.",
                    category: .general,
                    priority: .low
                )
            ]
        }
    }

    enum CommonScenario {
        case transitionDifficulty
        case sensoryOverload
        case meltdownInProgress
        case joyfulStimming
    }
}
