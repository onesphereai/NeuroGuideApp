//
//  SearchHistoryManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation
import Combine

/// Manages search history with local persistence
@MainActor
class SearchHistoryManager: ObservableObject {
    static let shared = SearchHistoryManager()

    // MARK: - Published Properties

    @Published private(set) var history: [SearchHistoryItem] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let historyKey = "neuroguide.searchHistory"
    private let maxHistoryItems = 50 // Keep last 50 searches

    // MARK: - Initialization

    init() {
        loadHistory()
    }

    // MARK: - History Management

    /// Add a search to history
    func addSearch(query: String, answerCount: Int) {
        // Remove duplicate if exists (keep most recent)
        history.removeAll { $0.query.lowercased() == query.lowercased() }

        // Create new history item
        let item = SearchHistoryItem(
            query: query,
            answerCount: answerCount
        )

        // Add to beginning
        history.insert(item, at: 0)

        // Limit to max items
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }

        saveHistory()
        print("✅ Search added to history: \(query)")
    }

    /// Remove a specific search from history
    func removeSearch(id: UUID) {
        guard let index = history.firstIndex(where: { $0.id == id }) else {
            print("⚠️ Search history item not found")
            return
        }

        let item = history[index]
        history.remove(at: index)
        saveHistory()
        print("🗑️ Search removed from history: \(item.query)")
    }

    /// Clear all search history
    func clearHistory() {
        history.removeAll()
        saveHistory()
        print("🗑️ Search history cleared")
    }

    // MARK: - Search and Filtering

    /// Get recent searches (last N items)
    func getRecentSearches(limit: Int = 5) -> [SearchHistoryItem] {
        Array(history.prefix(limit))
    }

    /// Search history by query text
    func searchHistory(matching query: String) -> [SearchHistoryItem] {
        guard !query.isEmpty else { return history }

        return history.filter { item in
            item.query.localizedCaseInsensitiveContains(query)
        }
    }

    /// Get searches grouped by date
    func getGroupedHistory() -> [String: [SearchHistoryItem]] {
        Dictionary(grouping: history) { $0.dateSection }
    }

    /// Get most common searches
    func getFrequentSearches(limit: Int = 5) -> [String] {
        // Count occurrences of similar queries
        var queryCounts: [String: Int] = [:]

        for item in history {
            let normalizedQuery = item.query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            queryCounts[normalizedQuery, default: 0] += 1
        }

        // Sort by count and return top queries
        return queryCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    // MARK: - Statistics

    /// Total number of searches
    var totalSearches: Int {
        history.count
    }

    /// Average answer count
    var averageAnswerCount: Double {
        guard !history.isEmpty else { return 0 }
        let total = history.reduce(0) { $0 + $1.answerCount }
        return Double(total) / Double(history.count)
    }

    // MARK: - Persistence

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            userDefaults.set(data, forKey: historyKey)
            print("💾 Search history saved: \(history.count) items")
        } catch {
            print("❌ Failed to save search history: \(error)")
        }
    }

    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey) else {
            print("ℹ️ No saved search history found")
            return
        }

        do {
            history = try JSONDecoder().decode([SearchHistoryItem].self, from: data)
            print("✅ Search history loaded: \(history.count) items")
        } catch {
            print("❌ Failed to load search history: \(error)")
            history = []
        }
    }
}
