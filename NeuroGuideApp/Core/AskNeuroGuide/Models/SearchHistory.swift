//
//  SearchHistory.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Represents a search query in the history
struct SearchHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let timestamp: Date
    let answerCount: Int

    init(
        id: UUID = UUID(),
        query: String,
        timestamp: Date = Date(),
        answerCount: Int = 0
    ) {
        self.id = id
        self.query = query
        self.timestamp = timestamp
        self.answerCount = answerCount
    }
}

// MARK: - Extensions

extension SearchHistoryItem {
    /// Formatted relative date string
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Short date string for grouping
    var dateSection: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            return "Today"
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else if calendar.isDate(timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
            return "This Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: timestamp)
        }
    }
}
