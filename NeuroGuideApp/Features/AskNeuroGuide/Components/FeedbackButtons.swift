//
//  FeedbackButtons.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import SwiftUI

/// Feedback buttons for rating answer helpfulness
struct FeedbackButtons: View {
    let answer: ContentAnswer
    let questionText: String?
    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var showFeedbackConfirmation = false

    var body: some View {
        HStack(spacing: 16) {
            Text("Was this helpful?")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // Thumbs up button
                Button(action: {
                    feedbackManager.markAsHelpful(answerId: answer.id, questionText: questionText)
                    showFeedbackConfirmation = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isHelpful == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.subheadline)

                        if let stats = getAnswerStats(), stats.helpfulCount > 0 {
                            Text("\(stats.helpfulCount)")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(isHelpful == true ? .green : .gray)
                }

                // Thumbs down button
                Button(action: {
                    feedbackManager.markAsNotHelpful(answerId: answer.id, questionText: questionText)
                    showFeedbackConfirmation = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isHelpful == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.subheadline)

                        if let stats = getAnswerStats(), stats.notHelpfulCount > 0 {
                            Text("\(stats.notHelpfulCount)")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(isHelpful == false ? .red : .gray)
                }
            }
        }
        .padding(.vertical, 8)
        .onChange(of: showFeedbackConfirmation) { newValue in
            if newValue {
                // Auto-dismiss after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showFeedbackConfirmation = false
                }
            }
        }
        .overlay(
            Group {
                if showFeedbackConfirmation {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Text("Thanks for your feedback!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        )
    }

    // MARK: - Computed Properties

    private var isHelpful: Bool? {
        feedbackManager.isHelpful(answerId: answer.id)
    }

    private func getAnswerStats() -> FeedbackStatistics? {
        // For now, just return global stats
        // In future, could track per-answer stats
        let stats = feedbackManager.getStatistics()
        return stats.totalFeedback > 0 ? stats : nil
    }
}

// MARK: - Compact Feedback Button

/// Compact version showing just icons
struct CompactFeedbackButtons: View {
    let answer: ContentAnswer
    let questionText: String?
    @StateObject private var feedbackManager = FeedbackManager.shared

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                feedbackManager.markAsHelpful(answerId: answer.id, questionText: questionText)
            }) {
                Image(systemName: isHelpful == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.caption)
                    .foregroundColor(isHelpful == true ? .green : .gray)
            }

            Button(action: {
                feedbackManager.markAsNotHelpful(answerId: answer.id, questionText: questionText)
            }) {
                Image(systemName: isHelpful == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.caption)
                    .foregroundColor(isHelpful == false ? .red : .gray)
            }
        }
    }

    private var isHelpful: Bool? {
        feedbackManager.isHelpful(answerId: answer.id)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        FeedbackButtons(
            answer: ContentAnswer(
                content: "Sample answer content",
                source: ContentSource(
                    title: "Sample Article",
                    section: nil,
                    author: nil,
                    credibilityLevel: .communityValidated
                ),
                relevanceScore: 0.8,
                strategies: nil
            ),
            questionText: "Sample question?"
        )

        CompactFeedbackButtons(
            answer: ContentAnswer(
                content: "Sample answer content",
                source: ContentSource(
                    title: "Sample Article",
                    section: nil,
                    author: nil,
                    credibilityLevel: .communityValidated
                ),
                relevanceScore: 0.8,
                strategies: nil
            ),
            questionText: "Sample question?"
        )
    }
    .padding()
}
