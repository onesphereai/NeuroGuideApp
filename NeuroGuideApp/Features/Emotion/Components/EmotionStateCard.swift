//
//  EmotionStateCard.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import SwiftUI

/// Displays current emotion state with confidence indicator
/// Neurodiversity-affirming language and visual design
struct EmotionStateCard: View {
    let classification: EmotionClassification
    let showSecondary: Bool

    init(classification: EmotionClassification, showSecondary: Bool = true) {
        self.classification = classification
        self.showSecondary = showSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and primary emotion
            HStack(spacing: 12) {
                emotionIcon(for: classification.primary)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(classification.primary.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(classification.primary.displayPhrase)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Confidence indicator
            ConfidenceIndicator(confidence: classification.confidence)

            // Secondary emotion (if present and enabled)
            if showSecondary, let secondary = classification.secondary {
                Divider()

                HStack(spacing: 8) {
                    Text("Also noticing:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    emotionIcon(for: secondary)
                        .font(.system(size: 16))

                    Text(secondary.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            // Timestamp
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(formatTimestamp(classification.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
        .background(backgroundColor(for: classification.primary))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helper Views

    private func emotionIcon(for emotion: EmotionLabel) -> some View {
        Image(systemName: emotion.icon)
            .foregroundColor(emotion.color)
    }

    private func backgroundColor(for emotion: EmotionLabel) -> Color {
        emotion.color.opacity(0.1)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicator: View {
    let confidence: ConfidenceScore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Confidence level label
            HStack(spacing: 8) {
                Circle()
                    .fill(confidenceColor)
                    .frame(width: 8, height: 8)

                Text(confidenceText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(confidenceColor)

                Spacer()

                Text("\(Int(confidence.probability * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Confidence bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * confidence.probability)
                }
            }
            .frame(height: 8)

            // User message
            if confidence.level == .low {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text(confidence.userMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
        }
    }

    private var confidenceColor: Color {
        switch confidence.level {
        case .low:
            return .orange
        case .medium:
            return .blue
        case .high:
            return .green
        }
    }

    private var confidenceText: String {
        switch confidence.level {
        case .low:
            return "Uncertain"
        case .medium:
            return "Moderate confidence"
        case .high:
            return "High confidence"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // High confidence joy
        EmotionStateCard(
            classification: EmotionClassification(
                primary: .joy,
                secondary: nil,
                confidence: ConfidenceScore(
                    level: .high,
                    probability: 0.85,
                    signalQuality: 0.9,
                    temporalStability: 0.8
                ),
                timestamp: Date(),
                features: nil
            )
        )

        // Low confidence overwhelm with secondary
        EmotionStateCard(
            classification: EmotionClassification(
                primary: .overwhelm,
                secondary: .frustration,
                confidence: ConfidenceScore(
                    level: .low,
                    probability: 0.45,
                    signalQuality: 0.6,
                    temporalStability: 0.4
                ),
                timestamp: Date().addingTimeInterval(-120),
                features: nil
            )
        )

        // Medium confidence calm
        EmotionStateCard(
            classification: EmotionClassification(
                primary: .calm,
                secondary: nil,
                confidence: ConfidenceScore(
                    level: .medium,
                    probability: 0.65,
                    signalQuality: 0.7,
                    temporalStability: 0.6
                ),
                timestamp: Date().addingTimeInterval(-30),
                features: nil
            )
        )

        Spacer()
    }
    .padding()
}
