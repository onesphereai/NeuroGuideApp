//
//  SensoryPreferencesStepView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.2)
//

import SwiftUI

/// Second step: Sensory preferences questionnaire
/// Full implementation for Bolt 3.2
struct SensoryPreferencesStepView: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions header
                VStack(spacing: 8) {
                    Text("Understanding your child's sensory preferences helps us recommend strategies that respect their needs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Info card
                InfoCard(
                    icon: "lightbulb.fill",
                    title: "What This Means",
                    message: "Seeking means actively wanting that input. Avoiding means sensitive or prefers less. Neutral means no strong preference."
                )

                // Sensory profiles for each sense
                VStack(spacing: 16) {
                    ForEach(SenseType.allCases, id: \.self) { sense in
                        SensoryProfileRow(
                            sense: sense,
                            profile: binding(for: sense)
                        )
                    }
                }

                // Specific triggers section
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Specific Triggers")
                                .font(.headline)
                            Text("(Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("List any specific sensory triggers we should know about")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    TextEditor(text: $viewModel.specificSensoryTriggers)
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
                        .accessibilityLabel("Specific sensory triggers")
                        .accessibilityHint("Optional. Enter any specific sensory triggers, like 'sudden loud noises' or 'scratchy fabrics'")
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

    // MARK: - Helper Methods

    /// Create a binding for a specific sense
    private func binding(for sense: SenseType) -> Binding<SensoryProfile> {
        Binding(
            get: { viewModel.sensoryPreferences.get(for: sense) },
            set: { newProfile in
                viewModel.sensoryPreferences.set(for: sense, profile: newProfile)
            }
        )
    }
}

// MARK: - Preview

struct SensoryPreferencesStepView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SensoryPreferencesStepView(viewModel: ProfileCreationViewModel())
                .previewDisplayName("Light Mode")

            SensoryPreferencesStepView(viewModel: ProfileCreationViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
