//
//  ParentEmotionSummaryView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Unit 5 - Live Coach Record-First Flow
//

import SwiftUI

/// Summary of parent's emotional state and regulation advice
struct ParentEmotionSummaryView: View {
    let advice: ParentRegulationAdvice?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Emotional State")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Understanding your emotions helps you co-regulate with your child")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let advice = advice {
                // Dominant emotion card
                DominantEmotionCard(advice: advice)

                // Regulation strategies
                RegulationStrategiesSection(advice: advice)

                // Specific moments
                if !advice.specificMoments.isEmpty {
                    SpecificMomentsSection(moments: advice.specificMoments)
                }
            } else {
                // No emotion data
                NoEmotionDataCard()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Dominant Emotion Card

struct DominantEmotionCard: View {
    let advice: ParentRegulationAdvice

    var body: some View {
        HStack(spacing: 16) {
            // Emotion icon
            ZStack {
                Circle()
                    .fill(advice.dominantEmotion.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: advice.dominantEmotion.icon)
                    .font(.title2)
                    .foregroundColor(advice.dominantEmotion.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Dominant Emotion")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(advice.dominantEmotion.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("\(Int(advice.emotionPercentage))% of session")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(advice.dominantEmotion.color.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Regulation Strategies Section

struct RegulationStrategiesSection: View {
    let advice: ParentRegulationAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Self-Regulation Strategies")
                .font(.headline)

            ForEach(Array(advice.regulationStrategies.enumerated()), id: \.offset) { index, strategy in
                StrategyCard(strategy: strategy, index: index)
            }
        }
    }
}

struct StrategyCard: View {
    let strategy: String
    let index: Int
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Number badge
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 28, height: 28)

                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                Text(strategy)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Strategy \(index + 1): \(strategy)")
    }
}

// MARK: - Specific Moments Section

struct SpecificMomentsSection: View {
    let moments: [ParentRegulationAdvice.EmotionMoment]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Moments")
                .font(.headline)

            Text("Times when you experienced strong emotions")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(moments) { moment in
                MomentCard(moment: moment)
            }
        }
    }
}

struct MomentCard: View {
    let moment: ParentRegulationAdvice.EmotionMoment

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatTimestamp(moment.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .frame(width: 50)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: moment.emotion.icon)
                        .font(.caption)
                        .foregroundColor(moment.emotion.color)

                    Text(moment.emotion.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text(moment.contextualNote)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .accessibilityElement(children: .combine)
    }

    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - No Emotion Data Card

struct NoEmotionDataCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Parent Emotion Analysis Unavailable")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Unable to detect parent emotions in this session. Make sure your face is visible to the parent camera during recording.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

struct ParentEmotionSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // With stress
                ParentEmotionSummaryView(
                    advice: ParentRegulationAdvice(
                        dominantEmotion: .stressed,
                        emotionPercentage: 65,
                        regulationStrategies: [
                            "Take slow, deep breaths - inhale for 4 counts, hold for 4, exhale for 6.",
                            "Ground yourself: notice 5 things you can see, 4 you can hear, 3 you can touch.",
                            "It's okay to take a brief pause - your child's safety is maintained."
                        ],
                        specificMoments: [
                            ParentRegulationAdvice.EmotionMoment(
                                timestamp: 15.5,
                                emotion: .stressed,
                                contextualNote: "When child was in Orange zone"
                            ),
                            ParentRegulationAdvice.EmotionMoment(
                                timestamp: 32.0,
                                emotion: .anxious,
                                contextualNote: "When child was in Red zone"
                            )
                        ]
                    )
                )

                // Calm state
                ParentEmotionSummaryView(
                    advice: ParentRegulationAdvice(
                        dominantEmotion: .calm,
                        emotionPercentage: 85,
                        regulationStrategies: [
                            "Great job staying regulated! Continue using the strategies that worked for you.",
                            "Your calm presence likely helped your child co-regulate.",
                            "Notice what helped you stay calm to use again in future sessions."
                        ],
                        specificMoments: []
                    )
                )

                // No data
                ParentEmotionSummaryView(advice: nil)
            }
            .padding()
        }
    }
}
