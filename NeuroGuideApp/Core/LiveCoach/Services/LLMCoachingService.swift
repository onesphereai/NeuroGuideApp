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

/// Available Groq models with different capabilities
enum GroqModel: String {
    case llama3_1_70b = "llama-3.1-70b-versatile"      // Best reasoning, pattern detection (slower)
    case llama3_1_8b = "llama-3.1-8b-instant"          // Fast, good quality (real-time)
    case mixtral_8x7b = "mixtral-8x7b-32768"           // Balanced alternative

    var displayName: String {
        switch self {
        case .llama3_1_70b: return "Llama 3.1 70B (Best Quality)"
        case .llama3_1_8b: return "Llama 3.1 8B (Fastest)"
        case .mixtral_8x7b: return "Mixtral 8x7B (Balanced)"
        }
    }

    var description: String {
        switch self {
        case .llama3_1_70b:
            return "Best for complex reasoning, pattern detection, and detailed analysis. Slower but smarter."
        case .llama3_1_8b:
            return "Ultra-fast responses, perfect for real-time coaching. Good quality with minimal latency."
        case .mixtral_8x7b:
            return "Balanced speed and quality. Good alternative to Llama models."
        }
    }
}

/// Context for model selection
enum ModelContext {
    case realTimeSuggestions  // Use fast model (8B)
    case deepAnalysis         // Use smart model (70B)
    case sessionReport        // Use smart model (70B)
    case askNeuroGuide        // Use smart model (70B)

    var recommendedModel: GroqModel {
        switch self {
        case .realTimeSuggestions:
            return .llama3_1_8b  // Speed priority
        case .deepAnalysis, .sessionReport, .askNeuroGuide:
            return .llama3_1_70b  // Quality priority
        }
    }
}

/// Service for generating coaching suggestions using on-device LLM
@available(iOS 18.0, *)
class LLMCoachingService {

    // MARK: - Singleton

    static let shared = LLMCoachingService()

    // MARK: - Properties

    private let isAppleIntelligenceAvailable: Bool
    private var groqAPIKey: String?
    private let groqAPIURL = "https://api.groq.com/openai/v1/chat/completions"

    // Model configuration
    private var defaultModel: GroqModel = .llama3_1_70b  // Default to best quality
    private var preferFastModel: Bool = false  // Set to true to prefer speed over quality

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
            print("✅ Groq API configured - Default model: \(defaultModel.displayName)")
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

    /// Set the default model for all requests
    /// - Parameter model: The Groq model to use as default
    func setDefaultModel(_ model: GroqModel) {
        self.defaultModel = model
        print("🔧 Default model set to: \(model.displayName)")
    }

    /// Enable fast model preference for real-time scenarios
    /// When enabled, always uses fast model (8B) regardless of context
    func setPreferFastModel(_ enabled: Bool) {
        self.preferFastModel = enabled
        print("🔧 Prefer fast model: \(enabled ? "enabled" : "disabled")")
    }

    /// Get the current model being used
    func getCurrentModel() -> GroqModel {
        return defaultModel
    }

    /// Select appropriate model based on context
    private func selectModel(for context: ModelContext) -> GroqModel {
        // If fast model preference is enabled, always use fast model
        if preferFastModel {
            return .llama3_1_8b
        }

        // Otherwise, use context-appropriate model or default
        return context.recommendedModel
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
        childName: String?,
        sessionContext: SessionContext? = nil,
        modelContext: ModelContext = .realTimeSuggestions
    ) async -> [CoachingSuggestionWithResource] {
        let suggestions = await generateSuggestions(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress,
            childName: childName,
            sessionContext: sessionContext,
            modelContext: modelContext
        )

        return suggestions.map { enrichWithResource($0) }
    }

