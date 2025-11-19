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

/// Available LLM models with different capabilities
enum LLMModel: String {
    // Claude models (Anthropic)
    case claudeSonnet4 = "claude-sonnet-4-20250514"    // Claude Sonnet 4.5 - Best quality and reasoning
    case claudeHaiku = "claude-3-5-haiku-20241022"     // Claude Haiku - Fast and efficient

    // Groq models (legacy support)
    case llama3_1_70b = "llama-3.1-70b-versatile"      // Best reasoning, pattern detection (slower)
    case llama3_1_8b = "llama-3.1-8b-instant"          // Fast, good quality (real-time)
    case mixtral_8x7b = "mixtral-8x7b-32768"           // Balanced alternative

    var displayName: String {
        switch self {
        case .claudeSonnet4: return "Claude Sonnet 4.5 (Best Quality)"
        case .claudeHaiku: return "Claude Haiku (Fast)"
        case .llama3_1_70b: return "Llama 3.1 70B (Best Quality)"
        case .llama3_1_8b: return "Llama 3.1 8B (Fastest)"
        case .mixtral_8x7b: return "Mixtral 8x7B (Balanced)"
        }
    }

    var description: String {
        switch self {
        case .claudeSonnet4:
            return "Claude Sonnet 4.5 - Most advanced reasoning and context understanding. Recommended for best quality."
        case .claudeHaiku:
            return "Claude Haiku - Fast responses with good quality. Efficient for real-time use."
        case .llama3_1_70b:
            return "Best for complex reasoning, pattern detection, and detailed analysis. Slower but smarter."
        case .llama3_1_8b:
            return "Ultra-fast responses, perfect for real-time coaching. Good quality with minimal latency."
        case .mixtral_8x7b:
            return "Balanced speed and quality. Good alternative to Llama models."
        }
    }

    var provider: LLMProvider {
        switch self {
        case .claudeSonnet4, .claudeHaiku:
            return .claude
        case .llama3_1_70b, .llama3_1_8b, .mixtral_8x7b:
            return .groq
        }
    }
}

/// Context for model selection
enum ModelContext {
    case realTimeSuggestions  // Use fast model
    case deepAnalysis         // Use smart model
    case sessionReport        // Use smart model
    case askNeuroGuide        // Use smart model

