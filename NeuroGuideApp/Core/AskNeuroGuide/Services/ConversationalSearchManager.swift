//
//  ConversationalSearchManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation
import Combine

/// Manager for conversational search with context awareness
@MainActor
class ConversationalSearchManager: ConversationalSearchService, ObservableObject {
    // MARK: - Singleton

    static let shared = ConversationalSearchManager()

    // MARK: - Published Properties

    @Published private(set) var conversationHistory: [ConversationTurn] = []

    // MARK: - Private Properties

    private let searchEngine: SemanticSearchEngine
    private let contentLibrary: SearchableContentLibrary
    private let profileManager: ChildProfileManager
    private let llmGenerator: LLMResponseGenerator

    // MARK: - Initialization

    init(
        searchEngine: SemanticSearchEngine = SemanticSearchEngine(),
        contentLibrary: SearchableContentLibrary? = nil,
        profileManager: ChildProfileManager = .shared,
        llmGenerator: LLMResponseGenerator = .shared
    ) {
        self.searchEngine = searchEngine
        self.contentLibrary = contentLibrary ?? Self.loadContentLibrary()
        self.profileManager = profileManager
        self.llmGenerator = llmGenerator
    }

    // MARK: - ConversationalSearchService

    /// Search for content based on question
    func search(query: Question, context: ConversationContext?) async throws -> SearchResult {
        var allAnswers: [ContentAnswer] = []

        // 1. Generate LLM-powered answer (primary answer)
        print("🤖 Generating LLM response for: \(query.text)")
        do {
            let llmAnswer = try await llmGenerator.generateAnswer(
                for: query.text,
                context: context
            )
            allAnswers.append(llmAnswer)
            print("✅ LLM answer generated successfully")
        } catch {
            print("⚠️ LLM generation failed: \(error.localizedDescription)")
            print("📚 Falling back to static content only")
        }

        // 2. Search static articles for additional context
        let scoredArticles = searchEngine.search(
            query: query.text,
            in: contentLibrary,
            context: context,
            limit: 3  // Reduced from 5 since LLM is primary
        )

        // Convert to ContentAnswers and append
        let staticAnswers = scoredArticles.map { scoredArticle in
            convertToAnswer(scoredArticle: scoredArticle)
        }
        allAnswers.append(contentsOf: staticAnswers)

        let result = SearchResult(
            query: query,
            answers: allAnswers,
            conversationContext: context
        )

        return result
    }

    /// Add follow-up question to conversation
    func addFollowUp(query: Question, context: ConversationContext) async throws -> SearchResult {
        // Search with context for better relevance
        return try await search(query: query, context: context)
    }

    /// Get conversation history
    func getConversationHistory() -> [ConversationTurn] {
        return conversationHistory
    }

    /// Clear conversation history
    func clearConversation() {
        conversationHistory.removeAll()
        print("🗑️ Conversation history cleared")
    }

    // MARK: - Content Conversion

    private func convertToAnswer(scoredArticle: ScoredArticle) -> ContentAnswer {
        let article = scoredArticle.article

        // Get related strategies if available
        let strategies = getStrategies(for: article.relatedStrategies)

        return ContentAnswer(
            content: article.content,
            source: article.source,
            relevanceScore: scoredArticle.normalizedScore,
            strategies: strategies.isEmpty ? nil : strategies
        )
    }

    private func getStrategies(for strategyIDs: [UUID]) -> [Strategy] {
        guard let currentProfile = profileManager.currentProfile else {
            return []
        }

        return currentProfile.soothingStrategies.filter { strategy in
            strategyIDs.contains(strategy.id)
        }
    }

    // MARK: - Content Library

    private static func loadContentLibrary() -> SearchableContentLibrary {
        // For now, return a library with sample content
        // In production, this would load from JSON or database
        return createSampleContentLibrary()
    }

