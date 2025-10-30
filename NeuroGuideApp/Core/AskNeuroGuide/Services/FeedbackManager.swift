//
//  FeedbackManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation
import Combine

/// Manages content feedback with local persistence
@MainActor
class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()

    // MARK: - Published Properties

    @Published private(set) var feedback: [ContentFeedback] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let feedbackKey = "neuroguide.contentFeedback"

    // MARK: - Initialization

    init() {
        loadFeedback()
    }

    // MARK: - Feedback Management

    /// Check if feedback exists for an answer
    func getFeedback(forAnswer answerId: UUID) -> ContentFeedback? {
        feedback.first { $0.answerId == answerId }
    }

    /// Check if an answer has been marked as helpful
    func isHelpful(answerId: UUID) -> Bool? {
        getFeedback(forAnswer: answerId)?.isHelpful
    }

    /// Submit helpful feedback
    func markAsHelpful(answerId: UUID, questionText: String?) {
        submitFeedback(answerId: answerId, isHelpful: true, questionText: questionText)
    }

    /// Submit not helpful feedback
    func markAsNotHelpful(answerId: UUID, questionText: String?) {
        submitFeedback(answerId: answerId, isHelpful: false, questionText: questionText)
    }

    /// Submit or update feedback
    private func submitFeedback(answerId: UUID, isHelpful: Bool, questionText: String?) {
        // Remove existing feedback for this answer
        feedback.removeAll { $0.answerId == answerId }

        // Create new feedback
        let newFeedback = ContentFeedback(
            answerId: answerId,
            isHelpful: isHelpful,
            questionText: questionText
        )

        feedback.append(newFeedback)
        saveFeedback()

        print("✅ Feedback submitted: \(isHelpful ? "helpful" : "not helpful") for answer \(answerId)")
    }

    /// Remove feedback for an answer
    func removeFeedback(answerId: UUID) {
        guard let index = feedback.firstIndex(where: { $0.answerId == answerId }) else {
            return
        }

        feedback.remove(at: index)
        saveFeedback()
        print("🗑️ Feedback removed for answer \(answerId)")
    }

    /// Clear all feedback
    func clearAllFeedback() {
        feedback.removeAll()
        saveFeedback()
        print("🗑️ All feedback cleared")
    }

    // MARK: - Statistics

    /// Get overall feedback statistics
    func getStatistics() -> FeedbackStatistics {
        let helpfulCount = feedback.filter { $0.isHelpful }.count
        let notHelpfulCount = feedback.filter { !$0.isHelpful }.count

        return FeedbackStatistics(
            totalFeedback: feedback.count,
            helpfulCount: helpfulCount,
            notHelpfulCount: notHelpfulCount
        )
    }

    /// Get helpful answers
    func getHelpfulAnswers() -> [ContentFeedback] {
        feedback.filter { $0.isHelpful }
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// Get not helpful answers
    func getNotHelpfulAnswers() -> [ContentFeedback] {
        feedback.filter { !$0.isHelpful }
            .sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Persistence

    private func saveFeedback() {
        do {
            let data = try JSONEncoder().encode(feedback)
            userDefaults.set(data, forKey: feedbackKey)
            print("💾 Feedback saved: \(feedback.count) items")
        } catch {
            print("❌ Failed to save feedback: \(error)")
        }
    }

    private func loadFeedback() {
        guard let data = userDefaults.data(forKey: feedbackKey) else {
            print("ℹ️ No saved feedback found")
            return
        }

        do {
            feedback = try JSONDecoder().decode([ContentFeedback].self, from: data)
            print("✅ Feedback loaded: \(feedback.count) items")
        } catch {
            print("❌ Failed to load feedback: \(error)")
            feedback = []
        }
    }
}
