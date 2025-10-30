//
//  ContentSearchManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 4 - Content Library & Management
//

import Foundation

/// Implementation of ContentSearchService
/// Provides keyword and basic semantic search
@MainActor
class ContentSearchManager: ContentSearchService {
    // MARK: - Singleton

    static let shared = ContentSearchManager()

    // MARK: - Dependencies

    private let contentLibrary: ContentLibraryService

    // MARK: - Initialization

    init(contentLibrary: ContentLibraryService = ContentLibraryManager.shared) {
        self.contentLibrary = contentLibrary
    }

    // MARK: - ContentSearchService Implementation

    func keywordSearch(keywords: [String]) async throws -> [ContentItem] {
        let allContent = try await contentLibrary.getAllContent()
        let lowercaseKeywords = keywords.map { $0.lowercased() }

        return allContent.filter { item in
            let searchableText = "\(item.title) \(item.body) \(item.tags.joined(separator: " "))".lowercased()

            // Check if any keyword matches
            return lowercaseKeywords.contains(where: { keyword in
                searchableText.contains(keyword)
            })
        }
    }

    func semanticSearch(query: String, limit: Int = 10) async throws -> [ContentItem] {
        // For MVP, use enhanced keyword search with ranking
        let allContent = try await contentLibrary.getAllContent()
        let lowercaseQuery = query.lowercased()
        let queryWords = lowercaseQuery.split(separator: " ").map { String($0) }

        // Score each item
        var scoredItems: [(item: ContentItem, score: Double)] = []

        for item in allContent {
            var score = 0.0

            // Title matches (highest weight)
            if item.title.lowercased().contains(lowercaseQuery) {
                score += 10.0
            }
            for word in queryWords {
                if item.title.lowercased().contains(word) {
                    score += 5.0
                }
            }

            // Tag matches (high weight)
            for tag in item.tags {
                if tag.lowercased().contains(lowercaseQuery) {
                    score += 8.0
                }
                for word in queryWords {
                    if tag.lowercased().contains(word) {
                        score += 4.0
                    }
                }
            }

            // Body matches (lower weight)
            if item.body.lowercased().contains(lowercaseQuery) {
                score += 3.0
            }
            for word in queryWords {
                if item.body.lowercased().contains(word) {
                    score += 1.5
                }
            }

            // Category matches
            if item.category.rawValue.lowercased().contains(lowercaseQuery) {
                score += 6.0
            }

            if score > 0 {
                scoredItems.append((item: item, score: score))
            }
        }

        // Sort by score and return top results
        scoredItems.sort { $0.score > $1.score }
        return scoredItems.prefix(limit).map { $0.item }
    }

    func contextualSearch(query: String, context: SearchContext) async throws -> [ContentItem] {
        // Start with semantic search
        var results = try await semanticSearch(query: query, limit: 50)

        // Apply contextual filtering

        // Filter by age
        if let age = context.childAge {
            results = results.filter { $0.isAppropriateForAge(age) }
        }

        // Filter by arousal band
        if let band = context.currentArousalBand {
            results = results.filter { $0.isRelevantForArousalBand(band) }
        }

        // Filter by emotion state
        if let emotion = context.currentEmotionState {
            results = results.filter { item in
                guard let emotions = item.emotionStates else { return true }
                return emotions.contains(where: { $0.lowercased() == emotion.lowercased() })
            }
        }

        // Boost items that match sensory profile
        if let sensoryPrefs = context.sensoryPreferences {
            results = boostBySensoryProfile(results, profile: sensoryPrefs)
        }

        return Array(results.prefix(10))
    }

    // MARK: - Private Methods

    private func boostBySensoryProfile(_ items: [ContentItem], profile: SensoryPreferences) -> [ContentItem] {
        // Simple boost: move sensory-matching items to front
        var sensoryMatched: [ContentItem] = []
        var others: [ContentItem] = []

        for item in items {
            if let sensoryProfiles = item.sensoryProfiles {
                var matches = false

                if profile.touch == .seeking && sensoryProfiles.contains("tactile-seeking") {
                    matches = true
                }
                if profile.touch == .avoiding && sensoryProfiles.contains("tactile-avoiding") {
                    matches = true
                }
                if profile.sound == .seeking && sensoryProfiles.contains("auditory-seeking") {
                    matches = true
                }
                if profile.sound == .avoiding && sensoryProfiles.contains("auditory-avoiding") {
                    matches = true
                }

                if matches {
                    sensoryMatched.append(item)
                } else {
                    others.append(item)
                }
            } else {
                others.append(item)
            }
        }

        return sensoryMatched + others
    }
}
