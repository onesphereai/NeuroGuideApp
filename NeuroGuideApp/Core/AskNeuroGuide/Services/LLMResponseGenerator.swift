//
//  LLMResponseGenerator.swift
//  NeuroGuide
//
//  Unit 7 - Ask NeuroGuide: LLM-Powered Responses
//

import Foundation

/// Generates AI-powered responses with citations for Ask NeuroGuide
class LLMResponseGenerator {

    // MARK: - Singleton

    static let shared = LLMResponseGenerator()

    // MARK: - Properties

    private var claudeAPIKey: String?
    private let claudeAPIURL = "https://api.anthropic.com/v1/messages"
    private let claudeModel = "claude-sonnet-4-20250514"  // Claude Sonnet 4.5
    private let anthropicVersion = "2023-06-01"

    // Caching for performance
    private var responseCache: [String: CachedResponse] = [:]
    private struct CachedResponse {
        let answer: ContentAnswer
        let timestamp: Date
    }

    // MARK: - Initialization

    private init() {
        loadAPIKey()

        print("✅ LLM Response Generator initialized with Claude Sonnet 4.5")
    }

    // MARK: - Configuration

    func configureClaudeAPI(apiKey: String) {
        self.claudeAPIKey = apiKey
        saveAPIKey(apiKey)
    }

    private func loadAPIKey() {
        // Try to load from SettingsManager first
        let settings = SettingsManager()
        if let key = settings.claudeAPIKey, !key.isEmpty {
            self.claudeAPIKey = key
            print("✅ Loaded Claude API key from SettingsManager")
            return
        }

        // Fallback to KeychainManager
        if let data = try? KeychainManager.shared.load(key: "claude_api_key"),
           let key = String(data: data, encoding: .utf8) {
            self.claudeAPIKey = key
            print("✅ Loaded Claude API key from Keychain")
        } else {
            print("⚠️ No Claude API key found")
        }
    }

    private func saveAPIKey(_ key: String) {
        if let data = key.data(using: .utf8) {
            try? KeychainManager.shared.save(data: data, forKey: "claude_api_key", accessible: .whenUnlocked)
        }
    }

    // MARK: - Response Generation

    /// Generate AI-powered answer with citations
    func generateAnswer(for question: String, context: ConversationContext?, profile: ChildProfile? = nil) async throws -> ContentAnswer {
        // Check cache (10 minute expiry)
        if let cached = responseCache[question],
           Date().timeIntervalSince(cached.timestamp) < 600 {
            print("♻️ Using cached response for: \(question)")
            return cached.answer
        }

        print("🤖 Generating LLM response for: \(question)")
        if let profile = profile {
            print("📋 Using child profile: \(profile.name), Age: \(profile.age)")
        } else {
            print("⚠️ No child profile provided")
        }

        // GUARDRAIL: Check if question is neurodivergence-related
        let isRelated = isNeurodivergenceRelated(question: question)
        print("🔍 Neurodivergence check: \(isRelated ? "PASS" : "FAIL") for question: \"\(question)\"")
        if !isRelated {
            print("🚫 Question rejected - not neurodivergence related")
            return createOutOfScopeResponse()
        }

        guard let apiKey = claudeAPIKey else {
            print("❌ No Claude API key configured!")
            throw LLMResponseError.noAPIKey
        }

        print("✅ Claude API key present: \(apiKey.prefix(10))...")

        // Build prompt with citation requirements and profile context
        let prompt = buildPrompt(question: question, context: context, profile: profile)
        print("📝 Built prompt with \(prompt.count) characters")

        // Call Claude API
        print("🚀 About to call Claude API...")
        let (responseText, resourceCitations) = try await callClaudeAPI(prompt: prompt, apiKey: apiKey)
        print("✅ Received response with \(responseText.count) characters and \(resourceCitations.count) citations")

        // Create ContentAnswer with citations
        let answer = ContentAnswer(
            content: responseText,
            source: ContentSource(
                title: "AI-Generated Response",
                section: determineTopic(for: question),
                author: "attune AI",
                credibilityLevel: .expertRecommended
            ),
            relevanceScore: 0.95,
            strategies: nil,
            resourceCitations: resourceCitations
        )

        // Cache the response
        responseCache[question] = CachedResponse(answer: answer, timestamp: Date())

        return answer
    }

    // MARK: - Prompt Building

