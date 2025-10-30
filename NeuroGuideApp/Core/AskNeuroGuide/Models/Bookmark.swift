//
//  Bookmark.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Represents a bookmarked answer for later reference
struct Bookmark: Identifiable, Codable, Equatable {
    let id: UUID
    let answer: ContentAnswer
    let question: String
    let bookmarkedAt: Date

    init(
        id: UUID = UUID(),
        answer: ContentAnswer,
        question: String,
        bookmarkedAt: Date = Date()
    ) {
        self.id = id
        self.answer = answer
        self.question = question
        self.bookmarkedAt = bookmarkedAt
    }
}

// MARK: - Bookmark Extensions

extension Bookmark {
    /// Display name for the bookmark (uses source title)
    var displayName: String {
        answer.source.title
    }

    /// Formatted date string
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: bookmarkedAt, relativeTo: Date())
    }
}
