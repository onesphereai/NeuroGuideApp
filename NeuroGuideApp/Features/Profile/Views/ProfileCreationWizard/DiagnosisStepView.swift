//
//  DiagnosisStepView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-11-01.
//  Unit 3 - Child Profile & Personalization (Diagnosis Support)
//

import SwiftUI

/// Diagnosis selection step of profile creation
struct DiagnosisStepView: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Info card at the top
                InfoCard(
                    icon: "heart.text.square.fill",
                    title: "Personalized Support",
                    message: "Sharing a diagnosis helps us personalize arousal detection and recommendations. This is completely optional and kept private on your device."
                )
                .padding(.top)

                // Primary diagnosis selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Primary Diagnosis")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    VStack(spacing: 12) {
                        ForEach(NeurodivergentDiagnosis.allCases) { diagnosis in
                            DiagnosisSelectionCard(
                                diagnosis: diagnosis,
                                isSelected: viewModel.selectedDiagnosis == diagnosis,
                                action: {
                                    withAnimation {
                                        viewModel.selectedDiagnosis = diagnosis
                                    }
                                }
                            )
                        }
                    }
                }

                // Additional diagnoses section (only show if not "prefer not to specify")
                if viewModel.selectedDiagnosis != .preferNotToSpecify {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Additional Diagnoses")
                                .font(.headline)
                            Text("(Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)

                        Text("Select any additional diagnoses if applicable")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            ForEach(availableAdditionalDiagnoses) { diagnosis in
                                AdditionalDiagnosisToggle(
                                    diagnosis: diagnosis,
                                    isSelected: viewModel.isAdditionalDiagnosisSelected(diagnosis),
                                    action: {
                                        withAnimation {
                                            viewModel.toggleAdditionalDiagnosis(diagnosis)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }

                // Professionally diagnosed toggle
                if viewModel.selectedDiagnosis != .preferNotToSpecify {
                    Toggle(isOn: $viewModel.professionallyDiagnosed) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Professionally diagnosed")
                                .font(.subheadline)
                            Text("By a licensed healthcare professional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }

                // Notes field
                if viewModel.selectedDiagnosis != .preferNotToSpecify {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Additional Notes")
                                .font(.headline)
                            Text("(Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)

                        TextEditor(text: $viewModel.diagnosisNotes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .accessibilityLabel("Additional notes about diagnosis")
                    }
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
    }

    /// Get available additional diagnoses (excluding primary and skip option)
    private var availableAdditionalDiagnoses: [NeurodivergentDiagnosis] {
        NeurodivergentDiagnosis.allCases.filter { diagnosis in
            diagnosis != viewModel.selectedDiagnosis &&
            diagnosis != .preferNotToSpecify
        }
    }
}

// MARK: - Diagnosis Selection Card

struct DiagnosisSelectionCard: View {
    let diagnosis: NeurodivergentDiagnosis
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Text(diagnosis.icon)
                    .font(.title2)
                    .accessibilityHidden(true)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(diagnosis.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(diagnosis.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .accessibilityLabel(isSelected ? "Selected" : "Not selected")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to select this diagnosis")
    }
}

// MARK: - Additional Diagnosis Toggle

struct AdditionalDiagnosisToggle: View {
    let diagnosis: NeurodivergentDiagnosis
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .accessibilityLabel(isSelected ? "Selected" : "Not selected")

                Text(diagnosis.icon)
                    .font(.body)
                    .accessibilityHidden(true)

                Text(diagnosis.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to toggle this additional diagnosis")
    }
}

// MARK: - Preview

struct DiagnosisStepView_Previews: PreviewProvider {
    static var previews: some View {
        DiagnosisStepView(viewModel: ProfileCreationViewModel())
    }
}
