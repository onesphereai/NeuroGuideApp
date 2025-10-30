//
//  EmotionValidationView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import SwiftUI

/// View for parent to validate emotion predictions
/// Helps improve model accuracy through feedback
struct EmotionValidationView: View {
    let prompt: ValidationPrompt
    let onValidation: (EmotionLabel) -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedEmotion: EmotionLabel?
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Current prediction
                    currentPredictionSection

                    // Validation question
                    validationQuestionSection

                    // Emotion selection
                    emotionSelectionGrid

                    // Action buttons
                    actionButtons

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Validate Emotion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onSkip()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.fill.checkmark")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            VStack(spacing: 6) {
                Text("Help Improve Accuracy")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Your feedback helps the model learn your child's unique expressions.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Current Prediction

    private var currentPredictionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The model detected:")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Image(systemName: prompt.classification.primary.icon)
                    .font(.system(size: 32))
                    .foregroundColor(prompt.classification.primary.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.classification.primary.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(confidenceColor)
                            .frame(width: 8, height: 8)

                        Text("\(Int(prompt.classification.confidence.probability * 100))% confident")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(prompt.classification.primary.color.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var confidenceColor: Color {
        switch prompt.classification.confidence.level {
        case .low:
            return .orange
        case .medium:
            return .blue
        case .high:
            return .green
        }
    }

    // MARK: - Validation Question

    private var validationQuestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Was this correct?")
                .font(.headline)

            Text("Select the emotion that best matches what you observed.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Emotion Selection Grid

    private var emotionSelectionGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(EmotionLabel.allCases, id: \.self) { emotion in
                emotionButton(emotion: emotion)
            }
        }
    }

    private func emotionButton(emotion: EmotionLabel) -> some View {
        let isSelected = selectedEmotion == emotion
        let isPredicted = emotion == prompt.classification.primary

        return Button(action: {
            selectedEmotion = emotion
        }) {
            VStack(spacing: 8) {
                Image(systemName: emotion.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : emotion.color)

                Text(emotion.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)

                if isPredicted {
                    Text("(Predicted)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected
                    ? emotion.color
                    : emotion.color.opacity(0.1)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? emotion.color : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Submit validation
            Button(action: {
                if let selected = selectedEmotion {
                    onValidation(selected)
                    showConfirmation = true

                    // Dismiss after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        dismiss()
                    }
                }
            }) {
                HStack {
                    if showConfirmation {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(showConfirmation ? "Thank you!" : "Submit")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedEmotion != nil ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(selectedEmotion == nil || showConfirmation)

            // Skip button
            Button(action: {
                onSkip()
                dismiss()
            }) {
                Text("I'm not sure right now")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EmotionValidationView(
        prompt: ValidationPrompt(
            id: UUID(),
            childID: UUID(),
            classification: EmotionClassification(
                primary: .joy,
                secondary: nil,
                confidence: ConfidenceScore(
                    level: .medium,
                    probability: 0.65,
                    signalQuality: 0.7,
                    temporalStability: 0.6
                ),
                timestamp: Date(),
                features: nil
            ),
            timestamp: Date()
        ),
        onValidation: { emotion in
            print("Validated as: \(emotion)")
        },
        onSkip: {
            print("Skipped validation")
        }
    )
}
