//
//  SemanticSearchEngine.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Semantic search engine for content retrieval
/// Uses keyword matching and relevance scoring
class SemanticSearchEngine {
    // MARK: - Search

    /// Search articles with relevance scoring
    func search(query: String, in library: SearchableContentLibrary, limit: Int = 5) -> [ScoredArticle] {
        // Extract keywords from query
        let keywords = extractKeywords(from: query)

        // Score all articles
        let scoredArticles = library.articles.compactMap { article -> ScoredArticle? in
            let score = calculateRelevanceScore(article: article, keywords: keywords, query: query)

            // Only return articles with score > 0
            guard score > 0 else { return nil }

            return ScoredArticle(article: article, score: score)
        }

        // Sort by score (highest first) and limit results
        return scoredArticles
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    /// Search with conversation context for follow-up questions
    func search(
        query: String,
        in library: SearchableContentLibrary,
        context: ConversationContext?,
        limit: Int = 5
    ) -> [ScoredArticle] {
        // If we have context, boost relevance for articles matching previous topics
        guard let context = context else {
            return search(query: query, in: library, limit: limit)
        }

        let keywords = extractKeywords(from: query)
        let contextTopics = extractTopicsFromContext(context)

        let scoredArticles = library.articles.compactMap { article -> ScoredArticle? in
            var score = calculateRelevanceScore(article: article, keywords: keywords, query: query)

            // Boost score if article matches context topics
            let topicBoost = calculateTopicBoost(article: article, contextTopics: contextTopics)
            score *= (1.0 + topicBoost)

            guard score > 0 else { return nil }

            return ScoredArticle(article: article, score: score)
        }

        return scoredArticles
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Keyword Extraction

    private func extractKeywords(from query: String) -> [String] {
        // Lowercase and split into words
        let words = query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        // Remove common stop words
        let stopWords = Set([
            "a", "an", "and", "are", "as", "at", "be", "by", "for",
            "from", "has", "he", "in", "is", "it", "its", "of", "on",
            "that", "the", "to", "was", "will", "with", "i", "my",
            "me", "how", "what", "when", "where", "why", "can", "do",
            "does", "should"
        ])

        let keywords = words.filter { !stopWords.contains($0) }

        // Also extract common neurodiversity terms
        let specialTerms = extractSpecialTerms(from: query.lowercased())

        return keywords + specialTerms
    }

    private func extractSpecialTerms(from query: String) -> [String] {
        var terms: [String] = []

        // Common neurodiversity phrases (multi-word)
        let phrases = [
            "sensory overload", "sensory processing", "meltdown", "shutdown",
            "flat affect", "emotional regulation", "self regulation",
            "co regulation", "social interaction", "communication support",
            "visual schedule", "deep pressure", "stimming", "hand flapping",
            "eye contact", "routine", "transition", "alexithymia"
        ]

        for phrase in phrases {
            if query.contains(phrase) {
                terms.append(phrase)
            }
        }

        return terms
    }

    // MARK: - Relevance Scoring

    private func calculateRelevanceScore(
        article: ContentArticle,
        keywords: [String],
        query: String
    ) -> Double {
        var score = 0.0

        let articleText = (article.title + " " + article.content + " " + article.keywords.joined(separator: " ")).lowercased()

        // Exact phrase match (highest weight)
        if articleText.contains(query.lowercased()) {
            score += 10.0
        }

        // Title keyword matches (high weight)
        for keyword in keywords {
            if article.title.lowercased().contains(keyword) {
                score += 3.0
            }
        }

        // Keyword matches in content (medium weight)
        for keyword in keywords {
            if article.keywords.contains(where: { $0.lowercased().contains(keyword) }) {
                score += 2.0
            }
        }

        // Content matches (lower weight)
        for keyword in keywords {
            if article.content.lowercased().contains(keyword) {
                score += 1.0
            }
        }

        // Credibility boost
        let credibilityMultiplier: Double
        switch article.credibilityLevel {
        case .peerReviewed:
            credibilityMultiplier = 1.2
        case .expertRecommended:
            credibilityMultiplier = 1.1
        case .communityValidated:
            credibilityMultiplier = 1.0
        }

        score *= credibilityMultiplier

        return score
    }

    private func calculateTopicBoost(
        article: ContentArticle,
        contextTopics: Set<Topic>
    ) -> Double {
        // Boost if article matches topics from conversation context
        let matchingTopics = Set(article.topics).intersection(contextTopics)

        if matchingTopics.isEmpty {
            return 0.0
        }

        // Boost by 20% for each matching topic (max 60%)
        return min(0.6, Double(matchingTopics.count) * 0.2)
    }

    private func extractTopicsFromContext(_ context: ConversationContext) -> Set<Topic> {
        // Extract topics mentioned in conversation
        var topics = Set<Topic>()

        for turn in context.turns {
            // Simple topic detection based on keywords in questions
            let query = turn.question.text.lowercased()

            for topic in Topic.allCases {
                let topicKeywords = getKeywordsForTopic(topic)
                if topicKeywords.contains(where: { query.contains($0) }) {
                    topics.insert(topic)
                }
            }
        }

        return topics
    }

    private func getKeywordsForTopic(_ topic: Topic) -> [String] {
        switch topic {
        case .meltdowns:
            return ["meltdown", "shutdown", "tantrum", "overwhelm", "overload"]
        case .sensory:
            return ["sensory", "sound", "touch", "smell", "texture", "noise"]
        case .communication:
            return ["communication", "speaking", "talking", "language", "words"]
        case .transitions:
            return ["transition", "change", "switch", "routine change"]
        case .stimming:
            return ["stim", "stimming", "self-soothing", "hand flapping", "rocking"]
        case .socialInteraction:
            return ["social", "friends", "play", "interaction", "peer"]
        case .routines:
            return ["routine", "schedule", "consistency", "predictability"]
        case .coRegulation:
            return ["co-regulation", "calming", "soothing", "comfort"]
        case .emotionalRegulation:
            return ["emotion", "feelings", "regulation", "dysregulation"]
        case .schoolSupport:
            return ["school", "teacher", "classroom", "education", "IEP"]
        case .selfCare:
            return ["parent", "self-care", "burnout", "stress"]
        case .advocacy:
            return ["advocate", "rights", "support", "accommodations"]
        case .diagnosis:
            return ["autism", "ADHD", "neurodivergent", "diagnosis"]
        case .strengths:
            return ["strengths", "abilities", "talents", "special interest"]
        }
    }
}

// MARK: - Supporting Types

/// Article with relevance score
struct ScoredArticle {
    let article: ContentArticle
    let score: Double

    /// Normalized relevance score (0-1)
    var normalizedScore: Double {
        // Normalize score to 0-1 range
        // Scores typically range from 1-20+
        return min(1.0, score / 20.0)
    }
}
