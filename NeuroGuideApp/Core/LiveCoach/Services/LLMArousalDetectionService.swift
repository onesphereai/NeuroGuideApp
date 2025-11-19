//
//  LLMArousalDetectionService.swift
//  NeuroGuide
//
//  Enhanced arousal band detection using LLM with comprehensive context
//  Sends all captured features, child profile, and historical data to LLM
//

import Foundation

/// LLM provider options
enum LLMProvider {
    case groq
    case claude
    case appleIntelligence
}

/// Service that uses LLM to determine arousal band from comprehensive multimodal data
class LLMArousalDetectionService {

    // MARK: - Dependencies

    private let apiKey: String?
    private let provider: LLMProvider

    // MARK: - Configuration

    private let temperature: Double = 0.3  // Low temperature for consistent classification

    // Model configurations
    private var modelName: String {
        switch provider {
        case .groq:
            return "llama-3.1-70b-versatile"
        case .claude:
            return "claude-sonnet-4-20250514"  // Claude Sonnet 4.5
        case .appleIntelligence:
            return "apple-intelligence"
        }
    }

    private var apiURL: String {
        switch provider {
        case .groq:
            return "https://api.groq.com/openai/v1/chat/completions"
        case .claude:
            return "https://api.anthropic.com/v1/messages"
        case .appleIntelligence:
            return "" // Not used for Apple Intelligence
        }
    }

    // MARK: - Caching

    /// Cache detection for 2 seconds to avoid repeated calls on similar frames
    private var lastDetection: (timestamp: Date, band: ArousalBand, confidence: Double)?
    private let cacheDuration: TimeInterval = 2.0

    /// Clear the detection cache (call when session ends)
    func clearCache() {
        lastDetection = nil
        print("🗑️ LLM arousal detection cache cleared")
    }

    // MARK: - Initialization

    init(apiKey: String? = nil, provider: LLMProvider = .claude) {
        self.apiKey = apiKey
        self.provider = provider
    }

    // Legacy initializer for backward compatibility
    convenience init(groqAPIKey: String? = nil, useAppleIntelligence: Bool = false) {
        if useAppleIntelligence {
            self.init(apiKey: nil, provider: .appleIntelligence)
        } else {
            self.init(apiKey: groqAPIKey, provider: .groq)
        }
    }

    // MARK: - Main Detection Method

    /// Detect arousal band using LLM with comprehensive context
    /// - Parameters:
    ///   - request: Complete detection request with all features and profile data
    /// - Returns: Arousal band and confidence score
    func detectArousalBand(request: LLMArousalDetectionRequest) async throws -> (band: ArousalBand, confidence: Double) {
        // Check cache
        if let cached = lastDetection,
           Date().timeIntervalSince(cached.timestamp) < cacheDuration {
            return (cached.band, cached.confidence)
        }

        // Route to appropriate provider
        let result: (band: ArousalBand, confidence: Double)

        switch provider {
        case .appleIntelligence:
            // TODO: Implement Apple Intelligence when API is available
            throw LLMArousalDetectionError.providerNotAvailable

        case .groq:
            guard let key = apiKey, !key.isEmpty else {
                throw LLMArousalDetectionError.noAPIKeyConfigured
            }
            result = try await detectWithGroq(request: request, apiKey: key)

        case .claude:
            guard let key = apiKey, !key.isEmpty else {
                throw LLMArousalDetectionError.noAPIKeyConfigured
            }
            result = try await detectWithClaude(request: request, apiKey: key)
        }

        // Cache result
        lastDetection = (Date(), result.band, result.confidence)

        return result
    }

    // MARK: - Groq API Implementation

    private func detectWithGroq(request: LLMArousalDetectionRequest, apiKey: String) async throws -> (band: ArousalBand, confidence: Double) {

        // Build comprehensive prompt
        let systemPrompt = buildSystemPrompt()
        let userPrompt = buildUserPrompt(from: request)

        // Prepare API request
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": temperature,
            "max_tokens": 200,
            "response_format": ["type": "json_object"]
        ]

        // Make API call
        guard let url = URL(string: apiURL) else {
            throw LLMArousalDetectionError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMArousalDetectionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMArousalDetectionError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let result = try parseGroqResponse(data: data)
        return result
    }

    // MARK: - Prompt Building