    func recommendedModel(provider: LLMProvider) -> LLMModel {
        switch provider {
        case .claude:
            // Always try Sonnet 4.5 first (best quality)
            // Fallback to Haiku happens automatically via rate limit tracking
            return .claudeSonnet4
        case .groq:
            switch self {
            case .realTimeSuggestions:
                return .llama3_1_8b  // Speed priority
            case .deepAnalysis, .sessionReport, .askNeuroGuide:
                return .llama3_1_70b  // Quality priority
            }
        case .appleIntelligence:
            // Apple Intelligence doesn't use these models, return a default
            return .claudeSonnet4
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
    private var claudeAPIKey: String?
    private var groqAPIKey: String?  // Legacy support
    private let claudeAPIURL = "https://api.anthropic.com/v1/messages"
    private let groqAPIURL = "https://api.groq.com/openai/v1/chat/completions"

    // Model configuration
    private var preferredProvider: LLMProvider = .claude  // Default to Claude
    private var defaultModel: LLMModel = .claudeSonnet4  // Default to best quality
    private var preferFastModel: Bool = false  // Set to true to prefer speed over quality

    // Rate limit tracking
    private var sonnetRequestCount: Int = 0
    private var sonnetRateLimitResetTime: Date?
    private var isUsingSonnetFallback: Bool = false
    private let sonnetRateLimit = 50  // 50 requests per minute
    private let rateLimitWindow: TimeInterval = 60  // 1 minute

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

        // Load API keys from keychain
        loadAPIKeys()

        if isAppleIntelligenceAvailable {
            print("✅ Apple Intelligence available - using on-device LLM")
        } else if claudeAPIKey != nil {
            print("✅ Claude API configured - Default model: \(defaultModel.displayName)")
        } else if groqAPIKey != nil {
            print("✅ Groq API configured (legacy) - Default model: \(defaultModel.displayName)")
        } else {
            print("⚠️ No LLM API key configured - will use rule-based suggestions")
            print("   Configure API key in Settings > Live Coach > API Configuration")
        }
    }

    // MARK: - Configuration

    /// Set the preferred LLM provider
    /// - Parameter provider: The LLM provider to use (Claude or Groq)
    func setPreferredProvider(_ provider: LLMProvider) {
        self.preferredProvider = provider
        // Update default model based on provider
        switch provider {
        case .claude:
            self.defaultModel = .claudeSonnet4
        case .groq:
            self.defaultModel = .llama3_1_70b
        case .appleIntelligence:
            self.defaultModel = .claudeSonnet4 // Fallback
        }
        print("🔧 Preferred provider set to: \(provider)")
    }

    /// Set the default model for all requests
    /// - Parameter model: The LLM model to use as default
    func setDefaultModel(_ model: LLMModel) {
        self.defaultModel = model
        self.preferredProvider = model.provider
        print("🔧 Default model set to: \(model.displayName)")
    }

    /// Enable fast model preference for real-time scenarios
    /// When enabled, always uses fast model regardless of context
    func setPreferFastModel(_ enabled: Bool) {
        self.preferFastModel = enabled
        print("🔧 Prefer fast model: \(enabled ? "enabled" : "disabled")")
    }

    /// Get the current model being used
    func getCurrentModel() -> LLMModel {
        return defaultModel
    }

    /// Get rate limit status for monitoring
    func getRateLimitStatus() -> (requests: Int, limit: Int, isUsingFallback: Bool, resetTime: Date?) {
        return (sonnetRequestCount, sonnetRateLimit, isUsingSonnetFallback, sonnetRateLimitResetTime)
    }

    /// Manually reset rate limit counter (for testing or administrative purposes)
    func resetRateLimit() {
        sonnetRequestCount = 0
        sonnetRateLimitResetTime = nil
        isUsingSonnetFallback = false
        print("✅ Rate limit manually reset")
    }

    /// Select appropriate model based on context and rate limits
    private func selectModel(for context: ModelContext, provider: LLMProvider) -> LLMModel {
        // If fast model preference is enabled, always use fast model for the provider
        if preferFastModel {
            return provider == .claude ? .claudeHaiku : .llama3_1_8b
        }

        // For Claude provider, check rate limits and use fallback strategy
        if provider == .claude {
            return selectClaudeModelWithRateLimitFallback(for: context)
        }

        // Otherwise, use context-appropriate model for the provider
        return context.recommendedModel(provider: provider)
    }

    /// Select Claude model with automatic fallback on rate limit
    private func selectClaudeModelWithRateLimitFallback(for context: ModelContext) -> LLMModel {
        // Reset rate limit counter if window has passed
        if let resetTime = sonnetRateLimitResetTime, Date() > resetTime {
            sonnetRequestCount = 0
            sonnetRateLimitResetTime = nil
            isUsingSonnetFallback = false
            print("✅ Rate limit window reset - back to Sonnet 4.5")
        }

        // Check if we've hit the rate limit
        if sonnetRequestCount >= sonnetRateLimit {
            if !isUsingSonnetFallback {
                print("⚠️ Sonnet 4.5 rate limit reached (\(sonnetRateLimit) req/min) - falling back to Haiku")
                isUsingSonnetFallback = true
            }
            return .claudeHaiku  // Fallback to fast model
        }

        // Always try Sonnet 4.5 first (best quality)
        let recommendedModel = context.recommendedModel(provider: .claude)

        // Track Sonnet 4.5 usage for rate limiting
        if recommendedModel == .claudeSonnet4 {
            sonnetRequestCount += 1

            // Set reset time if this is the first request in the window
            if sonnetRateLimitResetTime == nil {
                sonnetRateLimitResetTime = Date().addingTimeInterval(rateLimitWindow)
            }

            print("📊 Sonnet 4.5 requests: \(sonnetRequestCount)/\(sonnetRateLimit)")
        }

        return recommendedModel
    }

    private func loadAPIKeys() {
        // Load API keys from SettingsManager (which uses Keychain)
        let settings = SettingsManager()

        // Load Claude API key (preferred)
        self.claudeAPIKey = settings.claudeAPIKey

        // Load Groq API key (legacy)
        self.groqAPIKey = settings.groqAPIKey

        // Set preferred provider based on what's available
        if claudeAPIKey != nil && !claudeAPIKey!.isEmpty {
            self.preferredProvider = .claude
            self.defaultModel = .claudeSonnet4
        } else if groqAPIKey != nil && !groqAPIKey!.isEmpty {
            self.preferredProvider = .groq
            self.defaultModel = .llama3_1_70b
        }
    }

    private func saveAPIKey(_ key: String, provider: LLMProvider) {
        if let data = key.data(using: .utf8) {
            let keychainKey: String
            switch provider {
            case .claude:
                keychainKey = "claude_api_key"
            case .groq:
                keychainKey = "groq_api_key"
            case .appleIntelligence:
                return // Apple Intelligence doesn't use API keys
            }
            // Use whenUnlockedThisDeviceOnly for maximum security (not backed up to iCloud)
            try? KeychainManager.shared.save(data: data, forKey: keychainKey, accessible: .whenUnlockedThisDeviceOnly)
        }
    }

    /// Check if API key is configured for the preferred provider
    func hasAPIKey() -> Bool {
        switch preferredProvider {
        case .claude:
            return claudeAPIKey != nil && !claudeAPIKey!.isEmpty
        case .groq:
            return groqAPIKey != nil && !groqAPIKey!.isEmpty
        case .appleIntelligence:
            return true // Apple Intelligence doesn't require API keys
        }
    }

    /// Clear API key from memory and keychain
    func clearAPIKey(provider: LLMProvider) {
        switch provider {
        case .claude:
            claudeAPIKey = nil
            try? KeychainManager.shared.delete(key: "claude_api_key")
            print("✅ Claude API key cleared")
        case .groq:
            groqAPIKey = nil
            try? KeychainManager.shared.delete(key: "groq_api_key")
            print("✅ Groq API key cleared")
        case .appleIntelligence:
            print("⚠️ Apple Intelligence doesn't use API keys")
        }
    }

    /// Validate API key format (basic check)
    private func isValidAPIKey(_ key: String, provider: LLMProvider) -> Bool {
        switch provider {
        case .claude:
            // Claude API keys start with "sk-ant-" and are variable length
            return key.hasPrefix("sk-ant-") && key.count > 20
        case .groq:
            // Groq API keys start with "gsk_" and are 56 characters long
            return key.hasPrefix("gsk_") && key.count == 56
        case .appleIntelligence:
            // Apple Intelligence doesn't use API keys
            return false
        }
    }

    /// Configure Claude API key with validation
    func configureClaudeAPI(apiKey: String) throws {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidAPIKey(trimmedKey, provider: .claude) else {
            throw LLMError.invalidAPIKey
        }

        self.claudeAPIKey = trimmedKey
        saveAPIKey(trimmedKey, provider: .claude)
        self.preferredProvider = .claude
        self.defaultModel = .claudeSonnet4
        print("✅ Claude API key configured and saved securely")
    }

    /// Configure Groq API key with validation (legacy support)
    func configureGroqAPI(apiKey: String) throws {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidAPIKey(trimmedKey, provider: .groq) else {
            throw LLMError.invalidAPIKey
        }

        self.groqAPIKey = trimmedKey
        saveAPIKey(trimmedKey, provider: .groq)
        self.preferredProvider = .groq
        self.defaultModel = .llama3_1_70b
        print("✅ Groq API key configured and saved securely")
    }

    // MARK: - Public Methods

    /// Generate dual coaching suggestions (child + parent) with authentic resource links
    func generateDualSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        childName: String?,
        sessionContext: SessionContext? = nil,
        modelContext: ModelContext = .realTimeSuggestions
    ) async -> DualCoachingSuggestions? {
        print("🔄 Generating dual suggestions (child + parent)...")

        // Build context prompt (already updated to request dual format)
        let prompt = buildContextPrompt(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress,
            childName: childName,
            sessionContext: sessionContext
        )

        // Try Claude first (preferred)
        if let apiKey = claudeAPIKey, !apiKey.isEmpty {
            let selectedModel = selectModel(for: modelContext, provider: .claude)
            print("🤖 Calling Claude API for dual suggestions - Model: \(selectedModel.displayName)")
            do {
                let suggestions = try await callClaudeForDualSuggestions(
                    prompt: prompt,
                    apiKey: apiKey,
                    model: selectedModel
                )
                return suggestions
            } catch {
                print("⚠️ Claude API error: \(error.localizedDescription)")
            }
        }

        // Fallback: generate separate suggestions for child and parent
        print("⚠️ Falling back to separate suggestions")
        let suggestions = await generateSuggestions(
            arousalBand: arousalBand,
            behaviors: behaviors,
            environmentContext: environmentContext,
            parentStress: parentStress,
            childName: childName,
            sessionContext: sessionContext,
            modelContext: modelContext
        )

        guard let firstSuggestion = suggestions.first else { return nil }

        // Create child suggestion with fallback resources
        let childSuggestion = enrichWithResource(firstSuggestion)

        // Create parent suggestion
        let parentSuggestion = CoachingSuggestionWithResource(
            text: "Take a moment to check in with yourself. Notice your breath and your body.",
            category: .parentSupport,
            resourceTitle: "Caregiver Self-Care Strategies",
            resourceURL: "https://www.autismspeaks.org/caregiver-skills-training"
        )

        return DualCoachingSuggestions(
            childSuggestion: childSuggestion,
            parentSuggestion: parentSuggestion
        )
    }

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