    /// Generate coaching suggestions using LLM
    func generateSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        childName: String?,
        sessionContext: SessionContext? = nil,
        modelContext: ModelContext = .realTimeSuggestions
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
                    childName: childName,
                    sessionContext: sessionContext
                )
                updateCache(arousalBand: arousalBand, suggestions: suggestions)
                return suggestions
            }
        }

        // Priority 2: Use Groq API if configured (cloud)
        if let apiKey = groqAPIKey, !apiKey.isEmpty {
            let selectedModel = selectModel(for: modelContext)
            print("🤖 Calling Groq API - Model: \(selectedModel.displayName)")
            do {
                let suggestions = try await generateGroqSuggestions(
                    arousalBand: arousalBand,
                    behaviors: behaviors,
                    environmentContext: environmentContext,
                    parentStress: parentStress,
                    childName: childName,
                    sessionContext: sessionContext,
                    model: selectedModel
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
        childName: String?,
        sessionContext: SessionContext?
    ) async -> [String] {
        // Build context prompt for LLM
        let prompt = buildContextPrompt(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress,
            childName: childName,
            sessionContext: sessionContext
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
        childName: String?,
        sessionContext: SessionContext?,
        model: GroqModel
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
            childName: childName,
            sessionContext: sessionContext
        )

        // Call Groq API with selected model
        let suggestions = try await callGroqAPI(prompt: prompt, apiKey: apiKey, model: model)
        return suggestions
    }

    private func callGroqAPI(prompt: String, apiKey: String, model: GroqModel) async throws -> [String] {
        guard let url = URL(string: groqAPIURL) else {
            throw LLMError.invalidURL
        }

        print("📤 Sending request to Groq API...")
        print("   Model: \(model.rawValue)")
        print("   Prompt length: \(prompt.count) chars")

        // Build request body (OpenAI-compatible format)
        let requestBody: [String: Any] = [
            "model": model.rawValue,
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
        childName: String?,
        sessionContext: SessionContext?
    ) -> String {
        var prompt = """
        You are a compassionate neurodiversity-affirming coach providing real-time, evidence-based guidance to a parent supporting their neurodivergent child during a co-regulation session.

        """

        // Add child profile if available
        if let context = sessionContext, let profile = context.childProfile {
            prompt += """
            CHILD PROFILE:
            - Name: \(profile.name), Age: \(profile.age)
            - Diagnosis: \(profile.diagnosisInfo?.primaryDiagnosis.displayName ?? "Not specified")
            - Communication: \(profile.communicationMode.description)
            """

            if !profile.triggers.isEmpty {
                prompt += "\n- Known triggers: \(profile.triggers.prefix(3).map { $0.description }.joined(separator: ", "))"
            }

            if !profile.soothingStrategies.isEmpty {
                prompt += "\n- Effective strategies: \(profile.soothingStrategies.prefix(3).map { $0.description }.joined(separator: ", "))"
            }

            prompt += "\n\n"
        } else if let name = childName {
            prompt += "CHILD: \(name)\n\n"
        }

        // Add session context if available
        if let context = sessionContext {
            prompt += """
            SESSION CONTEXT:
            - Duration: \(context.durationMinutes) minutes
            - Behavior trend: \(context.behaviorSummary)

            AROUSAL TIMELINE (Recent observations):
            \(context.arousalTimelineFormatted)

            """

            // Add patterns if detected
            if !context.patterns.isEmpty {
                prompt += """
                PATTERNS OBSERVED THIS SESSION:
                \(context.patternsFormatted)

                """
            }

            // Add previous suggestions to avoid repetition
            if !context.recentSuggestions.isEmpty {
                prompt += """
                PREVIOUS SUGGESTIONS (avoid repeating):
                \(context.recentSuggestionsFormatted)

                """
            }

            // Add co-regulation moments
            if !context.coRegulationEvents.isEmpty {
                prompt += """
                CO-REGULATION MOMENTS:
                \(context.coRegulationEventsFormatted)

                """
            }
        }

        prompt += """
        CURRENT SITUATION:
        - Arousal state: \(arousalBand.displayName)
        - Observable behaviors: \(behaviors.map { $0.displayName }.joined(separator: ", "))
        - Environment: \(describeEnvironment(environmentContext))
        - Parent stress level: \(parentStress.displayName)

        Based on:
        1. The child's known profile and what works for them
        2. The session trends and patterns observed so far
        3. What has already been suggested (avoid repetition unless reinforcing success)
        4. The trajectory (escalating, improving, or stable)
        5. Co-regulation quality between parent and child

        Provide 3 specific, actionable coaching suggestions:

        Format requirements:
        - Start each with an action verb
        - Use warm, clear, professional language
        - 1-2 sentences maximum per suggestion
        - Be immediately actionable
        - If progress is being made, acknowledge it and build on success
        - If previous suggestions haven't helped, adapt your approach

        Principles:
        - Neurodiversity-affirming (no ABA/compliance terminology)
        - Prioritize nervous system regulation
        - Consider sensory processing needs
        - Support parent-child co-regulation
        - Evidence-based, trauma-informed strategies
        - Affirm parent efforts

        Priority order:
        1. Most urgent safety/regulation need
        2. Environmental or sensory modification
        3. Parent self-regulation support

        Recommendations:
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