    private func buildPrompt(question: String, context: ConversationContext?, profile: ChildProfile?) -> String {
        var prompt = """
        You are attune, an evidence-based autism and neurodiversity expert assistant helping parents of autistic children.

        User Question: \(question)
        """

        // Add child profile context
        if let profile = profile {
            prompt += "\n\nCHILD PROFILE:"
            prompt += "\n- Name: \(profile.name)"
            prompt += "\n- Age: \(profile.age) years old"

            if let pronouns = profile.pronouns {
                prompt += "\n- Pronouns: \(pronouns)"
            }

            // Add diagnosis information
            if let diagnosisInfo = profile.diagnosisInfo {
                prompt += "\n\n"
                prompt += diagnosisInfo.llmContext
            }

            // Add communication mode
            prompt += "\n- Communication mode: \(profile.communicationMode.description)"

            // Add known triggers
            if !profile.triggers.isEmpty {
                let triggerDescriptions = profile.triggers.prefix(5).map { $0.description }
                prompt += "\n- Known triggers: \(triggerDescriptions.joined(separator: ", "))"
            }

            // Add effective strategies
            if !profile.soothingStrategies.isEmpty {
                let strategyDescriptions = profile.soothingStrategies.prefix(5).map { $0.description }
                prompt += "\n- Effective strategies: \(strategyDescriptions.joined(separator: ", "))"
            }

            prompt += "\n\nPlease tailor your response specifically to this child's profile, age, and needs."
        }

        if let context = context {
            prompt += "\n\nConversation Context:"
            if !context.turns.isEmpty {
                let previousQuestions = context.turns.prefix(3).map { $0.question.text }
                prompt += "\nPrevious questions: \(previousQuestions.joined(separator: ", "))"
            }
        }

        prompt += """


        Provide a comprehensive, evidence-based answer that:

        1. Uses neurodiversity-affirming language (NEVER use person-first language, ALWAYS use identity-first "autistic child")
        2. Draws from current best practices in autism support
        3. Includes practical, actionable strategies
        4. Is compassionate toward both child and parent
        5. Emphasizes autonomy, sensory needs, and emotional regulation
        6. Avoids ABA, compliance-based approaches, or deficit-focused language

        Structure your response:
        - Start with a direct answer to the question
        - Provide 2-4 key evidence-based strategies or insights
        - End with a supportive, empowering statement for the parent

        Keep the response:
        - Professional yet warm and supportive
        - 150-250 words
        - Scannable with natural paragraph breaks
        - Focused on the specific question asked

        IMPORTANT: At the end of your response, add a "Learn More" section with 2-3 specific resources in this format:

        ---
        Learn More:
        • [Resource Title] - [Brief description]
          URL: [complete valid URL starting with https://]

        Use ONLY these verified resource domains with COMPLETE, VALID URLs:
        - https://www.autism.org.uk/ (UK autism charity - use specific page URLs like https://www.autism.org.uk/advice-and-guidance)
        - https://www.autismspeaks.org/ (major autism advocacy - use specific section URLs)
        - https://autisticadvocacy.org/ (Autistic Self Advocacy Network)
        - https://www.reframingautism.org.au/ (neurodiversity-focused Australian org)

        CRITICAL:
        - ALL URLs MUST start with https://
        - ALL URLs MUST be complete and valid (not placeholders)
        - ONLY include URLs from the domains listed above
        - Use specific page URLs that relate to the question topic

        Response:
        """

        return prompt
    }

    // MARK: - API Call

    private func callClaudeAPI(prompt: String, apiKey: String) async throws -> (response: String, citations: [ResourceCitation]) {
        guard let url = URL(string: claudeAPIURL) else {
            throw LLMResponseError.invalidURL
        }

        print("📤 Calling Claude API...")

        // Build system prompt
        let systemPrompt = """
        You are attune, an expert in autism support and neurodiversity-affirming practices. You provide evidence-based, compassionate guidance to parents of autistic children.

        IMPORTANT GUARDRAILS:
        - ONLY respond to questions about autism, neurodivergence, ADHD, sensory processing, developmental differences, and related parenting support
        - If a question is about unrelated topics (sports, politics, general trivia, etc.), politely decline by saying: "I'm specifically designed to support parents of neurodivergent children. I can help with questions about autism, ADHD, sensory processing, and neurodiversity-affirming parenting. Could you rephrase your question to relate to these topics?"
        - Do NOT answer questions that are clearly off-topic, even if they mention children or parenting in general
        """

        // Build Claude request body
        let requestBody: [String: Any] = [
            "model": claudeModel,
            "max_tokens": 1024,
            "temperature": 0.7,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request
        print("⏳ Waiting for Claude response...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📥 Received response from Claude")

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMResponseError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Claude API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw LLMResponseError.apiError(httpResponse.statusCode, errorMessage)
        }

        // Parse Claude response
        struct ClaudeResponse: Codable {
            let content: [ContentBlock]

            struct ContentBlock: Codable {
                let text: String
            }
        }

        let decoder = JSONDecoder()
        let claudeResponse = try decoder.decode(ClaudeResponse.self, from: data)

        guard let text = claudeResponse.content.first?.text else {
            throw LLMResponseError.parseError
        }

        // Extract citations
        let citations = extractCitations(from: text)

        return (text, citations)
    }

    // MARK: - Helper Methods