        // Priority 2: Use Cloud LLM API if configured (Claude or Groq)
        // Reload API keys to get latest values from SettingsManager
        loadAPIKeys()

        // Try Claude first (preferred), then Groq (legacy)
        if let apiKey = claudeAPIKey, !apiKey.isEmpty {
            let selectedModel = selectModel(for: modelContext, provider: .claude)
            print("🤖 Calling Claude API - Model: \(selectedModel.displayName)")
            print("   API Key: \(apiKey.prefix(10))...")
            do {
                let suggestions = try await generateClaudeSuggestions(
                    arousalBand: arousalBand,
                    behaviors: behaviors,
                    environmentContext: environmentContext,
                    parentStress: parentStress,
                    childName: childName,
                    sessionContext: sessionContext,
                    model: selectedModel
                )
                print("✅ Claude returned \(suggestions.count) suggestions")
                updateCache(arousalBand: arousalBand, suggestions: suggestions)
                return suggestions
            } catch {
                print("⚠️ Claude API error: \(error.localizedDescription) - falling back to rule-based")
            }
        } else {
            print("❌ No Claude API key available")
            if claudeAPIKey == nil {
                print("   claudeAPIKey is nil")
            } else if claudeAPIKey!.isEmpty {
                print("   claudeAPIKey is empty")
            }
        }

