//
//  LLMCoachingService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach: LLM-Powered Coaching Suggestions
//
//  Uses Apple Intelligence (iOS 18.1+) to generate personalized,
//  context-aware coaching suggestions for parents.
//

import Foundation
import NaturalLanguage

/// Service for generating coaching suggestions using on-device LLM
@available(iOS 18.0, *)
class LLMCoachingService {

    // MARK: - Singleton

    static let shared = LLMCoachingService()

    // MARK: - Properties

    private let isAppleIntelligenceAvailable: Bool
    private var groqAPIKey: String?
    private let groqAPIURL = "https://api.groq.com/openai/v1/chat/completions"
    private let groqModel = "llama-3.1-8b-instant"  // Ultra-fast Groq model for real-time suggestions

    // Caching for optimization
    private var lastArousalBand: ArousalBand?
    private var lastSuggestions: [String] = []
    private var lastRequestTime: Date?

    // MARK: - Initialization

    private init() {
        // Check if Apple Intelligence is available
        // This requires iOS 18.1+ and compatible device (A17 Pro or M1+)
        if #available(iOS 18.1, *) {
            isAppleIntelligenceAvailable = Self.checkAppleIntelligenceAvailability()
        } else {
            isAppleIntelligenceAvailable = false
        }

        // Load Groq API key from keychain
        loadAPIKey()

        // TEMPORARY: Auto-configure API key if not set
        // TODO: Move to settings UI
        if groqAPIKey == nil {
            let apiKey = "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"
            configureGroqAPI(apiKey: apiKey)
        }