    private func buildSystemPrompt() -> String {
        return """
        You are an expert arousal state classifier for neurodivergent children (ages 2-8) specializing in autism, ADHD, and sensory processing differences.

        Your task is to analyze multimodal data (movement, vocal, visual, environmental) along with the child's comprehensive profile to determine their current arousal band.

        AROUSAL BANDS (Polyvagal Theory-Based):
        1. SHUTDOWN - Under-aroused, withdrawn, freeze response (dorsal vagal)
           Signs: Very low movement, flat/quiet vocal affect, minimal response to environment

        2. GREEN - Regulated, optimal arousal, social engagement (ventral vagal)
           Signs: Moderate movement, calm/conversational vocal patterns, engaged with environment

        3. YELLOW - Elevated arousal, early warning signs (sympathetic activation beginning)
           Signs: Increased movement/stimming, elevated vocal pitch/volume, sensory sensitivity emerging

        4. ORANGE - High arousal, dysregulation building (sympathetic dominance)
           Signs: High-energy movement, strained/fast vocal patterns, sensory overwhelm visible

        5. RED - Crisis arousal, meltdown/shutdown imminent or occurring (sympathetic peak or dorsal shutdown)
           Signs: Extreme movement or complete stillness, vocal distress or silence, safety concern

        IMPORTANT CONSIDERATIONS:
        - Stimming (hand-flapping, rocking, spinning) can occur in BOTH regulated (green) and dysregulated states
        - Flat affect and minimal facial expressions are NORMAL for many autistic children - do not assume distress
        - Movement differences are neurotype features, not always arousal indicators
        - Context matters: Same behavior can mean different things in different arousal states
        - Respect the child's baseline calibration data - compare to THEIR normal, not neurotypical norms

        You must respond with valid JSON in this exact format:
        {
          "arousalBand": "green|yellow|orange|red|shutdown",
          "confidence": 0.0-1.0,
          "reasoning": "Brief explanation of key factors that led to this classification",
          "keyIndicators": ["indicator1", "indicator2", "indicator3"]
        }
        """
    }