    private func extractCitations(from text: String) -> [ResourceCitation] {
        // Extract citations from the "Learn More" section
        // Expected format:
        // • [Resource Title] - [Brief description]
        //   URL: [actual working URL]

        var citations: [ResourceCitation] = []

        // Find the "Learn More" section
        guard let learnMoreRange = text.range(of: "Learn More:", options: .caseInsensitive) else {
            return []
        }

        let learnMoreSection = String(text[learnMoreRange.upperBound...])
        let lines = learnMoreSection.components(separatedBy: .newlines)

        var currentTitle: String?
        var currentDescription: String?

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Check for resource title line (starts with •)
            if trimmedLine.hasPrefix("•") {
                // Extract title and description from "• [Title] - [Description]"
                let content = trimmedLine.dropFirst(1).trimmingCharacters(in: .whitespaces)

                // Split by " - " to separate title and description
                let parts = content.components(separatedBy: " - ")
                if parts.count >= 2 {
                    currentTitle = parts[0].trimmingCharacters(in: .whitespaces)
                    currentDescription = parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces)
                } else {
                    currentTitle = content
                    currentDescription = nil
                }
            }
            // Check for URL line
            else if trimmedLine.hasPrefix("URL:") {
                let urlString = trimmedLine.replacingOccurrences(of: "URL:", with: "")
                    .trimmingCharacters(in: .whitespaces)

                if let title = currentTitle, !urlString.isEmpty {
                    let citation = ResourceCitation(
                        title: title,
                        url: urlString,
                        description: currentDescription
                    )
                    citations.append(citation)

                    // Reset for next citation
                    currentTitle = nil
                    currentDescription = nil
                }
            }
        }

        print("📚 Extracted \(citations.count) resource citations")
        return citations
    }

    private func determineTopic(for question: String) -> String {
        let lowercased = question.lowercased()

        if lowercased.contains("meltdown") || lowercased.contains("tantrum") || lowercased.contains("crisis") {
            return "Crisis Support"
        } else if lowercased.contains("sensory") || lowercased.contains("noise") || lowercased.contains("light") {
            return "Sensory Processing"
        } else if lowercased.contains("stim") || lowercased.contains("flapping") || lowercased.contains("rocking") {
            return "Stimming & Self-Regulation"
        } else if lowercased.contains("communication") || lowercased.contains("speak") || lowercased.contains("talk") {
            return "Communication Support"
        } else if lowercased.contains("transition") || lowercased.contains("change") || lowercased.contains("routine") {
            return "Transitions & Routines"
        } else if lowercased.contains("school") || lowercased.contains("teacher") || lowercased.contains("IEP") {
            return "School & Education"
        } else if lowercased.contains("parent") || lowercased.contains("burnout") || lowercased.contains("stress") {
            return "Parent Support"
        } else {
            return "General Support"
        }
    }

    // MARK: - Guardrails

    /// Check if question is related to neurodivergence topics
    private func isNeurodivergenceRelated(question: String) -> Bool {
        let lowercased = question.lowercased()

        // Neurodivergence-related keywords
        let neurodivergenceKeywords = [
            // Core conditions
            "autism", "autistic", "adhd", "add", "dyslexia", "dyspraxia", "tourette",
            "neurodivergent", "neurodiversity", "neurodiverse",

            // Autism-specific
            "asperger", "asd", "spectrum", "stimming", "stim", "echolalia", "scripting",
            "meltdown", "shutdown", "masking", "sensory overload",

            // Sensory processing
            "sensory", "proprioception", "vestibular", "interoception",
            "hypersensitive", "hyposensitive", "sensory seeking", "sensory avoiding",

            // Development & behavior
            "developmental delay", "developmental difference", "executive function",
            "motor skills", "fine motor", "gross motor",

            // Communication
            "nonverbal", "non-verbal", "nonspeaking", "aac", "augmentative communication",
            "speech delay", "language delay",

            // Emotional regulation
            "regulation", "dysregulation", "co-regulation", "self-regulation",
            "emotional regulation", "arousal",

            // Common challenges
            "routine", "transition", "change", "rigidity", "flexibility",
            "social skills", "social interaction", "eye contact",

            // Support & strategies
            "iep", "504", "special education", "accommodations", "modifications",
            "visual schedule", "social story", "fidget", "weighted blanket",

            // Parent support
            "parenting autistic", "neurodivergent child", "special needs",
            "parent burnout", "caregiver stress"
        ]

        // Check if question contains any neurodivergence keywords
        for keyword in neurodivergenceKeywords {
            if lowercased.contains(keyword) {
                return true
            }
        }

        // If no keywords found, it's likely off-topic
        return false
    }

    /// Create a polite out-of-scope response
    private func createOutOfScopeResponse() -> ContentAnswer {
        let content = """
        I'm specifically designed to support parents of neurodivergent children with questions about autism, ADHD, sensory processing, and neurodiversity-affirming parenting.

        I can help with topics like:
        • Understanding autism and neurodivergence
        • Sensory processing and regulation strategies
        • Communication support and AAC
        • Managing meltdowns and emotional regulation
        • School accommodations (IEPs, 504 plans)
        • Parent self-care and burnout prevention

        Could you rephrase your question to relate to neurodivergence or parenting a neurodivergent child?
        """

        return ContentAnswer(
            content: content,
            source: ContentSource(
                title: "Out of Scope",
                section: "System Message",
                author: "attune",
                credibilityLevel: .expertRecommended
            ),
            relevanceScore: 0.0,
            strategies: nil,
            resourceCitations: []
        )
    }
}

// MARK: - Errors

enum LLMResponseError: LocalizedError {
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
