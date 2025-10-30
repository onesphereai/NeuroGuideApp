//
//  FollowUpQuestionGenerator.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Generates suggested follow-up questions based on conversation context
class FollowUpQuestionGenerator {

    // MARK: - Generate Follow-Ups

    /// Generate suggested follow-up questions based on the current result
    func generateFollowUps(for result: SearchResult, limit: Int = 3) -> [String] {
        guard let primaryAnswer = result.primaryAnswer else {
            return []
        }

        // Extract topics from the answer
        let topics = extractTopics(from: primaryAnswer)

        // Generate questions for each topic
        var suggestions: [String] = []

        for topic in topics {
            let topicQuestions = getFollowUpQuestions(for: topic)
            suggestions.append(contentsOf: topicQuestions)
        }

        // Remove duplicates and limit
        let uniqueSuggestions = Array(Set(suggestions))
        return Array(uniqueSuggestions.prefix(limit))
    }

    /// Generate contextual follow-ups based on conversation history
    func generateContextualFollowUps(
        for context: ConversationContext,
        currentResult: SearchResult,
        limit: Int = 3
    ) -> [String] {
        // Get topics from entire conversation
        let conversationTopics = extractTopicsFromContext(context)

        // Get topics from current answer
        let currentTopics = extractTopics(from: currentResult.primaryAnswer)

        // Combine and prioritize current topics
        let allTopics = currentTopics + conversationTopics.filter { !currentTopics.contains($0) }

        var suggestions: [String] = []

        for topic in allTopics {
            let topicQuestions = getFollowUpQuestions(for: topic)
            suggestions.append(contentsOf: topicQuestions)
        }

        // Filter out questions already asked
        let askedQuestions = Set(context.turns.map { $0.question.text.lowercased() })
        let filteredSuggestions = suggestions.filter { question in
            !askedQuestions.contains(question.lowercased())
        }

        return Array(Set(filteredSuggestions).prefix(limit))
    }

    // MARK: - Topic Extraction

    private func extractTopics(from answer: ContentAnswer?) -> [Topic] {
        guard let answer = answer else { return [] }

        var topics: [Topic] = []
        let content = answer.content.lowercased()

        // Check for topic keywords in content
        for topic in Topic.allCases {
            let keywords = getKeywordsForTopic(topic)
            if keywords.contains(where: { content.contains($0) }) {
                topics.append(topic)
            }
        }

        return topics
    }

    private func extractTopicsFromContext(_ context: ConversationContext) -> [Topic] {
        var topics: [Topic] = []

        for turn in context.turns {
            if let answer = turn.result.primaryAnswer {
                topics.append(contentsOf: extractTopics(from: answer))
            }
        }

        return Array(Set(topics))
    }

    private func getKeywordsForTopic(_ topic: Topic) -> [String] {
        switch topic {
        case .meltdowns:
            return ["meltdown", "shutdown", "tantrum", "overwhelm", "crisis"]
        case .sensory:
            return ["sensory", "sound", "touch", "smell", "texture", "noise"]
        case .communication:
            return ["communication", "speaking", "talking", "language", "aac"]
        case .transitions:
            return ["transition", "change", "routine", "schedule"]
        case .stimming:
            return ["stim", "stimming", "flapping", "rocking"]
        case .socialInteraction:
            return ["social", "friends", "play", "peer"]
        case .routines:
            return ["routine", "schedule", "predictability"]
        case .coRegulation:
            return ["co-regulation", "calming", "soothing"]
        case .emotionalRegulation:
            return ["emotion", "feelings", "regulation"]
        case .schoolSupport:
            return ["school", "teacher", "classroom", "iep"]
        case .selfCare:
            return ["parent", "self-care", "burnout"]
        case .advocacy:
            return ["advocate", "rights", "accommodations"]
        case .diagnosis:
            return ["autism", "adhd", "diagnosis"]
        case .strengths:
            return ["strengths", "abilities", "talents"]
        }
    }

    // MARK: - Question Templates

    private func getFollowUpQuestions(for topic: Topic) -> [String] {
        switch topic {
        case .meltdowns:
            return [
                "How long do meltdowns usually last?",
                "What's the difference between a meltdown and a shutdown?",
                "How can I prevent meltdowns from happening?",
                "What should I do after a meltdown is over?"
            ]
        case .sensory:
            return [
                "How do I know if my child is sensory seeking or avoiding?",
                "What are sensory-friendly activities?",
                "How can I create a sensory space at home?",
                "What is proprioceptive input?"
            ]
        case .communication:
            return [
                "What is AAC and how does it work?",
                "How can I support my non-speaking child?",
                "When should I introduce alternative communication?",
                "What if my child uses echolalia?"
            ]
        case .transitions:
            return [
                "How much warning time should I give before transitions?",
                "What are visual schedules?",
                "How can I make bedtime transitions easier?",
                "What about unexpected changes to routine?"
            ]
        case .stimming:
            return [
                "Is stimming harmful?",
                "Should I redirect stimming behaviors?",
                "How can I support happy stims?",
                "What if stimming happens at school?"
            ]
        case .socialInteraction:
            return [
                "Should I force my child to make eye contact?",
                "How can I support my child's friendships?",
                "What about parallel play?",
                "How do I handle social rejection?"
            ]
        case .routines:
            return [
                "How do I establish new routines?",
                "What about weekend versus weekday routines?",
                "How rigid should routines be?",
                "What are visual schedules?"
            ]
        case .coRegulation:
            return [
                "What is co-regulation?",
                "How do I stay calm when my child is dysregulated?",
                "What are co-regulation techniques?",
                "When should I give space versus stay close?"
            ]
        case .emotionalRegulation:
            return [
                "How do I teach emotional regulation?",
                "What are age-appropriate expectations?",
                "How can I help identify emotions?",
                "What about alexithymia?"
            ]
        case .schoolSupport:
            return [
                "What is an IEP?",
                "How do I advocate for accommodations?",
                "What about 504 plans?",
                "How can I work with teachers?"
            ]
        case .selfCare:
            return [
                "How do I avoid burnout?",
                "What are self-care strategies for parents?",
                "How do I ask for help?",
                "What about respite care?"
            ]
        case .advocacy:
            return [
                "How do I advocate for my child?",
                "What are my child's rights?",
                "How do I handle unsupportive family?",
                "What accommodations should I request?"
            ]
        case .diagnosis:
            return [
                "What does neurodivergent mean?",
                "How do I explain autism to my child?",
                "What about late diagnosis?",
                "Should I pursue formal diagnosis?"
            ]
        case .strengths:
            return [
                "How do I support special interests?",
                "What are neurodivergent strengths?",
                "How can I celebrate my child's abilities?",
                "What about intense interests?"
            ]
        }
    }
}
