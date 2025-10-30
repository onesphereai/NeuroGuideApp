//
//  CalibrationStepView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.4)
//

import SwiftUI

/// Fifth step: Baseline calibration (optional)
/// Full implementation for Bolt 3.4
struct CalibrationStepView: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions header
                instructionsHeader

                // How it works card
                howItWorksCard

                // Skip calibration toggle
                skipCalibrationSection

                // Coming soon note
                comingSoonNote

                // Privacy note
                privacyNote

                Spacer(minLength: 20)
            }
            .padding()
        }
    }

    // MARK: - Instructions Header

    private var instructionsHeader: some View {
        VStack(spacing: 8) {
            Text("Baseline calibration is optional. It helps us detect early signs of dysregulation by understanding your child's typical patterns when calm.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - How It Works Card

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)

                Text("How It Works")
                    .font(.headline)
            }

            Text("When your child is calm and regulated, we'll observe their typical patterns:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                bulletPoint(icon: "figure.walk", text: "Movement level", description: "How active they are when calm")
                bulletPoint(icon: "waveform", text: "Vocal patterns", description: "Typical sounds and volume")
                bulletPoint(icon: "face.smiling", text: "Facial expressions", description: "Usual expressions when regulated")
            }

            Divider()
                .padding(.vertical, 4)

            Text("This creates a personalized baseline. Later, we can detect subtle changes that may signal dysregulation before it escalates.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Skip Calibration Section

    private var skipCalibrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.skipCalibration) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Skip baseline calibration")
                        .font(.body)
                        .fontWeight(.medium)

                    Text("You can do this later in your profile settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .accessibilityLabel("Skip baseline calibration")
            .accessibilityHint(viewModel.skipCalibration ? "Calibration will be skipped" : "Calibration will be included")

            if viewModel.skipCalibration {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("You can calibrate anytime from your profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    // MARK: - Coming Soon Note

    private var comingSoonNote: some View {
        InfoCard(
            icon: "sparkles",
            title: "Coming Soon",
            message: "Full calibration with sensor integration will be available in a future update. For now, you can complete your profile and we'll notify you when this feature is ready."
        )
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
        InfoCard(
            icon: "lock.fill",
            title: "Privacy First",
            message: "Baseline data is stored encrypted on your device. No data is sent to external servers. You can delete your baseline anytime."
        )
    }

    // MARK: - Helper Views

    private func bulletPoint(icon: String, text: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

struct CalibrationStepView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Not skipped
            CalibrationStepView(viewModel: {
                let vm = ProfileCreationViewModel()
                vm.skipCalibration = false
                return vm
            }())
                .previewDisplayName("Not Skipped")

            // Skipped
            CalibrationStepView(viewModel: {
                let vm = ProfileCreationViewModel()
                vm.skipCalibration = true
                return vm
            }())
                .previewDisplayName("Skipped")

            // Dark mode
            CalibrationStepView(viewModel: ProfileCreationViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