        if let apiKey = groqAPIKey, !apiKey.isEmpty {
            let selectedModel = selectModel(for: modelContext, provider: .groq)
            print("🤖 Calling Groq API (legacy) - Model: \(selectedModel.displayName)")
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
            print("⚠️ No LLM API key - using rule-based suggestions")
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

    // MARK: - Claude API (Cloud)

    private func generateClaudeSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        childName: String?,
        sessionContext: SessionContext?,
        model: LLMModel
    ) async throws -> [String] {
        guard let apiKey = claudeAPIKey else {
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

        // Call Claude API with selected model
        let suggestions = try await callClaudeAPI(prompt: prompt, apiKey: apiKey, model: model)
        return suggestions
    }

    private func callClaudeAPI(prompt: String, apiKey: String, model: LLMModel) async throws -> [String] {
        guard let url = URL(string: claudeAPIURL) else {
            throw LLMError.invalidURL
        }

        print("📤 Sending request to Claude API...")
        print("   Model: \(model.rawValue)")
        print("   Prompt length: \(prompt.count) chars")

        // Build request body (Claude format)
        let requestBody: [String: Any] = [
            "model": model.rawValue,
            "max_tokens": 1024,
            "temperature": 0.7,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request
        print("⏳ Waiting for Claude response...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📥 Received response from Claude")

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        // Handle rate limit error (429)
        if httpResponse.statusCode == 429 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Rate limit exceeded"
            print("❌ Claude API rate limit (429): \(errorMessage)")

            // Force immediate fallback to Haiku for future requests
            if model == .claudeSonnet4 {
                sonnetRequestCount = sonnetRateLimit  // Max out counter
                isUsingSonnetFallback = true
                print("⚠️ Forcing fallback to Haiku due to 429 error")
            }

            throw LLMError.apiError(429, "Rate limit exceeded - will use Haiku for next requests")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Claude API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw LLMError.apiError(httpResponse.statusCode, errorMessage)
        }

        // Parse response (Claude format)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            print("❌ Failed to parse Claude response JSON")
            throw LLMError.parseError
        }

        // Debug: Log what Claude returned
        print("📝 Claude response text:")
        print("   \(text.prefix(200))...")

        // Extract suggestions from text
        let suggestions = parseSuggestions(from: text)
        print("✅ Parsed \(suggestions.count) suggestion(s) from Claude response")

        return suggestions
    }

