//
//  ContentLibrary.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Content library containing all searchable content for Ask NeuroGuide
struct SearchableContentLibrary: Codable {
    let articles: [ContentArticle]
    let topics: [Topic]

    init(articles: [ContentArticle], topics: [Topic] = []) {
        self.articles = articles
        self.topics = topics
    }

    /// Get all articles for a specific topic
    func articles(for topic: Topic) -> [ContentArticle] {
        return articles.filter { $0.topics.contains(topic) }
    }

    /// Search articles by keywords
    func search(keywords: [String]) -> [ContentArticle] {
        return articles.filter { article in
            keywords.contains { keyword in
                article.title.localizedCaseInsensitiveContains(keyword) ||
                article.content.localizedCaseInsensitiveContains(keyword) ||
                article.keywords.contains { $0.localizedCaseInsensitiveContains(keyword) }
            }
        }
    }
}

/// A single article in the content library
struct ContentArticle: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let content: String
    let section: String
    let topics: [Topic]
    let keywords: [String]
    let author: String?
    let credibilityLevel: CredibilityLevel
    let relatedStrategies: [UUID]  // Strategy IDs
    let lastUpdated: Date

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        section: String,
        topics: [Topic],
        keywords: [String],
        author: String? = nil,
        credibilityLevel: CredibilityLevel,
        relatedStrategies: [UUID] = [],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.section = section
        self.topics = topics
        self.keywords = keywords
        self.author = author
        self.credibilityLevel = credibilityLevel
        self.relatedStrategies = relatedStrategies
        self.lastUpdated = lastUpdated
    }

    /// Create ContentSource for this article
    var source: ContentSource {
        return ContentSource(
            title: title,
            section: section,
            author: author,
            credibilityLevel: credibilityLevel
        )
    }
}

/// Topic categories for content organization
enum Topic: String, Codable, CaseIterable {
    case meltdowns = "Meltdowns & Shutdowns"
    case sensory = "Sensory Processing"
    case communication = "Communication"
    case transitions = "Transitions"
    case stimming = "Stimming & Self-Regulation"
    case socialInteraction = "Social Interaction"
    case routines = "Routines & Structure"
    case coRegulation = "Co-Regulation"
    case emotionalRegulation = "Emotional Regulation"
    case schoolSupport = "School Support"
    case selfCare = "Parent Self-Care"
    case advocacy = "Advocacy & Rights"
    case diagnosis = "Understanding Neurodivergence"
    case strengths = "Strengths & Abilities"

    var displayName: String {
        return rawValue
    }

    var icon: String {
        switch self {
        case .meltdowns: return "exclamationmark.octagon"
        case .sensory: return "waveform.path"
        case .communication: return "bubble.left.and.bubble.right"
        case .transitions: return "arrow.left.arrow.right"
        case .stimming: return "hand.raised.fill"
        case .socialInteraction: return "person.2.fill"
        case .routines: return "calendar"
        case .coRegulation: return "heart.fill"
        case .emotionalRegulation: return "face.smiling"
        case .schoolSupport: return "book.fill"
        case .selfCare: return "leaf.fill"
        case .advocacy: return "megaphone.fill"
        case .diagnosis: return "brain.head.profile"
        case .strengths: return "star.fill"
        }
    }
}