    private func buildUserPrompt(from request: LLMArousalDetectionRequest) -> String {
        var prompt = "# CHILD PROFILE\n\n"

        // Basic info
        prompt += "Name: \(request.childProfile.name)\n"
        prompt += "Age: \(request.childProfile.age) years old\n"
        if let pronouns = request.childProfile.pronouns {
            prompt += "Pronouns: \(pronouns)\n"
        }

        // Diagnosis
        if let diagnosis = request.childProfile.diagnosisInfo {
            prompt += diagnosis.llmContext
        }

        // Communication mode
        prompt += "Communication: \(request.childProfile.communicationMode.rawValue)\n"
        if let notes = request.childProfile.communicationNotes, !notes.isEmpty {
            prompt += "Communication notes: \(notes)\n"
        }

        // Emotion expression profile
        if let emotionProfile = request.childProfile.emotionExpressionProfile {
            prompt += "\n## Emotion Expression Patterns\n"
            prompt += "- Flat affect: \(emotionProfile.hasFlatAffect ? "Yes" : "No")\n"
            prompt += "- Uses echolalia: \(emotionProfile.usesEcholalia ? "Yes" : "No")\n"
            prompt += "- Stims when happy: \(emotionProfile.stimsWhenHappy ? "Yes" : "No")\n"
            prompt += "- Stims when distressed: \(emotionProfile.stimsWhenDistressed ? "Yes" : "No")\n"
            prompt += "- Has alexithymia: \(emotionProfile.hasAlexithymia ? "Yes" : "No")\n"
            prompt += "- Non-speaking: \(emotionProfile.isNonSpeaking ? "Yes" : "No")\n"

            if !emotionProfile.joyExpressions.isEmpty {
                prompt += "- Joy expressions: \(emotionProfile.joyExpressions.joined(separator: ", "))\n"
            }
            if !emotionProfile.frustrationExpressions.isEmpty {
                prompt += "- Frustration expressions: \(emotionProfile.frustrationExpressions.joined(separator: ", "))\n"
            }
            if !emotionProfile.overwhelmExpressions.isEmpty {
                prompt += "- Overwhelm expressions: \(emotionProfile.overwhelmExpressions.joined(separator: ", "))\n"
            }
        }

        // Sensory preferences
        prompt += "\n## Sensory Profile\n"
        prompt += request.childProfile.sensoryProfileSummary + "\n"
        if !request.childProfile.sensoryPreferences.specificTriggers.isEmpty {
            prompt += "Specific triggers: \(request.childProfile.sensoryPreferences.specificTriggers.joined(separator: ", "))\n"
        }

        // Known triggers
        if !request.childProfile.triggers.isEmpty {
            prompt += "\n## Known Dysregulation Triggers\n"
            for trigger in request.childProfile.triggers {
                prompt += "- [\(trigger.category.rawValue)] \(trigger.description)\n"
            }
        }

        // Effective strategies
        if !request.childProfile.soothingStrategies.isEmpty {
            prompt += "\n## Effective Co-Regulation Strategies\n"
            let topStrategies = request.childProfile.getTopStrategies(limit: 5)
            for strategy in topStrategies {
                prompt += "- [\(strategy.category.rawValue)] \(strategy.description)"
                if strategy.effectivenessRating > 0 {
                    prompt += " (effectiveness: \(String(format: "%.1f", strategy.effectivenessRating))/5.0)"
                }
                prompt += "\n"
            }
        }

        // Baseline calibration
        if let baseline = request.childProfile.baselineCalibration {
            prompt += "\n## Baseline Calibration (Calm State)\n"
            prompt += "Captured: \(formatDate(baseline.calibratedAt))\n"
            prompt += "Typical movement energy: \(String(format: "%.2f", baseline.movementBaseline.averageMovementEnergy))\n"
            if !baseline.movementBaseline.commonStimBehaviors.isEmpty {
                prompt += "Common stims: \(baseline.movementBaseline.commonStimBehaviors.joined(separator: ", "))\n"
                prompt += "Stims are regulatory: \(baseline.movementBaseline.stimIsRegulatory ? "Yes" : "No")\n"
            }
            prompt += "Typical pitch: \(String(format: "%.0f", baseline.vocalBaseline.averagePitch)) Hz\n"
            prompt += "Typical volume: \(String(format: "%.0f", baseline.vocalBaseline.averageVolume)) dB\n"
        }

        // Co-regulation history
        if request.childProfile.coRegulationHistory.totalSessions > 0 {
            prompt += "\n## Co-Regulation History\n"
            prompt += "Total sessions: \(request.childProfile.coRegulationHistory.totalSessions)\n"
            prompt += "Average helpfulness: \(String(format: "%.1f", request.childProfile.coRegulationHistory.averageHelpfulness))/5.0\n"
        }

        // CURRENT OBSERVATIONS
        prompt += "\n\n# CURRENT OBSERVATIONS\n\n"

        // Pose/Movement features
        if let pose = request.poseFeatures {
            prompt += "## Movement & Pose\n"
            prompt += "Movement intensity: \(String(format: "%.2f", pose.movementIntensity)) (0=still, 1=high energy)\n"
            prompt += "Body tension: \(String(format: "%.2f", pose.bodyTension)) (0=relaxed, 1=tense)\n"
            prompt += "Posture openness: \(String(format: "%.2f", pose.postureOpenness)) (0=closed, 1=open)\n"
            prompt += "Arousal contribution: \(String(format: "%.2f", pose.arousalContribution))\n"
            prompt += "Detection confidence: \(String(format: "%.2f", pose.keypointConfidence))\n"
        }

        // Detected behaviors
        if !request.detectedBehaviors.isEmpty {
            prompt += "\n## Observed Behaviors\n"
            for behavior in request.detectedBehaviors {
                prompt += "- \(behavior.displayName)\n"
            }
        }

        // Vocal features
        if let vocal = request.vocalFeatures {
            prompt += "\n## Vocal Characteristics\n"
            prompt += "Vocal volume: \(String(format: "%.2f", vocal.volume)) (0-1 scale)\n"
            prompt += "Pitch: \(String(format: "%.1f", vocal.pitch)) Hz\n"
            prompt += "Energy: \(String(format: "%.2f", vocal.energy)) (0-1 scale)\n"
            prompt += "Speech rate: \(String(format: "%.2f", vocal.speechRate)) (0-1 scale)\n"
            prompt += "Voice quality: \(String(format: "%.2f", vocal.voiceQuality)) (0=harsh, 1=smooth)\n"
            prompt += "Arousal contribution: \(String(format: "%.2f", vocal.arousalContribution))\n"
        }

        // Environmental context
        prompt += "\n## Environment\n"
        prompt += "Lighting: \(request.environment.lightingLevel.displayName)\n"
        prompt += "Visual complexity: \(request.environment.visualComplexity.displayName)\n"
        prompt += "Noise level: \(request.environment.noiseLevel.displayName)\n"
        if let noiseType = request.environment.noiseType {
            prompt += "Noise type: \(noiseType.displayName)\n"
        }
        if let crowdDensity = request.environment.crowdDensity {
            prompt += "Crowd density: \(crowdDensity.displayName)\n"
        }

        // Parent stress (context for co-regulation)
        if let parentStress = request.parentStress {
            prompt += "\n## Parent State\n"
            prompt += "Parent stress level: \(parentStress.overallStressLevel.displayName)\n"
            prompt += "Facial tension: \(parentStress.facialTension.displayName)\n"
            prompt += "Vocal stress: \(parentStress.vocalStress.displayName)\n"
        }

        // Session context
        if let sessionContext = request.sessionContext {
            prompt += "\n## Session Context\n"
            prompt += "Session duration: \(sessionContext.durationMinutes) minutes\n"
            prompt += "Behavior summary: \(sessionContext.behaviorSummary)\n"
            if !sessionContext.arousalTimeline.isEmpty {
                prompt += "Recent arousal timeline:\n\(sessionContext.arousalTimelineFormatted)\n"
            }
            if !sessionContext.patterns.isEmpty {
                prompt += "Observed patterns:\n\(sessionContext.patternsFormatted)\n"
            }
            if !sessionContext.coRegulationEvents.isEmpty {
                prompt += "Co-regulation events:\n\(sessionContext.coRegulationEventsFormatted)\n"
            }
        }

        // Timestamp
        prompt += "\nTimestamp: \(formatDate(request.timestamp))\n"

        prompt += "\n\n# TASK\n\n"
        prompt += "Based on ALL the information above, determine the child's current arousal band. "
        prompt += "Remember to compare current observations to THEIR baseline (not neurotypical norms). "
        prompt += "Consider the whole context - diagnosis, sensory profile, emotion expression patterns, environment, and historical data. "
        prompt += "Respond with valid JSON only."

        return prompt
    }

