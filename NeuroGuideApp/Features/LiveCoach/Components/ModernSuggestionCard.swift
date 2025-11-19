//
//  ModernSuggestionCard.swift
//  NeuroGuide
//
//  Modern suggestion card with feedback and authentic resource link
//

import SwiftUI

struct ModernSuggestionCard: View {
    let suggestion: CoachingSuggestionWithResource
    let onFeedback: (Bool) -> Void  // true = thumbs up, false = thumbs down

    @State private var feedbackGiven: Bool? = nil
    @State private var showingResource = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Coaching Suggestion")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(suggestion.category.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }

                Spacer()
            }

            // Suggestion text
            Text(suggestion.text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            // Resource link (if available)
            if let resourceTitle = suggestion.resourceTitle,
               let resourceURL = suggestion.resourceURL {
                resourceLinkButton(title: resourceTitle, url: resourceURL)
            }

            // Feedback buttons
            HStack(spacing: 16) {
                Text("Was this helpful?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                feedbackButton(isPositive: true)
                feedbackButton(isPositive: false)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func resourceLinkButton(title: String, url: String) -> some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "book.fill")
                    .font(.system(size: 14, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Read More")
                        .font(.system(size: 12, weight: .semibold))
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func feedbackButton(isPositive: Bool) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                feedbackGiven = isPositive
                onFeedback(isPositive)
            }
        }) {
            ZStack {
                Circle()
                    .fill(feedbackGiven == isPositive ? (isPositive ? Color.green.opacity(0.2) : Color.red.opacity(0.2)) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: isPositive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(
                        feedbackGiven == isPositive ? (isPositive ? .green : .red) : .gray
                    )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(feedbackGiven == isPositive ? 1.1 : 1.0)
    }
}

extension CoachingSuggestionWithResource.SuggestionCategory {
    var displayName: String {
        switch self {
        case .regulation: return "Co-Regulation"
        case .sensory: return "Sensory Support"
        case .parentSupport: return "Parent Care"
        case .environmental: return "Environment"
        case .deescalation: return "De-escalation"
        case .communication: return "Communication"
        case .general: return "General"
        }
    }
}