    private func callClaudeForDualSuggestions(prompt: String, apiKey: String, model: LLMModel) async throws -> DualCoachingSuggestions? {
        guard let url = URL(string: claudeAPIURL) else {
            throw LLMError.invalidURL
        }

        print("📤 Sending request to Claude API for dual suggestions...")
        print("   Model: \(model.rawValue)")

        // Build request body (Claude format)
        let requestBody: [String: Any] = [
            "model": model.rawValue,
            "max_tokens": 1536,  // More tokens for dual suggestions
            "temperature": 0.7,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request
        print("⏳ Waiting for Claude dual response...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📥 Received dual response from Claude")

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        // Handle rate limit error (429)
        if httpResponse.statusCode == 429 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Rate limit exceeded"
            print("❌ Claude API rate limit (429): \(errorMessage)")

            if model == .claudeSonnet4 {
                sonnetRequestCount = sonnetRateLimit
                isUsingSonnetFallback = true
                print("⚠️ Forcing fallback to Haiku due to 429 error")
            }

            throw LLMError.apiError(429, "Rate limit exceeded")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Claude API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw LLMError.apiError(httpResponse.statusCode, errorMessage)
        }

        // Parse response (Claude format)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            print("❌ Failed to parse Claude response JSON")
            throw LLMError.parseError
        }

        // Debug: Log what Claude returned
        print("📝 Claude dual response text:")
        print(text)

        // Extract dual suggestions from text
        let dualSuggestions = parseDualSuggestions(from: text)

        if dualSuggestions == nil {
            print("⚠️ Failed to parse dual suggestions format")
        }

