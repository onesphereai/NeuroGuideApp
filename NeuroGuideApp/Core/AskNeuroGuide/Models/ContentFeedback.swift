//
//  ContentFeedback.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Represents user feedback on a content answer
struct ContentFeedback: Identifiable, Codable, Equatable {
    let id: UUID
    let answerId: UUID
    let isHelpful: Bool
    let timestamp: Date
    let questionText: String?

    init(
        id: UUID = UUID(),
        answerId: UUID,
        isHelpful: Bool,
        timestamp: Date = Date(),
        questionText: String? = nil
    ) {
        self.id = id
        self.answerId = answerId
        self.isHelpful = isHelpful
        self.timestamp = timestamp
        self.questionText = questionText
    }
}

// MARK: - Feedback Statistics

struct FeedbackStatistics {
    let totalFeedback: Int
    let helpfulCount: Int
    let notHelpfulCount: Int

    var helpfulPercentage: Double {
        guard totalFeedback > 0 else { return 0 }
        return Double(helpfulCount) / Double(totalFeedback) * 100
    }

    var notHelpfulPercentage: Double {
        guard totalFeedback > 0 else { return 0 }
        return Double(notHelpfulCount) / Double(totalFeedback) * 100
    }
}