        if isAppleIntelligenceAvailable {
            print("✅ Apple Intelligence available - using on-device LLM")
        } else if groqAPIKey != nil {
            print("✅ Groq API configured - using Llama 3.1 8B Instant")
        } else {
            print("⚠️ No LLM available - will use rule-based suggestions")
        }
    }

    // MARK: - Configuration

    /// Configure Groq API key for cloud LLM suggestions
    func configureGroqAPI(apiKey: String) {
        self.groqAPIKey = apiKey
        saveAPIKey(apiKey)
        print("✅ Groq API key configured")
    }

    private func loadAPIKey() {
        if let data = try? KeychainManager.shared.load(key: "groq_api_key"),
           let key = String(data: data, encoding: .utf8) {
            self.groqAPIKey = key
        }
    }

    private func saveAPIKey(_ key: String) {
        if let data = key.data(using: .utf8) {
            try? KeychainManager.shared.save(data: data, forKey: "groq_api_key", accessible: .whenUnlocked)
        }
    }

    // MARK: - Public Methods

    /// Generate coaching suggestions with educational resources
    func generateSuggestionsWithResources(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        childName: String?
    ) async -> [CoachingSuggestionWithResource] {
        let suggestions = await generateSuggestions(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress,
            childName: childName
        )

        return suggestions.map { enrichWithResource($0) }
    }

    /// Generate coaching suggestions using LLM
    func generateSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        childName: String?
    ) async -> [String] {
        // Optimization: Check if arousal band has changed
        // If same as last request and we have cached suggestions, return them
        if let lastBand = lastArousalBand,
           lastBand == arousalBand,
           !lastSuggestions.isEmpty,
           let lastTime = lastRequestTime,
           Date().timeIntervalSince(lastTime) < 10 {  // Cache for 10 seconds
            print("♻️ Using cached suggestions (arousal unchanged: \(arousalBand.displayName))")
            return lastSuggestions
        }

        // Arousal has changed or cache expired - generate new suggestions
        print("🔄 Arousal changed: \(lastArousalBand?.displayName ?? "none") → \(arousalBand.displayName)")

        // Priority 1: Use Apple Intelligence if available (on-device)
        if isAppleIntelligenceAvailable {
            if #available(iOS 18.1, *) {
                let suggestions = await generateAppleIntelligenceSuggestions(
                    arousalBand: arousalBand,
                    behaviors: behaviors,
                    environmentContext: environmentContext,
                    parentStress: parentStress,
                    childName: childName
                )
                updateCache(arousalBand: arousalBand, suggestions: suggestions)
                return suggestions
            }
        }

        // Priority 2: Use Groq API if configured (cloud)
        if let apiKey = groqAPIKey, !apiKey.isEmpty {
            print("🤖 Calling Groq API for coaching suggestions...")
            do {
                let suggestions = try await generateGroqSuggestions(
                    arousalBand: arousalBand,
                    behaviors: behaviors,
                    environmentContext: environmentContext,
                    parentStress: parentStress,
                    childName: childName
                )
                print("✅ Groq returned \(suggestions.count) suggestions")
                updateCache(arousalBand: arousalBand, suggestions: suggestions)
                return suggestions
            } catch {
                print("⚠️ Groq API error: \(error.localizedDescription) - falling back to rule-based")
            }
        } else {
            print("⚠️ No Groq API key - using rule-based suggestions")
        }

        // Priority 3: Fallback to enhanced rule-based suggestions
        let suggestions = generateEnhancedRuleBasedSuggestions(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress
        )
        updateCache(arousalBand: arousalBand, suggestions: suggestions)
        return suggestions
    }

    /// Update cache with new suggestions
    private func updateCache(arousalBand: ArousalBand, suggestions: [String]) {
        lastArousalBand = arousalBand
        lastSuggestions = suggestions
        lastRequestTime = Date()
    }

    // MARK: - LLM Generation

    // MARK: - Apple Intelligence (On-Device)

    @available(iOS 18.1, *)
    private func generateAppleIntelligenceSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        childName: String?
    ) async -> [String] {
        // Build context prompt for LLM
        let prompt = buildContextPrompt(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress,
            childName: childName
        )

        // TODO: Use Apple Intelligence API when available
        // For now, use enhanced Natural Language processing
        // Apple Intelligence API will be added when publicly available

        // Placeholder: In production, this would call:
        // let response = try await AppleIntelligence.generate(prompt: prompt)

        // For now, return enhanced rule-based with NLP
        return await generateWithNaturalLanguage(prompt: prompt)
    }

    // MARK: - Groq API (Cloud)

    private func generateGroqSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        childName: String?
    ) async throws -> [String] {
        guard let apiKey = groqAPIKey else {
            throw LLMError.noAPIKey
        }

        // Build prompt
        let prompt = buildContextPrompt(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress,
            childName: childName
        )

        // Call Groq API
        let suggestions = try await callGroqAPI(prompt: prompt, apiKey: apiKey)
        return suggestions
    }

    private func callGroqAPI(prompt: String, apiKey: String) async throws -> [String] {
        guard let url = URL(string: groqAPIURL) else {
            throw LLMError.invalidURL
        }

        print("📤 Sending request to Groq API...")
        print("   Model: \(groqModel)")
        print("   Prompt length: \(prompt.count) chars")

        // Build request body (OpenAI-compatible format)
        let requestBody: [String: Any] = [
            "model": groqModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request
        print("⏳ Waiting for Groq response...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📥 Received response from Groq")

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Groq API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw LLMError.apiError(httpResponse.statusCode, errorMessage)
        }

        // Parse response (OpenAI format)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw LLMError.parseError
        }

        // Extract suggestions from text
        return parseSuggestions(from: text)
    }

    private func parseSuggestions(from text: String) -> [String] {
        // Split by numbered lines (1., 2., 3. or 1) 2) 3))
        let pattern = "(?:^|\\n)\\d+[.)\\s]+(.+?)(?=\\n\\d+[.)\\s]+|$)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            // Fallback: split by newlines
            return text.components(separatedBy: "\n")
                .map { cleanMarkdown($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .filter { !$0.isEmpty && !$0.hasPrefix("Suggestions:") && !$0.hasPrefix("Recommendations:") }
                .prefix(3)
                .map { String($0) }
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))

        let suggestions = matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1 else { return nil }
            let range = match.range(at: 1)
            let rawText = nsText.substring(with: range)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleanMarkdown(rawText)
        }

        return Array(suggestions.prefix(3))
    }

    /// Remove markdown formatting from text
    private func cleanMarkdown(_ text: String) -> String {
        var cleaned = text

        // Remove bold markdown (**text** or __text__)
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "__", with: "")

        // Remove italic markdown (*text* or _text_)
        cleaned = cleaned.replacingOccurrences(of: "*", with: "")
        cleaned = cleaned.replacingOccurrences(of: "_", with: "")

        // Remove inline code backticks
        cleaned = cleaned.replacingOccurrences(of: "`", with: "")

        return cleaned
    }

    /// Enrich suggestion with educational resource
    private func enrichWithResource(_ suggestionText: String) -> CoachingSuggestionWithResource {
        let category = categorizeSuggestion(suggestionText)
        let (title, url) = getResourceForCategory(category)

        return CoachingSuggestionWithResource(
            text: suggestionText,
            category: category,
            resourceTitle: title,
            resourceURL: url
        )
    }

    /// Categorize suggestion based on content
    private func categorizeSuggestion(_ text: String) -> CoachingSuggestionWithResource.SuggestionCategory {
        let lowercased = text.lowercased()

        // Check for parent support keywords
        if lowercased.contains("breath") || lowercased.contains("your") || lowercased.contains("yourself") ||
           lowercased.contains("caregiver") || lowercased.contains("parent") || lowercased.contains("oxygen mask") {
            return .parentSupport
        }

        // Check for sensory keywords
        if lowercased.contains("sensory") || lowercased.contains("headphones") || lowercased.contains("noise") ||
           lowercased.contains("pressure") || lowercased.contains("tactile") || lowercased.contains("proprioceptive") {
            return .sensory
        }

        // Check for environmental keywords
        if lowercased.contains("light") || lowercased.contains("environment") || lowercased.contains("space") ||
           lowercased.contains("quiet") || lowercased.contains("visual") {
            return .environmental
        }

        // Check for de-escalation keywords
        if lowercased.contains("safety") || lowercased.contains("crisis") || lowercased.contains("escalat") ||
           lowercased.contains("meltdown") || lowercased.contains("reduce demands") {
            return .deescalation
        }

        // Check for communication keywords
        if lowercased.contains("communicate") || lowercased.contains("express") || lowercased.contains("signal") ||
           lowercased.contains("visual") && lowercased.contains("support") {
            return .communication
        }

        // Check for regulation keywords
        if lowercased.contains("regulat") || lowercased.contains("co-regulation") || lowercased.contains("nervous system") ||
           lowercased.contains("autonomic") {
            return .regulation
        }

        return .general
    }

    /// Get educational resource for category
    private func getResourceForCategory(_ category: CoachingSuggestionWithResource.SuggestionCategory) -> (title: String?, url: String?) {
        switch category {
        case .regulation:
            return (
                "Understanding Co-Regulation",
                "https://www.autismspeaks.org/expert-opinion/co-regulation-tool-supporting-emotional-development"
            )

        case .sensory:
            return (
                "Sensory Processing in Autism",
                "https://www.autism.org.uk/advice-and-guidance/topics/sensory-differences/sensory-differences/all-audiences"
            )

        case .parentSupport:
            return (
                "Caregiver Self-Care Strategies",
                "https://www.autismspeaks.org/caregiver-skills-training"
            )

        case .environmental:
            return (
                "Creating Autism-Friendly Environments",
                "https://www.autism.org.uk/advice-and-guidance/topics/behaviour/meltdowns/autistic-environment"
            )

        case .deescalation:
            return (
                "Crisis Prevention & De-escalation",
                "https://www.autism.org.uk/advice-and-guidance/topics/behaviour/meltdowns/all-audiences"
            )

        case .communication:
            return (
                "Supporting Autistic Communication",
                "https://www.autism.org.uk/advice-and-guidance/topics/communication/communication/all-audiences"
            )

        case .general:
            return (
                "Evidence-Based Autism Support",
                "https://www.autismspeaks.org/tool-kit"
            )
        }
    }

    /// Build context prompt for LLM
    private func buildContextPrompt(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        childName: String?
    ) -> String {
        var prompt = """
        You are a professional neurodiversity-affirming specialist providing evidence-based guidance to a parent supporting their child with special needs (ASD, ADHD, GDD, SPD, etc.).
        Each child will be at different stages of autism specturm and have unique sensory processing needs.

        Clinical Assessment:
        - Arousal regulation state: \(arousalBand.displayName)
        - Observable behaviors: \(behaviors.map { $0.displayName }.joined(separator: ", "))
        - Environmental factors: \(describeEnvironment(environmentContext))
        - Caregiver stress indicators: \(parentStress.displayName)
        """

        if let name = childName {
            prompt += "\n- Child: \(name)"
        }

        prompt += """

        Provide 3 professional, evidence-based intervention recommendations:

        Format requirements:
        - Start each suggestion with an action verb
        - Use clear, professional non-clinical, empathetic language
        - Be direct and specific (avoid casual phrasing)
        - Each recommendation: 1-2 sentences maximum
        - Focus on immediate, practical interventions

        Principles:
        - Neurodiversity-affirming approach (no ABA/compliance terminology)
        - Prioritize autonomic nervous system regulation
        - Consider sensory processing needs
        - Support co-regulation between caregiver and child
        - Evidence-based, trauma-informed strategies

        Priority order:
        1. Most urgent safety/regulation need
        2. Environmental or sensory modification
        3. Caregiver self-regulation support

        Recommendations:

        For reference links make sure that links are from reputable autism organizations such as Autism Speaks or National Autistic Society.
        """
        

        return prompt
    }

    /// Describe environment in natural language
    private func describeEnvironment(_ context: EnvironmentContext) -> String {
        var parts: [String] = []

        parts.append("\(context.lightingLevel.displayName) lighting")
        parts.append("\(context.noiseLevel.displayName) noise")
        parts.append("\(context.visualComplexity.displayName) visual complexity")

        if let crowd = context.crowdDensity {
            parts.append("\(crowd.displayName)")
        }

        return parts.joined(separator: ", ")
    }

    /// Generate suggestions using Natural Language framework
    /// (Placeholder until Apple Intelligence API is public)
    private func generateWithNaturalLanguage(prompt: String) async -> [String] {
        // For now, use enhanced template-based generation
        // This will be replaced with actual LLM API when available

        // Extract key information from prompt
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = prompt

        // Return enhanced suggestions
        // TODO: Replace with actual LLM generation
        return [
            "Analyzing situation with on-device intelligence...",
            "LLM-powered suggestions will appear here when Apple Intelligence API is available.",
            "Currently using enhanced rule-based system."
        ]
    }

    // MARK: - Enhanced Rule-Based Fallback

    private func generateEnhancedRuleBasedSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel
    ) -> [String] {
        var suggestions: [String] = []

        // 1. Parent support (highest priority if stressed)
        if parentStress == .high {
            suggestions.append("Take a breath. Your calm helps them regulate.")
        }

        // 2. Behavior-specific suggestions
        for behavior in behaviors.prefix(2) {
            let behaviorSuggestions = behavior.suggestions(arousal: arousalBand)
            if let first = behaviorSuggestions.first {
                suggestions.append(first)
            }
        }

        // 3. Environmental suggestions
        if !environmentContext.isOptimal {
            let envSuggestions = environmentContext.suggestions
            if let first = envSuggestions.first {
                suggestions.append(first)
            }
        }

        // 4. Arousal-specific
        switch arousalBand {
        case .shutdown:
            if suggestions.isEmpty {
                suggestions.append("Try alerting activities like jumping or dancing.")
            }
        case .green:
            if suggestions.isEmpty {
                suggestions.append("Great regulation! Maintain current environment.")
            }
        case .yellow:
            if suggestions.isEmpty {
                suggestions.append("Early warning signs. Offer movement break or reduce demands.")
            }
        case .orange:
            if suggestions.isEmpty {
                suggestions.append("High arousal. Move to quieter space if possible.")
            }
        case .red:
            if suggestions.isEmpty {
                suggestions.append("Reduce sensory input immediately. Give space. Stay calm.")
            }
        }

        // Limit to 3 suggestions
        return Array(suggestions.prefix(3))
    }

    // MARK: - Availability Check

    private static func checkAppleIntelligenceAvailability() -> Bool {
        // Check for Apple Intelligence availability
        // This requires:
        // 1. iOS 18.1+
        // 2. A17 Pro or M1+ chip
        // 3. Apple Intelligence enabled in settings

        // For now, return false until Apple Intelligence API is public
        // When available, this will check:
        // return AppleIntelligence.isAvailable

        return false
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code, let message):
            return "API error \(code): \(message)"
        case .parseError:
            return "Failed to parse API response"
        }
    }
}

// MARK: - Supporting Types

/// Coaching suggestion with educational resource
struct CoachingSuggestionWithResource {
    let text: String
    let category: SuggestionCategory
    let resourceTitle: String?
    let resourceURL: String?

    enum SuggestionCategory {
        case regulation
        case sensory
        case parentSupport
        case environmental
        case deescalation
        case communication
        case general
    }
}

// MARK: - Future Apple Intelligence Integration

/*
 When Apple Intelligence API becomes publicly available, update this file:

 1. Import Apple Intelligence framework:
    import AppleIntelligence

 2. Update generateLLMSuggestions():
    let response = try await AppleIntelligence.generate(
        prompt: prompt,
        options: .init(
            maxTokens: 150,
            temperature: 0.7,
            onDevice: true  // Ensure on-device processing for privacy
        )
    )

 3. Update checkAppleIntelligenceAvailability():
    return AppleIntelligence.isAvailable && AppleIntelligence.isOnDeviceAvailable

 4. Parse LLM response into suggestions array

 Privacy Note: All LLM processing will be on-device only.
 No data sent to cloud services.
 */
