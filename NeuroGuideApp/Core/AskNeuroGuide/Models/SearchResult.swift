//
//  SearchResult.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Result from searching the content library
struct SearchResult: Identifiable, Codable, Equatable {
    let id: UUID
    let query: Question
    let answers: [ContentAnswer]
    let conversationContext: ConversationContext?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        query: Question,
        answers: [ContentAnswer],
        conversationContext: ConversationContext? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.query = query
        self.answers = answers
        self.conversationContext = conversationContext
        self.timestamp = timestamp
    }

    /// Primary answer (highest relevance)
    var primaryAnswer: ContentAnswer? {
        return answers.first
    }

    /// Whether there are multiple relevant answers
    var hasMultipleAnswers: Bool {
        return answers.count > 1
    }
}

/// A single answer from the content library
struct ContentAnswer: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let source: ContentSource
    let relevanceScore: Double // 0-1
    let strategies: [Strategy]?
    let resourceCitations: [ResourceCitation]?  // NEW: LLM-generated resource links

    init(
        id: UUID = UUID(),
        content: String,
        source: ContentSource,
        relevanceScore: Double,
        strategies: [Strategy]? = nil,
        resourceCitations: [ResourceCitation]? = nil
    ) {
        self.id = id
        self.content = content
        self.source = source
        self.relevanceScore = relevanceScore
        self.strategies = strategies
        self.resourceCitations = resourceCitations
    }

    /// Display relevance as percentage
    var relevancePercentage: Int {
        return Int(relevanceScore * 100)
    }
}

/// Resource citation from LLM response
struct ResourceCitation: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let url: String
    let description: String?

    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        description: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.description = description
    }
}

/// Source of content (for attribution)
struct ContentSource: Codable, Equatable {
    let title: String
    let section: String?
    let author: String?
    let credibilityLevel: CredibilityLevel

    var displayName: String {
        if let section = section {
            return "\(title) - \(section)"
        }
        return title
    }
}

/// Credibility level of the source
enum CredibilityLevel: String, Codable, CaseIterable {
    case peerReviewed = "peer_reviewed"
    case expertRecommended = "expert_recommended"
    case communityValidated = "community_validated"

    var displayName: String {
        switch self {
        case .peerReviewed:
            return "Peer-Reviewed Research"
        case .expertRecommended:
            return "Expert-Recommended"
        case .communityValidated:
            return "Community-Validated"
        }
    }

    var icon: String {
        switch self {
        case .peerReviewed:
            return "doc.text.magnifyingglass"
        case .expertRecommended:
            return "person.badge.shield.checkmark"
        case .communityValidated:
            return "checkmark.seal.fill"
        }
    }

    var description: String {
        switch self {
        case .peerReviewed:
            return "Published in peer-reviewed journals"
        case .expertRecommended:
            return "Recommended by neurodiversity experts"
        case .communityValidated:
            return "Validated by the neurodivergent community"
        }
    }
}
