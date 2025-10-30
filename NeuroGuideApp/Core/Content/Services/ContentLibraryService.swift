//
//  ContentLibraryService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 4 - Content Library & Management
//

import Foundation

/// Service for accessing the content library
protocol ContentLibraryService {
    /// Get all content items
    func getAllContent() async throws -> [ContentItem]

    /// Get content by category
    func getContentByCategory(category: ContentCategory) async throws -> [ContentItem]

    /// Get content by tags
    func getContentByTags(tags: [String]) async throws -> [ContentItem]

    /// Search content by keyword
    func searchContent(query: String) async throws -> [ContentItem]

    /// Get a specific content item by ID
    func getContentItem(id: UUID) async throws -> ContentItem?

    /// Get library version
    func getLibraryVersion() -> String

    /// Get last update date
    func getLastUpdateDate() -> Date?

    /// Get content filtered by context
    func getFilteredContent(context: ContentFilterContext) async throws -> [ContentItem]
}

/// Service for filtering and validating content
protocol ContentFilteringService {
    /// Filter content by multiple criteria
    func filterContent(arousalBand: ArousalBand?, emotionState: String?, age: Int?) async throws -> [ContentItem]

    /// Filter by sensory profile
    func filterBySensoryProfile(profile: SensoryPreferences) async throws -> [ContentItem]

    /// Validate content against red-flag terms
    func validateContent(text: String) -> ContentValidationResult

    /// Get all red-flag terms
    func getRedFlagTerms() -> [String]

    /// Get suggested alternative for a flagged term
    func getAlternative(for term: String) -> String?
}

/// Service for searching content
protocol ContentSearchService {
    /// Keyword search
    func keywordSearch(keywords: [String]) async throws -> [ContentItem]

    /// Semantic search (simple implementation)
    func semanticSearch(query: String, limit: Int) async throws -> [ContentItem]

    /// Contextual search using profile and current state
    func contextualSearch(query: String, context: SearchContext) async throws -> [ContentItem]
}

/// Context for content search
struct SearchContext {
    let currentArousalBand: ArousalBand?
    let currentEmotionState: String?
    let childAge: Int?
    let sensoryPreferences: SensoryPreferences?

    init(
        currentArousalBand: ArousalBand? = nil,
        currentEmotionState: String? = nil,
        childAge: Int? = nil,
        sensoryPreferences: SensoryPreferences? = nil
    ) {
        self.currentArousalBand = currentArousalBand
        self.currentEmotionState = currentEmotionState
        self.childAge = childAge
        self.sensoryPreferences = sensoryPreferences
    }

    /// Create search context from a child profile
    static func from(profile: ChildProfile, arousalBand: ArousalBand? = nil, emotionState: String? = nil) -> SearchContext {
        return SearchContext(
            currentArousalBand: arousalBand,
            currentEmotionState: emotionState,
            childAge: profile.age,
            sensoryPreferences: profile.sensoryPreferences
        )
    }
}

/// Service for content updates and versioning
protocol ContentUpdateService {
    /// Check if updates are available
    func checkForUpdates() async throws -> ContentUpdateInfo?

    /// Download an update
    func downloadUpdate(updateInfo: ContentUpdateInfo) async throws

    /// Apply a downloaded update
    func applyUpdate() async throws

    /// Get update history
    func getUpdateHistory() -> [ContentUpdate]
}

/// Information about a content update
struct ContentUpdateInfo: Codable {
    let version: String
    let releaseDate: Date
    let changeCount: Int
    let downloadSize: Int64
    let changeLog: String
}

/// Record of a content update
struct ContentUpdate: Codable {
    let version: String
    let appliedDate: Date
    let changeCount: Int
    let changesSummary: String
}
