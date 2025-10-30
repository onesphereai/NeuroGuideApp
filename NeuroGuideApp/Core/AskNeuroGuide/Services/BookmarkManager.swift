//
//  BookmarkManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation
import Combine

/// Manages bookmarked content for later reference
@MainActor
class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    // MARK: - Published Properties

    @Published private(set) var bookmarks: [Bookmark] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let bookmarksKey = "neuroguide.bookmarks"

    // MARK: - Initialization

    init() {
        loadBookmarks()
    }

    // MARK: - Bookmark Management

    /// Check if an answer is bookmarked
    func isBookmarked(answerId: UUID) -> Bool {
        bookmarks.contains { $0.answer.id == answerId }
    }

    /// Add a bookmark
    func addBookmark(answer: ContentAnswer, question: String) {
        // Check if already bookmarked
        guard !isBookmarked(answerId: answer.id) else {
            print("⚠️ Answer already bookmarked")
            return
        }

        let bookmark = Bookmark(
            answer: answer,
            question: question
        )

        bookmarks.append(bookmark)
        saveBookmarks()

        print("✅ Bookmark added: \(answer.source.title)")
    }

    /// Remove a bookmark by answer ID
    func removeBookmark(answerId: UUID) {
        guard let index = bookmarks.firstIndex(where: { $0.answer.id == answerId }) else {
            print("⚠️ Bookmark not found")
            return
        }

        let bookmark = bookmarks[index]
        bookmarks.remove(at: index)
        saveBookmarks()

        print("🗑️ Bookmark removed: \(bookmark.answer.source.title)")
    }

    /// Toggle bookmark state for an answer
    func toggleBookmark(answer: ContentAnswer, question: String) {
        if isBookmarked(answerId: answer.id) {
            removeBookmark(answerId: answer.id)
        } else {
            addBookmark(answer: answer, question: question)
        }
    }

    /// Remove a bookmark by bookmark ID
    func removeBookmark(id: UUID) {
        guard let index = bookmarks.firstIndex(where: { $0.id == id }) else {
            print("⚠️ Bookmark not found")
            return
        }

        let bookmark = bookmarks[index]
        bookmarks.remove(at: index)
        saveBookmarks()

        print("🗑️ Bookmark removed: \(bookmark.answer.source.title)")
    }

    /// Clear all bookmarks
    func clearAllBookmarks() {
        bookmarks.removeAll()
        saveBookmarks()
        print("🗑️ All bookmarks cleared")
    }

    // MARK: - Sorting and Filtering

    /// Get bookmarks sorted by date (newest first)
    func getBookmarksByDate() -> [Bookmark] {
        bookmarks.sorted { $0.bookmarkedAt > $1.bookmarkedAt }
    }

    /// Get bookmarks sorted by source credibility
    func getBookmarksByCredibility() -> [Bookmark] {
        bookmarks.sorted { lhs, rhs in
            if lhs.answer.source.credibilityLevel == rhs.answer.source.credibilityLevel {
                return lhs.bookmarkedAt > rhs.bookmarkedAt
            }
            return lhs.answer.source.credibilityLevel.rawValue < rhs.answer.source.credibilityLevel.rawValue
        }
    }

    /// Get bookmarks filtered by topic
    func getBookmarks(forTopic topic: Topic) -> [Bookmark] {
        bookmarks.filter { bookmark in
            // Check if answer content contains topic keywords
            let content = bookmark.answer.content.lowercased()
            let keywords = getKeywordsForTopic(topic)
            return keywords.contains(where: { content.contains($0) })
        }
    }

    // MARK: - Persistence

    private func saveBookmarks() {
        do {
            let data = try JSONEncoder().encode(bookmarks)
            userDefaults.set(data, forKey: bookmarksKey)
            print("💾 Bookmarks saved: \(bookmarks.count) items")
        } catch {
            print("❌ Failed to save bookmarks: \(error)")
        }
    }

    private func loadBookmarks() {
        guard let data = userDefaults.data(forKey: bookmarksKey) else {
            print("ℹ️ No saved bookmarks found")
            return
        }

        do {
            bookmarks = try JSONDecoder().decode([Bookmark].self, from: data)
            print("✅ Bookmarks loaded: \(bookmarks.count) items")
        } catch {
            print("❌ Failed to load bookmarks: \(error)")
            bookmarks = []
        }
    }

    // MARK: - Topic Keywords (duplicated from FollowUpQuestionGenerator for now)

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
}