    private static func createSampleContentLibrary() -> SearchableContentLibrary {
        let articles = [
            // Meltdowns & Shutdowns
            ContentArticle(
                title: "Understanding Meltdowns vs Tantrums",
                content: """
                Meltdowns are not tantrums. A meltdown is an involuntary response to overwhelming sensory, emotional, or cognitive input. Unlike tantrums, which are goal-oriented behaviors, meltdowns happen when a child's nervous system is overwhelmed beyond their capacity to cope.

                During a meltdown, your child is not in control. They are experiencing a fight-flight-freeze response. The most important thing is to ensure safety and provide a calm, supportive presence.

                Key strategies:
                • Reduce sensory input (dim lights, quiet space)
                • Remove demands and expectations
                • Stay calm and present without overwhelming them
                • Allow time and space for recovery
                • Don't try to teach or reason during a meltdown

                After a meltdown, your child may need rest, comfort, or time alone. Respect their needs and avoid discussing what happened until they're fully regulated.
                """,
                section: "Crisis Support",
                topics: [.meltdowns, .emotionalRegulation, .coRegulation],
                keywords: ["meltdown", "tantrum", "overwhelm", "crisis", "shutdown", "fight or flight"],
                author: "Dr. Mona Delahooke",
                credibilityLevel: .expertRecommended
            ),

            ContentArticle(
                title: "Recognizing Shutdown vs Meltdown",
                content: """
                Shutdowns are often the lesser-known sibling of meltdowns. While meltdowns are externalized (crying, yelling, physical outbursts), shutdowns are internalized responses to overwhelm.

                Signs of a shutdown:
                • Becoming very quiet or non-verbal
                • Appearing "frozen" or unresponsive
                • Withdrawing from interaction
                • Flat or reduced facial expressions
                • Difficulty processing information

                During a shutdown:
                • Reduce all demands immediately
                • Provide a quiet, safe space
                • Don't force interaction or eye contact
                • Use minimal language
                • Allow recovery time without pressure

                Both meltdowns and shutdowns indicate nervous system overwhelm. The goal is not to prevent them (which creates more stress), but to create an environment where regulation is possible.
                """,
                section: "Crisis Support",
                topics: [.meltdowns, .emotionalRegulation],
                keywords: ["shutdown", "meltdown", "overwhelm", "quiet", "withdrawn", "freeze"],
                credibilityLevel: .expertRecommended
            ),

            // Sensory Processing
            ContentArticle(
                title: "Sensory-Friendly Environments",
                content: """
                Creating sensory-friendly spaces helps prevent overwhelm and supports regulation. Every neurodivergent child has unique sensory needs - some seek sensory input, others avoid it, and many need a combination.

                Key elements of sensory-friendly spaces:
                • Adjustable lighting (dimmers, natural light, blackout options)
                • Noise control (white noise machines, noise-canceling headphones)
                • Comfortable seating (bean bags, floor cushions, weighted blankets)
                • Visual calm (reduced clutter, neutral colors, organized spaces)
                • Access to sensory tools (fidgets, chewable items, textured objects)

                Observe your child's patterns:
                • When do they seem most comfortable?
                • What sensory inputs do they seek out?
                • What do they avoid or react negatively to?

                Use this information to create personalized sensory spaces at home and advocate for accommodations at school.
                """,
                section: "Environmental Support",
                topics: [.sensory, .routines],
                keywords: ["sensory", "environment", "space", "lighting", "noise", "comfort"],
                credibilityLevel: .communityValidated
            ),

            ContentArticle(
                title: "Deep Pressure and Proprioceptive Input",
                content: """
                Deep pressure and proprioceptive input (body awareness) are powerful regulation tools for many neurodivergent children. These inputs help the nervous system feel grounded and organized.

                Deep pressure techniques:
                • Weighted blankets or lap pads
                • Firm hugs or squeezes (with consent)
                • Compression clothing
                • Rolling a therapy ball over their body
                • Tight "burrito" wraps in blankets

                Proprioceptive activities:
                • Pushing or pulling heavy objects
                • Jumping on a trampoline
                • Animal walks (bear crawls, crab walks)
                • Carrying heavy items
                • Wall pushes or chair push-ups

                These aren't just calming strategies - they're essential sensory nutrition for many neurodivergent nervous systems. Build them into daily routines, not just crisis moments.
                """,
                section: "Sensory Strategies",
                topics: [.sensory, .coRegulation, .stimming],
                keywords: ["deep pressure", "proprioception", "weighted blanket", "compression", "heavy work"],
                credibilityLevel: .expertRecommended
            ),

            // Stimming
            ContentArticle(
                title: "Understanding and Supporting Stimming",
                content: """
                Stimming (self-stimulatory behavior) is a natural and important part of neurodivergent experience. Stims include repetitive movements, sounds, or behaviors that provide sensory input or emotional regulation.

                Common stims:
                • Hand flapping or finger movements
                • Rocking or bouncing
                • Vocal sounds or echolalia
                • Spinning or pacing
                • Touching or rubbing textures

                Why stimming matters:
                • Helps regulate the nervous system
                • Expresses emotions and excitement
                • Processes sensory information
                • Manages stress and anxiety
                • Part of neurodivergent identity and joy

                Never suppress stimming unless it causes harm. Instead:
                • Celebrate joyful stims (happy flaps!)
                • Provide safe alternatives if needed
                • Create stim-friendly spaces
                • Educate others about neurodiversity
                • Normalize stimming as healthy self-regulation

                If a stim is harmful, work with occupational therapy to find safer alternatives that meet the same sensory need.
                """,
                section: "Neurodiversity & Identity",
                topics: [.stimming, .selfCare, .strengths],
                keywords: ["stimming", "self-stimulation", "hand flapping", "rocking", "regulation", "sensory"],
                credibilityLevel: .communityValidated
            ),

            // Communication
            ContentArticle(
                title: "Supporting Non-Speaking and Minimally Speaking Children",
                content: """
                Non-speaking and minimally speaking children have important things to communicate. Lack of speech does not mean lack of understanding, intelligence, or feelings.

                Communication supports:
                • AAC devices (speech-generating devices)
                • Picture exchange systems (PECS)
                • Sign language
                • Visual schedules and choice boards
                • Writing or typing
                • Body language and gestures

                Presume competence:
                • Assume your child understands you
                • Give them time to process and respond
                • Don't speak about them as if they're not there
                • Provide multiple ways to communicate
                • Respect their communication attempts

                Some children are situationally non-speaking (able to speak sometimes but not others). This is valid and not "refusing" to speak. Support all forms of communication equally.
                """,
                section: "Communication",
                topics: [.communication, .advocacy],
                keywords: ["non-speaking", "AAC", "alternative communication", "speech", "language"],
                credibilityLevel: .expertRecommended
            ),

            // Transitions
            ContentArticle(
                title: "Making Transitions Easier",
                content: """
                Transitions between activities are often challenging for neurodivergent children. Predictability, preparation, and processing time make transitions smoother.

                Transition strategies:
                • Visual schedules showing the day's flow
                • Timer warnings (5 minutes, 2 minutes, 30 seconds)
                • Transition objects (bring something from one activity to another)
                • Verbal preparation ("In 5 minutes, we'll...")
                • Consistent routines and rituals
                • First-Then boards ("First bath, then book")

                Allow extra processing time:
                • Give warnings earlier than you think necessary
                • Pause after giving information
                • Use visual + verbal + written cues
                • Reduce demands during transitions

                Some children need longer to shift their attention and nervous system from one activity to another. This isn't defiance - it's neurodivergent processing.
                """,
                section: "Daily Living",
                topics: [.transitions, .routines, .communication],
                keywords: ["transition", "change", "schedule", "routine", "warning", "visual"],
                credibilityLevel: .communityValidated
            ),

            // Co-Regulation
            ContentArticle(
                title: "The Power of Co-Regulation",
                content: """
                Co-regulation is the foundation of emotional regulation. Children learn to regulate their nervous systems through connection with calm, regulated caregivers.

                Co-regulation principles:
                • Your calm is contagious
                • You can't pour from an empty cup (care for yourself first)
                • Presence over perfection
                • Connection before correction
                • Safety before behavior

                Co-regulation techniques:
                • Breathing together (match their breath, then slow)
                • Physical closeness (if wanted)
                • Calm voice and body language
                • Validating their feelings
                • Being a safe, stable presence

                Self-regulation is a developmental skill that takes years to develop. Don't expect your child to "calm themselves down" before they've experienced thousands of hours of co-regulation with you.

                Parent self-care IS co-regulation. You cannot regulate your child when you're dysregulated yourself.
                """,
                section: "Parenting Strategies",
                topics: [.coRegulation, .emotionalRegulation, .selfCare],
                keywords: ["co-regulation", "calm", "breathing", "connection", "presence", "parent"],
                credibilityLevel: .peerReviewed
            ),

            // Parent Self-Care
            ContentArticle(
                title: "Parent Self-Care Is Not Selfish",
                content: """
                Neurodiversity-affirming parenting is deeply rewarding and can also be exhausting. You cannot pour from an empty cup. Your wellbeing directly impacts your ability to support your child.

                Self-care essentials:
                • Rest when you can (imperfect sleep counts)
                • Ask for and accept help
                • Connect with other neurodivergent-affirming parents
                • Set boundaries with unhelpful advice
                • Celebrate small wins
                • Therapy or coaching for yourself

                Common parent struggles:
                • Burnout from constant advocacy
                • Grief over lost expectations
                • Isolation from unsupportive community
                • Sensory overload from caregiving
                • Decision fatigue

                You are doing important, hard work. Give yourself the same compassion and acceptance you give your child. Your regulation matters just as much as theirs.

                Consider: Are you also neurodivergent? Many parents discover their own neurodivergence through their child's journey.
                """,
                section: "Parent Support",
                topics: [.selfCare, .advocacy],
                keywords: ["parent", "self-care", "burnout", "exhaustion", "support", "rest"],
                credibilityLevel: .communityValidated
            )
        ]

        return SearchableContentLibrary(articles: articles)
    }
}
