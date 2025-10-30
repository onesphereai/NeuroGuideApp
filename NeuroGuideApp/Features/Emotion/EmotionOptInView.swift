//
//  EmotionOptInView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import SwiftUI

/// Opt-in flow for emotion interface
/// Clear consent with model card and demo option
struct EmotionOptInView: View {
    @StateObject private var emotionInterface = EmotionInterfaceManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showModelCard = false
    @State private var showDemo = false
    @State private var isEnabling = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // What it does
                    whatItDoesSection

                    // What it doesn't do
                    whatItDoesntSection

                    // Neurodiversity considerations
                    neurodiversitySection

                    // Privacy section
                    privacySection

                    // Actions
                    actionsSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Emotion Interface")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe Later") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showModelCard) {
                ModelCardView(modelCard: emotionInterface.getModelCard())
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "face.smiling.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Understand Your Child's Emotions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Optional facial expression analysis can help provide better support during challenging moments.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - What It Does

    private var whatItDoesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("What Emotion Detection Does", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(
                    icon: "eye.fill",
                    title: "Analyzes facial expressions",
                    description: "Detects 6 emotion states: Joy, Calm, Frustration, Overwhelm, Focused, Dysregulated"
                )

                featureRow(
                    icon: "lightbulb.fill",
                    title: "Provides context for coaching",
                    description: "Helps suggest strategies based on your child's current emotional state"
                )

                featureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Learns your child's patterns",
                    description: "Improves over time as you validate predictions"
                )

                featureRow(
                    icon: "hand.raised.fill",
                    title: "Shows confidence levels",
                    description: "Always tells you when it's uncertain - encourages trusting your instincts"
                )
            }
        }
    }

    // MARK: - What It Doesn't Do

    private var whatItDoesntSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("What It Doesn't Do", systemImage: "xmark.circle.fill")
                .font(.headline)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 12) {
                limitationRow(
                    icon: "stethoscope",
                    text: "Not a diagnostic tool - for supportive guidance only"
                )

                limitationRow(
                    icon: "exclamationmark.triangle",
                    text: "Not 100% accurate - accuracy varies (see model card)"
                )

                limitationRow(
                    icon: "brain",
                    text: "Can't read minds - makes educated guesses based on visible expressions"
                )

                limitationRow(
                    icon: "person.fill.questionmark",
                    text: "Can't replace your judgment - you know your child best"
                )
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Neurodiversity

    private var neurodiversitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Neurodiversity-Affirming", systemImage: "heart.fill")
                .font(.headline)
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 12) {
                Text("This model respects neurodivergent communication:")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    afirmingRow(icon: "checkmark", text: "Flat affect doesn't mean sad or distressed")
                    afirmingRow(icon: "checkmark", text: "Stimming is respected as valid emotional expression")
                    afirmingRow(icon: "checkmark", text: "Trained on neurodivergent children's expressions")
                    afirmingRow(icon: "checkmark", text: "Adapts to your child's unique patterns")
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Privacy First", systemImage: "lock.fill")
                .font(.headline)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 8) {
                privacyRow(icon: "iphone", text: "100% on-device processing")
                privacyRow(icon: "xmark.shield", text: "No video/images uploaded to cloud")
                privacyRow(icon: "arrow.up.trash", text: "No raw images stored")
                privacyRow(icon: "hand.raised", text: "Can disable anytime")
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 16) {
            // View Model Card
            Button(action: {
                showModelCard = true
                Task {
                    await emotionInterface.markModelCardViewed()
                }
            }) {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("View Model Card")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Watch Demo (placeholder)
            Button(action: {
                showDemo = true
                Task {
                    await emotionInterface.showDemoVideo()
                }
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Watch Demo Video")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.vertical, 8)

            // Enable Button
            Button(action: {
                Task {
                    isEnabling = true
                    do {
                        try await emotionInterface.enable()
                        dismiss()
                    } catch {
                        print("❌ Failed to enable emotion interface: \(error)")
                    }
                    isEnabling = false
                }
            }) {
                HStack {
                    if isEnabling {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(isEnabling ? "Enabling..." : "Enable Emotion Detection")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isEnabling)

            // Decline Button
            Button(action: {
                dismiss()
            }) {
                Text("Maybe Later")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helper Views

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func limitationRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.caption)
                .frame(width: 20)

            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private func afirmingRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .font(.caption)
                .frame(width: 20)

            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private func privacyRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
                .frame(width: 20)

            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    EmotionOptInView()
}
