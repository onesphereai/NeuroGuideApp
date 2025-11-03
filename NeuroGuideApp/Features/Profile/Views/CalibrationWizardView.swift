//
//  CalibrationWizardView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 3 - Child Profile & Personalization (Baseline Calibration Wizard)
//

import SwiftUI
import AVFoundation

struct CalibrationWizardView: View {
    @StateObject private var viewModel = BaselineCalibrationViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: ((BaselineCalibration) -> Void)?
    var onSkip: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                // Content based on state
                Group {
                    switch viewModel.calibrationState {
                    case .intro:
                        introView
                    case .instructions:
                        instructionsView
                    case .recording:
                        recordingView
                    case .review:
                        reviewView
                    case .completed:
                        completedView
                    case .skipped:
                        EmptyView()
                    case .error:
                        errorView
                    }
                }
            }
            .navigationTitle("Baseline Calibration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.calibrationState == .intro {
                        Button("Skip") {
                            viewModel.skipCalibration()
                            onSkip?()
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.calibrationState == .recording {
                        Button("Cancel") {
                            viewModel.cancelRecording()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .task {
            viewModel.setup()
            await viewModel.loadProfile()
        }
    }

    // MARK: - Intro View

    private var introView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Title
            Text("Personalize Arousal Detection")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            // Description
            VStack(alignment: .leading, spacing: 16) {
                CalibrationFeatureRow(
                    icon: "person.fill",
                    title: "Individual Baselines",
                    description: "Every child has different typical arousal patterns"
                )

                CalibrationFeatureRow(
                    icon: "chart.bar.fill",
                    title: "More Accurate",
                    description: "Personalized thresholds reduce false alarms"
                )

                CalibrationFeatureRow(
                    icon: "clock.fill",
                    title: "5 Minutes",
                    description: "Quick one-time setup, recalibrate every 30 days"
                )
            }
            .padding(.horizontal)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.startInstructions()
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    viewModel.skipCalibration()
                    onSkip?()
                    dismiss()
                }) {
                    Text("Skip for Now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Instructions View

    private var instructionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Find a Calm Moment")
                        .font(.title2.bold())

                    Text("We'll record \(viewModel.childName)'s typical behavior when they're regulated and content.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Instructions:")
                        .font(.headline)

                    InstructionRow(
                        number: 1,
                        title: "Choose the Right Time",
                        description: "Pick a moment when \(viewModel.childName) is in their \"green zone\" - calm, content, and regulated. Not excited, not withdrawn."
                    )

                    InstructionRow(
                        number: 2,
                        title: "Good Times to Record",
                        description: "• After a meal\n• During preferred quiet activity\n• Morning routine (if usually calm)\n• Resting but awake"
                    )

                    InstructionRow(
                        number: 3,
                        title: "What We'll Measure",
                        description: "• Typical movement patterns\n• Usual voice pitch and volume\n• Baseline facial expressions\n• Common self-regulatory behaviors"
                    )

                    InstructionRow(
                        number: 4,
                        title: "During Recording",
                        description: "Let \(viewModel.childName) do their thing naturally. No need to direct or engage - just observe. Recording lasts 45 seconds."
                    )
                }

                // Important note
                NGCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Important")
                                .font(.headline)
                            Text("Choose a moment that represents their typical calm state, not an exceptional one. This helps the app understand their normal baseline.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.startRecording()
                        }
                    }) {
                        Text("Start Recording")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        viewModel.skipCalibration()
                        onSkip?()
                        dismiss()
                    }) {
                        Text("Skip Calibration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Recording View

    private var recordingView: some View {
        VStack(spacing: 24) {
            // Camera preview
            if let session = viewModel.getCameraSession() {
                GeometryReader { geometry in
                    CameraPreviewView(session: session)
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.5)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 3)
                        )
                }
                .frame(maxHeight: 400)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .cornerRadius(16)
                    .overlay(
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Starting camera...")
                                .foregroundColor(.secondary)
                        }
                    )
            }

            // Progress
            VStack(spacing: 12) {
                ProgressView(value: viewModel.recordingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)

                Text("\(viewModel.progressPercentage) Complete")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)

            // Real-time metrics
            VStack(spacing: 12) {
                MetricRow(
                    icon: "figure.walk",
                    label: "Movement",
                    value: viewModel.formattedMovementEnergy
                )

                MetricRow(
                    icon: "waveform",
                    label: "Voice Pitch",
                    value: viewModel.formattedPitch
                )

                MetricRow(
                    icon: "speaker.wave.2.fill",
                    label: "Volume",
                    value: viewModel.formattedVolume
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            // Detected movements
            if !viewModel.detectedMovements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Observed Behaviors:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    ForEach(viewModel.detectedMovements, id: \.self) { behavior in
                        Text("• \(behavior)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
    }

    // MARK: - Review View

    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Success header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Baseline Recorded!")
                        .font(.title2.bold())

                    Text("Review the detected baseline below")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()

                if let baseline = viewModel.completedCalibration {
                    // Movement baseline
                    NGCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "figure.walk.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Movement Baseline")
                                    .font(.headline)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                CalibrationInfoRow(label: "Average Energy", value: String(format: "%.1f%%", baseline.movementBaseline.averageMovementEnergy * 100))
                                CalibrationInfoRow(label: "Typical Posture", value: baseline.movementBaseline.typicalPosture ?? "Unknown")

                                if !baseline.movementBaseline.commonStimBehaviors.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Observed Behaviors:")
                                            .font(.caption.bold())
                                        ForEach(baseline.movementBaseline.commonStimBehaviors, id: \.self) { behavior in
                                            Text("• \(behavior)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Vocal baseline
                    NGCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "waveform.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Vocal Baseline")
                                    .font(.headline)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                CalibrationInfoRow(label: "Average Pitch", value: String(format: "%.0f Hz", baseline.vocalBaseline.averagePitch))
                                CalibrationInfoRow(label: "Average Volume", value: String(format: "%.0f dB", baseline.vocalBaseline.averageVolume))
                                CalibrationInfoRow(label: "Cadence", value: baseline.vocalBaseline.typicalCadence ?? "Unknown")
                            }
                        }
                    }

                    // Expression baseline (if available)
                    if let expression = baseline.expressionBaseline {
                        NGCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "face.smiling.fill")
                                        .foregroundColor(.orange)
                                    Text("Expression Baseline")
                                        .font(.headline)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    CalibrationInfoRow(label: "Neutral Expression", value: expression.neutralExpression ?? "Unknown")
                                    CalibrationInfoRow(label: "Flat Affect Normal", value: expression.flatAffectNormal ? "Yes" : "No")
                                }
                            }
                        }
                    }

                    // Optional notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Notes (Optional)")
                            .font(.headline)

                        Text("What was \(viewModel.childName) doing during this recording?")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("e.g., Playing quietly with blocks, resting after lunch", text: $viewModel.parentNotes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...5)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }

                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.confirmAndSave()
                        }
                    }) {
                        Text("Save Baseline")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        viewModel.retryCalibration()
                    }) {
                        Text("Record Again")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Baseline Saved!")
                .font(.title.bold())

            Text("Arousal detection is now personalized for \(viewModel.childName)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button(action: {
                if let baseline = viewModel.completedCalibration {
                    onComplete?(baseline)
                }
                dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Calibration Failed")
                .font(.title2.bold())

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    viewModel.retryCalibration()
                }) {
                    Text("Try Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    onSkip?()
                    dismiss()
                }) {
                    Text("Skip for Now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Supporting Views

private struct CalibrationFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct InstructionRow: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct MetricRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.blue)
        }
    }
}

private struct CalibrationInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    CalibrationWizardView()
}