    // MARK: - Claude API Implementation

    private func detectWithClaude(request: LLMArousalDetectionRequest, apiKey: String) async throws -> (band: ArousalBand, confidence: Double) {

        // Build comprehensive prompt
        let systemPrompt = buildSystemPrompt()
        let userPrompt = buildUserPrompt(from: request)

        // Prepare API request (Claude format)
        let requestBody: [String: Any] = [
            "model": modelName,
            "max_tokens": 1024,
            "temperature": temperature,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ]
        ]

        // Make API call
        guard let url = URL(string: apiURL) else {
            throw LLMArousalDetectionError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMArousalDetectionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Log error details for debugging
            if let errorText = String(data: data, encoding: .utf8) {
                print("❌ Claude API Error (\(httpResponse.statusCode)): \(errorText)")
            }
            throw LLMArousalDetectionError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let result = try parseClaudeResponse(data: data)
        return result
    }

    // MARK: - Response Parsing

    private func parseGroqResponse(data: Data) throws -> (band: ArousalBand, confidence: Double) {
        let response = try JSONDecoder().decode(GroqResponse.self, from: data)

        guard let firstChoice = response.choices.first else {
            throw LLMArousalDetectionError.noChoicesInResponse
        }

        let content = firstChoice.message.content

        // Parse JSON content
        guard let contentData = content.data(using: .utf8),
              let jsonResponse = try? JSONDecoder().decode(LLMDetectionResponse.self, from: contentData) else {
            throw LLMArousalDetectionError.invalidJSONResponse
        }

        // Map string to ArousalBand
        let band: ArousalBand
        switch jsonResponse.arousalBand.lowercased() {
        case "green":
            band = .green
        case "yellow":
            band = .yellow
        case "orange":
            band = .orange
        case "red":
            band = .red
        case "shutdown":
            band = .shutdown
        default:
            throw LLMArousalDetectionError.invalidArousalBand(jsonResponse.arousalBand)
        }

        // Validate confidence
        let confidence = max(0.0, min(1.0, jsonResponse.confidence))

        print("🤖 LLM Arousal Detection: \(band.displayName) (confidence: \(String(format: "%.2f", confidence)))")
        print("   Reasoning: \(jsonResponse.reasoning)")
        print("   Key indicators: \(jsonResponse.keyIndicators.joined(separator: ", "))")

        return (band, confidence)
    }

