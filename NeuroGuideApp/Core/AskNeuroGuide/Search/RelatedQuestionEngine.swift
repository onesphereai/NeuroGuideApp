//
//  RelatedQuestionEngine.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Generates related questions from content library based on article topics
class RelatedQuestionEngine {

    // MARK: - Generate Related Questions

    /// Generate related questions for an answer
    func generateRelatedQuestions(for answer: ContentAnswer, limit: Int = 3) -> [String] {
        // Extract topics from the answer's source article
        let topics = extractTopics(from: answer)

        // Generate questions for these topics
        var questions: [String] = []

        for topic in topics {
            let topicQuestions = getRelatedQuestions(for: topic)
            questions.append(contentsOf: topicQuestions)
        }

        // Remove duplicates and limit
        let uniqueQuestions = Array(Set(questions))
        return Array(uniqueQuestions.shuffled().prefix(limit))
    }

    /// Generate related questions from search result
    func generateRelatedQuestions(for result: SearchResult, limit: Int = 3) -> [String] {
        guard let primaryAnswer = result.primaryAnswer else {
            return []
        }

        return generateRelatedQuestions(for: primaryAnswer, limit: limit)
    }

    // MARK: - Topic Extraction

    private func extractTopics(from answer: ContentAnswer) -> [Topic] {
        var topics: [Topic] = []
        let content = (answer.source.title + " " + answer.content).lowercased()

        // Check for topic keywords in title and content
        for topic in Topic.allCases {
            let keywords = getKeywordsForTopic(topic)
            if keywords.contains(where: { content.contains($0) }) {
                topics.append(topic)
            }
        }

        return topics
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

    // MARK: - Related Question Templates

    private func getRelatedQuestions(for topic: Topic) -> [String] {
        switch topic {
        case .meltdowns:
            return [
                "What are early warning signs of a meltdown?",
                "How is a shutdown different from a meltdown?",
                "What should I do during a meltdown?",
                "How can I help my child recover after a meltdown?"
            ]
        case .sensory:
            return [
                "What is sensory processing disorder?",
                "How do I create a sensory-friendly home?",
                "What are sensory seeking vs sensory avoiding behaviors?",
                "What sensory tools can help my child?"
            ]
        case .communication:
            return [
                "What is augmentative and alternative communication?",
                "How do I support a non-speaking child?",
                "What is echolalia and is it helpful?",
                "How can I encourage communication without forcing speech?"
            ]
        case .transitions:
            return [
                "Why are transitions hard for autistic children?",
                "How do visual schedules help with transitions?",
                "What are transition warnings and how to use them?",
                "How can I make unexpected changes easier?"
            ]
        case .stimming:
            return [
                "What is stimming and why do autistic people stim?",
                "Is stimming harmful or should I allow it?",
                "How can I support my child's stims?",
                "What about stimming in public places?"
            ]
        case .socialInteraction:
            return [
                "Should I push my child to make friends?",
                "What is parallel play and is it okay?",
                "How do I support my child's social needs?",
                "What about teaching eye contact?"
            ]
        case .routines:
            return [
                "Why are routines important for autistic children?",
                "How rigid should routines be?",
                "How do I establish helpful routines?",
                "What about flexibility within routines?"
            ]
        case .coRegulation:
            return [
                "What is co-regulation?",
                "How do I co-regulate with my dysregulated child?",
                "What are co-regulation techniques?",
                "How do I stay calm when my child is dysregulated?"
            ]
        case .emotionalRegulation:
            return [
                "How do I teach emotional regulation?",
                "What is alexithymia?",
                "How can I help my child identify emotions?",
                "What are age-appropriate emotional regulation expectations?"
            ]
        case .schoolSupport:
            return [
                "What is an IEP and how do I get one?",
                "What's the difference between IEP and 504 plan?",
                "How do I advocate for my child at school?",
                "What accommodations should I request?"
            ]
        case .selfCare:
            return [
                "How do I avoid parenting burnout?",
                "What are self-care strategies for autism parents?",
                "How do I ask for help?",
                "What is respite care?"
            ]
        case .advocacy:
            return [
                "How do I advocate for my child?",
                "What are my child's legal rights?",
                "How do I handle unsupportive family members?",
                "What accommodations can I request?"
            ]
        case .diagnosis:
            return [
                "Should I pursue a formal autism diagnosis?",
                "How do I explain autism to my child?",
                "What is neurodivergent?",
                "What about late diagnosis?"
            ]
        case .strengths:
            return [
                "How do I support my child's special interests?",
                "What are neurodivergent strengths?",
                "How can I celebrate my child's unique abilities?",
                "Should I limit intense interests?"
            ]
        }
    }
}
