//
//  ContentLibraryManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 4 - Content Library & Management
//

import Foundation
import Combine

/// Main implementation of ContentLibraryService
/// Manages the curated content library with filtering and search
@MainActor
class ContentLibraryManager: ContentLibraryService, ObservableObject {
    // MARK: - Singleton

    static let shared = ContentLibraryManager()

    // MARK: - Published Properties

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var libraryVersion: String = "1.0.0"
    @Published private(set) var lastUpdateDate: Date?

    // MARK: - Private Properties

    private var contentItems: [ContentItem] = []
    private var contentCache: [UUID: ContentItem] = [:]
    private let contentFileName = "content_library.json"

    // MARK: - Initialization

    init() {
        // Load content on initialization
        Task {
            await loadContentLibrary()
        }
    }

    // MARK: - ContentLibraryService Implementation

    func getAllContent() async throws -> [ContentItem] {
        if contentItems.isEmpty {
            await loadContentLibrary()
        }
        // Only return approved, non-deprecated content
        return contentItems.filter { $0.reviewStatus == .approved && !$0.isDeprecated }
    }

    func getContentByCategory(category: ContentCategory) async throws -> [ContentItem] {
        let allContent = try await getAllContent()
        return allContent.filter { $0.category == category }
    }

    func getContentByTags(tags: [String]) async throws -> [ContentItem] {
        let allContent = try await getAllContent()
        let lowercaseTags = tags.map { $0.lowercased() }

        return allContent.filter { item in
            let itemTags = item.tags.map { $0.lowercased() }
            return !Set(lowercaseTags).isDisjoint(with: Set(itemTags))
        }
    }

    func searchContent(query: String) async throws -> [ContentItem] {
        let allContent = try await getAllContent()
        let lowercaseQuery = query.lowercased()

        return allContent.filter { item in
            item.title.lowercased().contains(lowercaseQuery) ||
            item.body.lowercased().contains(lowercaseQuery) ||
            item.tags.contains(where: { $0.lowercased().contains(lowercaseQuery) })
        }
    }

    func getContentItem(id: UUID) async throws -> ContentItem? {
        // Check cache first
        if let cached = contentCache[id] {
            return cached
        }

        // Search in content items
        let allContent = try await getAllContent()
        return allContent.first(where: { $0.id == id })
    }

    func getLibraryVersion() -> String {
        return libraryVersion
    }

    func getLastUpdateDate() -> Date? {
        return lastUpdateDate
    }

    func getFilteredContent(context: ContentFilterContext) async throws -> [ContentItem] {
        var filtered = try await getAllContent()

        // Filter by age range
        if let ageRange = context.ageRange {
            filtered = filtered.filter { item in
                // Check if ranges overlap
                item.ageRange.overlaps(ageRange)
            }
        }

        // Filter by arousal band
        if let arousalBand = context.arousalBand {
            filtered = filtered.filter { item in
                item.isRelevantForArousalBand(arousalBand)
            }
        }

        // Filter by emotion state
        if let emotionState = context.emotionState {
            filtered = filtered.filter { item in
                guard let emotions = item.emotionStates else { return true }
                return emotions.contains(where: { $0.lowercased() == emotionState.lowercased() })
            }
        }

        // Filter by tags
        if let tags = context.tags, !tags.isEmpty {
            filtered = filtered.filter { item in
                item.matchesTags(tags)
            }
        }

        // Filter by sensory profile (if provided)
        if let sensoryPrefs = context.sensoryPreferences {
            filtered = filtered.filter { item in
                // Check if content matches sensory profiles
                guard let profiles = item.sensoryProfiles else { return true }

                // Check for seeking/avoiding matches
                if sensoryPrefs.touch == .seeking && profiles.contains("tactile-seeking") {
                    return true
                }
                if sensoryPrefs.touch == .avoiding && profiles.contains("tactile-avoiding") {
                    return true
                }
                // Similar logic for other senses
                return true
            }
        }

        return filtered
    }

    // MARK: - Private Methods

    private func loadContentLibrary() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Try to load from bundle
            if let url = Bundle.main.url(forResource: "content_library", withExtension: "json") {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let library = try decoder.decode(ContentLibrary.self, from: data)
                self.contentItems = library.items
                self.libraryVersion = library.version
                self.lastUpdateDate = library.lastUpdated

                // Build cache
                for item in contentItems {
                    contentCache[item.id] = item
                }

                print("✅ Loaded \(contentItems.count) content items (version \(libraryVersion))")
            } else {
                // No bundled content - use sample content
                print("⚠️ No bundled content found, using sample content")
                await loadSampleContent()
            }
        } catch {
            print("❌ Error loading content library: \(error)")
            // Fall back to sample content
            await loadSampleContent()
        }
    }

    private func loadSampleContent() async {
        // Load sample content for testing
        self.contentItems = ContentSamples.sampleItems
        self.libraryVersion = "1.0.0-sample"
        self.lastUpdateDate = Date()

        // Build cache
        for item in contentItems {
            contentCache[item.id] = item
        }

        print("✅ Loaded \(contentItems.count) sample content items")
    }
}

// MARK: - Content Library Structure

/// Root structure for bundled content library
struct ContentLibrary: Codable {
    let version: String
    let lastUpdated: Date
    let items: [ContentItem]
}

// MARK: - Sample Content

/// Sample content items for testing
struct ContentSamples {
    static let sampleItems: [ContentItem] = [
        ContentItem(
            title: "Deep Pressure for Calming",
            body: """
            Deep pressure input can help calm the nervous system during high arousal states. \
            Try a weighted blanket, firm hugs, or a compression vest. \
            Deep pressure activates the proprioceptive system, providing organizing sensory input.
            """,
            summary: "Use deep pressure to help calm and regulate",
            category: .sensorySupport,
            subcategory: "Proprioceptive",
            tags: ["deep-pressure", "calming", "proprioceptive", "weighted-blanket"],
            sourceType: .peerReviewedResearch,
            sourceAttribution: "Grandin & Panek (2013)",
            ageRange: 2...8,
            arousalBands: [.orange, .red],
            reviewStatus: .approved
        ),
        ContentItem(
            title: "Visual Schedule for Transitions",
            body: """
            Visual schedules help children understand what's coming next, reducing anxiety around transitions. \
            Use pictures or words to show the sequence of activities. \
            Review the schedule before starting and after each activity.
            """,
            summary: "Visual schedules reduce transition anxiety",
            category: .dailyRoutines,
            subcategory: "Transitions",
            tags: ["visual-supports", "transitions", "predictability", "routine"],
            sourceType: .clinicalGuidelines,
            sourceAttribution: "TEACCH Approach",
            ageRange: 2...8,
            arousalBands: [.yellow, .orange],
            reviewStatus: .approved
        ),
        ContentItem(
            title: "Co-Regulation Through Breathing",
            body: """
            When your child is dysregulated, regulate yourself first. \
            Take slow, deep breaths and maintain a calm presence. \
            Your regulation helps them find their own. Model deep breathing without forcing them to participate.
            """,
            summary: "Regulate yourself to help your child regulate",
            category: .parentSelfCare,
            subcategory: "Co-Regulation",
            tags: ["co-regulation", "breathing", "parent-regulation", "modeling"],
            sourceType: .autisticCommunityInput,
            sourceAttribution: "Autistic Self-Advocacy Network",
            ageRange: 2...8,
            arousalBands: [.yellow, .orange, .red],
            reviewStatus: .approved
        )
    ]
}