        return dualSuggestions
    }

    // MARK: - Groq API (Cloud - Legacy)

    private func generateGroqSuggestions(
        arousalBand: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        childName: String?,
        sessionContext: SessionContext?,
        model: LLMModel
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

    private func callGroqAPI(prompt: String, apiKey: String, model: LLMModel) async throws -> [String] {
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // First, try to parse numbered list (for backward compatibility)
        let pattern = "(?:^|\\n)\\d+[.)\\s]+(.+?)(?=\\n\\d+[.)\\s]+|$)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))

            if !matches.isEmpty {
                let suggestions = matches.compactMap { match -> String? in
                    guard match.numberOfRanges > 1 else { return nil }
                    let range = match.range(at: 1)
                    let rawText = nsText.substring(with: range)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return cleanMarkdown(rawText)
                }

                if !suggestions.isEmpty {
                    return Array(suggestions.prefix(3))
                }
            }
        }

        // No numbered list found - treat entire response as single suggestion
        // This handles the new format where Claude returns one suggestion without numbering
        let cleaned = cleanMarkdown(trimmed)

        // Remove common prefixes
        var suggestion = cleaned
        let prefixesToRemove = [
            "Your single recommendation:",
            "Recommendation:",
            "Suggestion:",
            "Here's what you can do:",
            "Try this:",
        ]

        for prefix in prefixesToRemove {
            if suggestion.hasPrefix(prefix) {
                suggestion = String(suggestion.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Return as array with single element if not empty
        return suggestion.isEmpty ? [] : [suggestion]
    }

    /// Parse dual suggestions (child + parent) from LLM response
    private func parseDualSuggestions(from text: String) -> DualCoachingSuggestions? {
        // Extract child suggestion
        guard let childSuggestionRange = text.range(of: "CHILD SUGGESTION:", options: .caseInsensitive),
              let childResourceRange = text.range(of: "CHILD RESOURCE:", options: .caseInsensitive) else {
            print("⚠️ Could not find CHILD SUGGESTION markers")
            return nil
        }

        let childSuggestionText = String(text[childSuggestionRange.upperBound..<childResourceRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract child resource
        guard let parentSuggestionRange = text.range(of: "PARENT SUGGESTION:", options: .caseInsensitive) else {
            print("⚠️ Could not find PARENT SUGGESTION marker")
            return nil
        }

        let childResourceText = String(text[childResourceRange.upperBound..<parentSuggestionRange.lowerBound])
        let (childResourceTitle, childResourceURL) = parseResource(from: childResourceText)

        // Extract parent suggestion
        guard let parentResourceRange = text.range(of: "PARENT RESOURCE:", options: .caseInsensitive) else {
            print("⚠️ Could not find PARENT RESOURCE marker")
            return nil
        }

        let parentSuggestionText = String(text[parentSuggestionRange.upperBound..<parentResourceRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract parent resource
        let parentResourceText = String(text[parentResourceRange.upperBound...])
        let (parentResourceTitle, parentResourceURL) = parseResource(from: parentResourceText)

        // Create suggestions
        let childSuggestion = CoachingSuggestionWithResource(
            text: cleanMarkdown(childSuggestionText),
            category: categorizeSuggestion(childSuggestionText),
            resourceTitle: childResourceTitle,
            resourceURL: childResourceURL
        )

        let parentSuggestion = CoachingSuggestionWithResource(
            text: cleanMarkdown(parentSuggestionText),
            category: .parentSupport,  // Always parent support
            resourceTitle: parentResourceTitle,
            resourceURL: parentResourceURL
        )

        print("✅ Parsed dual suggestions:")
        print("   Child: \(childSuggestion.text.prefix(50))...")
        print("   Parent: \(parentSuggestion.text.prefix(50))...")

        return DualCoachingSuggestions(
            childSuggestion: childSuggestion,
            parentSuggestion: parentSuggestion
        )
    }

    /// Parse resource title and URL from text
    private func parseResource(from text: String) -> (title: String?, url: String?) {
        var title: String? = nil
        var url: String? = nil

        // Extract title
        if let titleRange = text.range(of: "Title:", options: .caseInsensitive) {
            let afterTitle = text[titleRange.upperBound...]
            if let urlRange = afterTitle.range(of: "URL:", options: .caseInsensitive) {
                title = String(afterTitle[..<urlRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                title = String(afterTitle)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Extract URL
        if let urlRange = text.range(of: "URL:", options: .caseInsensitive) {
            let afterURL = text[urlRange.upperBound...]
            url = String(afterURL)
                .components(separatedBy: .newlines).first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return (title, url)
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

        IMPORTANT: Provide ONLY ONE clear, actionable suggestion. Do not provide multiple suggestions or numbered lists.

        """

        // Add child profile if available
        if let context = sessionContext, let profile = context.childProfile {
            prompt += """
            CHILD PROFILE:
            - Name: \(profile.name), Age: \(profile.age)
            - Communication: \(profile.communicationMode.description)
            """

            // Add diagnosis information and notes for LLM context
            if let diagnosisInfo = profile.diagnosisInfo {
                prompt += "\n"
                prompt += diagnosisInfo.llmContext
            }

            if !profile.triggers.isEmpty {
                prompt += "\n- Known triggers: \(profile.triggers.prefix(3).map { $0.description }.joined(separator: ", "))"
            }

            if !profile.soothingStrategies.isEmpty {
                prompt += "\n- Effective strategies: \(profile.soothingStrategies.prefix(3).map { $0.description }.joined(separator: ", "))"
            }

            // Add co-regulation assessment insights
            let assessment = profile.coRegulationAssessment
            if !assessment.currentPractices.isEmpty {
                prompt += "\n\nCO-REGULATION PRACTICES (What Works for This Family):"

                // Current practices
                prompt += "\n- Parent uses: \(assessment.currentPractices.map { $0.rawValue }.prefix(3).joined(separator: ", "))"

                // Effective calming strategies (rated 4-5)
                var effectiveStrategies: [String] = []
                if let rating = assessment.deepPressureRating, rating >= 4 {
                    effectiveStrategies.append("deep pressure")
                }
                if let rating = assessment.rhythmicMovementRating, rating >= 4 {
                    effectiveStrategies.append("rhythmic movement")
                }
                if let rating = assessment.quietEnvironmentRating, rating >= 4 {
                    effectiveStrategies.append("quiet environment")
                }
                if let rating = assessment.sensoryItemsRating, rating >= 4 {
                    effectiveStrategies.append("sensory items")
                }
                if let rating = assessment.routinesRating, rating >= 4 {
                    effectiveStrategies.append("predictable routines")
                }
                if let rating = assessment.verbalReassuranceRating, rating >= 4 {
                    effectiveStrategies.append("verbal reassurance")
                }
                if let rating = assessment.silentPresenceRating, rating >= 4 {
                    effectiveStrategies.append("silent presence")
                }
                if !effectiveStrategies.isEmpty {
                    prompt += "\n- Highly effective calming: \(effectiveStrategies.joined(separator: ", "))"
                }

                // Communication preferences
                if let commApproach = assessment.communicationApproach {
                    prompt += "\n- Communication during distress: \(commApproach.rawValue)"
                }

                // Physical proximity
                if let proximity = assessment.physicalProximityPreference {
                    prompt += "\n- Physical proximity: \(proximity.rawValue)"
                }

                // Recovery time
                if let recovery = assessment.recoveryTime {
                    prompt += "\n- Typical recovery time: \(recovery.rawValue)"
                }

                // Parent confidence level
                if let confidence = assessment.parentConfidence {
                    prompt += "\n- Parent confidence level: \(confidence)/5"
                }
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

            // Add voice observations (parent context)
            if !context.voiceObservations.isEmpty {
                prompt += """
                PARENT VOICE OBSERVATIONS (Additional Context):
                \(context.voiceObservationsFormatted)

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
        2. The co-regulation practices and strategies this family finds effective
        3. The session trends and patterns observed so far
        4. What has already been suggested (avoid repetition unless reinforcing success)
        5. The trajectory (escalating, improving, or stable)
        6. Co-regulation quality between parent and child
        7. Parent's confidence level and self-regulation needs

        Provide ONE specific, actionable coaching suggestion (not a list, just a single recommendation):

        Format requirements:
        - Start with an action verb
        - Use warm, clear, professional language
        - 1-2 sentences maximum
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

        Focus on the most urgent need:
        - Safety and regulation first
        - Environmental or sensory modification if applicable
        - Parent self-regulation support if needed

        Provide TWO separate recommendations in this EXACT format:

        CHILD SUGGESTION:
        [Your actionable suggestion for supporting the child - 1-2 sentences]

        CHILD RESOURCE:
        Title: [Brief title of educational resource]
        URL: [Direct URL to an authentic, credible resource from autism.org.uk, autismspeaks.org, understood.org, or similar trusted organization]

        PARENT SUGGESTION:
        [Your actionable suggestion for parent self-care or co-regulation - 1-2 sentences]

        PARENT RESOURCE:
        Title: [Brief title of educational resource about caregiver support]
        URL: [Direct URL to an authentic resource for parent/caregiver wellbeing]

        IMPORTANT:
        - Provide working URLs to real pages (not broken links)
        - Child suggestion focuses on supporting the child's regulation
        - Parent suggestion focuses on parent self-care or staying regulated themselves
        - Both suggestions should complement each other for effective co-regulation
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
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured"
        case .invalidAPIKey:
            return "Invalid API key format. Groq API keys should start with 'gsk_' and be 56 characters long."
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

/// Dual coaching suggestions (child + parent)
struct DualCoachingSuggestions {
    let childSuggestion: CoachingSuggestionWithResource
    let parentSuggestion: CoachingSuggestionWithResource
}

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