    private func parseClaudeResponse(data: Data) throws -> (band: ArousalBand, confidence: Double) {
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let firstContent = response.content.first else {
            throw LLMArousalDetectionError.noChoicesInResponse
        }

        let content = firstContent.text

        // Claude should return JSON, extract it
        // Look for JSON object in the response
        guard let jsonStart = content.range(of: "{"),
              let jsonEnd = content.range(of: "}", options: .backwards) else {
            throw LLMArousalDetectionError.invalidJSONResponse
        }

        let jsonString = String(content[jsonStart.lowerBound...jsonEnd.upperBound])

        // Parse JSON content
        guard let contentData = jsonString.data(using: .utf8),
              let jsonResponse = try? JSONDecoder().decode(LLMDetectionResponse.self, from: contentData) else {
            throw LLMArousalDetectionError.invalidJSONResponse
        }

        // Map string to ArousalBand
        let band: ArousalBand
        switch jsonResponse.arousalBand.lowercased() {
        case "green":
            band = .green
        case "yellow":
            band = .yellow
        case "orange":
            band = .orange
        case "red":
            band = .red
        case "shutdown":
            band = .shutdown
        default:
            throw LLMArousalDetectionError.invalidArousalBand(jsonResponse.arousalBand)
        }

        // Validate confidence
        let confidence = max(0.0, min(1.0, jsonResponse.confidence))

        print("🤖 Claude Arousal Detection: \(band.displayName) (confidence: \(String(format: "%.2f", confidence)))")
        print("   Reasoning: \(jsonResponse.reasoning)")
        print("   Key indicators: \(jsonResponse.keyIndicators.joined(separator: ", "))")

        return (band, confidence)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - API Response Models

    private struct GroqResponse: Codable {
        let choices: [Choice]

        struct Choice: Codable {
            let message: Message

            struct Message: Codable {
                let content: String
            }
        }
    }

    private struct ClaudeResponse: Codable {
        let content: [ContentBlock]

        struct ContentBlock: Codable {
            let text: String
        }
    }

    private struct LLMDetectionResponse: Codable {
        let arousalBand: String
        let confidence: Double
        let reasoning: String
        let keyIndicators: [String]
    }
}

// MARK: - Request Model

/// Comprehensive arousal detection request with all available data
struct LLMArousalDetectionRequest {
    // Child profile (complete personalization data)
    let childProfile: ChildProfile

    // Current multimodal features
    let poseFeatures: PoseFeatures?
    let vocalFeatures: VocalFeatures?
    let facialFeatures: FacialFeatures?  // Note: Only for parent stress, NOT used for child

    // Detected behaviors
    let detectedBehaviors: [ChildBehavior]

    // Environmental context
    let environment: EnvironmentContext

    // Parent state (for co-regulation context)
    let parentStress: ParentStressAnalysis?

    // Session context (temporal patterns)
    let sessionContext: SessionContext?

    // Timestamp
    let timestamp: Date
}

// Note: SessionContext, PoseFeatures, VocalFeatures, and FacialFeatures
// are already defined elsewhere in the codebase, so we don't redeclare them here

// MARK: - Errors

enum LLMArousalDetectionError: Error, LocalizedError {
    case noAPIKeyConfigured
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case noChoicesInResponse
    case invalidJSONResponse
    case invalidArousalBand(String)
    case providerNotAvailable

    var errorDescription: String? {
        switch self {
        case .noAPIKeyConfigured:
            return "No API key configured. Please add your API key in settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode):
            return "API error with status code: \(statusCode)"
        case .noChoicesInResponse:
            return "No content in API response"
        case .invalidJSONResponse:
            return "Could not parse JSON response from LLM"
        case .invalidArousalBand(let band):
            return "Invalid arousal band returned: \(band)"
        case .providerNotAvailable:
            return "Selected LLM provider is not yet available"
        }
    }
}
