//
//  CommunicationStepView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.2)
//

import SwiftUI

/// Third step: Communication mode selection
/// Full implementation for Bolt 3.2
struct CommunicationStepView: View {
    @ObservedObject var     viewModel: ProfileCreationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions header
                VStack(spacing: 8) {
                    Text("Understanding how your child communicates helps us provide guidance that respects their communication style.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Info card
                InfoCard(
                    icon: "lightbulb.fill",
                    title: "All Communication is Valid",
                    message: "Every child communicates in their own way. There's no 'better' or 'worse' method—we respect all forms of communication."
                )

                // Communication mode selection
                VStack(spacing: 12) {
                    ForEach(CommunicationMode.allCases, id: \.self) { mode in
                        CommunicationModeRow(
                            mode: mode,
                            isSelected: viewModel.communicationMode == mode,
                            onTap: { viewModel.communicationMode = mode }
                        )
                    }
                }

                // Communication notes section
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Additional Notes")
                                .font(.headline)
                            Text("(Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("Tell us more about your child's communication strengths or challenges")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    TextEditor(text: $viewModel.communicationNotes)
                        .frame(height: 100)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .accessibilityLabel("Communication notes")
                        .accessibilityHint("Optional. Enter any additional information about your child's communication, like 'uses scripting from favorite shows' or 'prefers visual supports'")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )

                // Alexithymia section
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Emotion Recognition")
                            .font(.headline)

                        Text("Understanding how your child recognizes and names emotions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Alexithymia toggle
                    Toggle(isOn: $viewModel.alexithymiaSettings.hasDifficultyNamingFeelings) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Difficulty naming feelings")
                                .font(.body)

                            Text("If checked, we'll focus on body cues (e.g., 'tight chest,' 'fast heartbeat') rather than emotion labels")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .accessibilityLabel("Difficulty naming feelings")
                    .accessibilityHint("Toggle on if your child has difficulty recognizing or naming their own emotions")

                    // Info about alexithymia
                    InfoCard(
                        icon: "heart.text.square.fill",
                        title: "Body-First Approach",
                        message: "Some autistic individuals experience alexithymia—difficulty identifying their own emotions. We can help by focusing on physical sensations instead of emotion words."
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )

                // Privacy note
                InfoCard(
                    icon: "lock.fill",
                    title: "Privacy First",
                    message: "This information is stored securely on your device and used only to personalize guidance for your child."
                )

                Spacer(minLength: 20)
            }
            .padding()
        }
    }
}

// MARK: - Preview

struct CommunicationStepView_Previews: PreviewProvider {
    static var previews: some View {
        CommunicationStepView(viewModel: ProfileCreationViewModel())
    }
}
