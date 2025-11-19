//
//  ModelTrainingView.swift
//  NeuroGuide
//
//  View for training custom ML model
//

import SwiftUI

struct ModelTrainingView: View {
    @StateObject private var viewModel = ModelTrainingViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if viewModel.isTraining {
                    trainingInProgressView
                } else if viewModel.trainingComplete {
                    trainingCompleteView
                } else {
                    trainingReadyView
                }
            }
            .padding()
            .navigationTitle("Train Custom Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isTraining)
                }
            }
            .alert("Training Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Training Ready View

    private var trainingReadyView: some View {
        VStack(spacing: 32) {
            // Icon
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)

            // Title
            VStack(spacing: 12) {
                Text("Ready to Train")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Train a custom ML model using your collected training videos for personalized arousal detection.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Info cards
            VStack(spacing: 16) {
                TrainingInfoRow(
                    icon: "video.fill",
                    title: "Training Videos",
                    value: "\(TrainingDataManager.shared.currentDataset?.totalVideoCount ?? 0)"
                )

                TrainingInfoRow(
                    icon: "clock.fill",
                    title: "Estimated Time",
                    value: "2-3 minutes"
                )

                TrainingInfoRow(
                    icon: "brain.head.profile",
                    title: "Algorithm",
                    value: "k-Nearest Neighbors"
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Spacer()

            // Start button
            Button(action: {
                Task {
                    await viewModel.startTraining()
                }
            }) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Start Training")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canStartTraining)
        }
    }

    // MARK: - Training In Progress View

    private var trainingInProgressView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.trainingProgress)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: viewModel.trainingProgress)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
            }

            // Progress info
            VStack(spacing: 12) {
                Text("\(viewModel.progressPercentage)%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.purple)

                Text(viewModel.currentPhase.displayName)
                    .font(.title3)
                    .fontWeight(.medium)

                Text("Please keep the app open...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            ProgressView(value: viewModel.trainingProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                .frame(maxWidth: 300)

            Spacer()

            // Phase descriptions
            VStack(alignment: .leading, spacing: 8) {
                PhaseRow(
                    phase: .extractingFeatures,
                    isCurrent: viewModel.currentPhase == .extractingFeatures,
                    isComplete: viewModel.trainingProgress > 0.6
                )
                PhaseRow(
                    phase: .preparingData,
                    isCurrent: viewModel.currentPhase == .preparingData,
                    isComplete: viewModel.trainingProgress > 0.7
                )
                PhaseRow(
                    phase: .training,
                    isCurrent: viewModel.currentPhase == .training,
                    isComplete: viewModel.trainingProgress > 0.9
                )
                PhaseRow(
                    phase: .evaluating,
                    isCurrent: viewModel.currentPhase == .evaluating,
                    isComplete: viewModel.trainingProgress > 0.95
                )
                PhaseRow(
                    phase: .exporting,
                    isCurrent: viewModel.currentPhase == .exporting,
                    isComplete: viewModel.trainingProgress >= 1.0
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Training Complete View

    private var trainingCompleteView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            // Title
            VStack(spacing: 12) {
                Text("Training Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your custom model is ready to use in Personalized Mode.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Model stats
            if let model = viewModel.trainedModel {
                VStack(spacing: 16) {
                    StatRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Accuracy",
                        value: String(format: "%.1f%%", (model.accuracy ?? 0) * 100)
                    )

                    StatRow(
                        icon: "video.fill",
                        title: "Training Videos",
                        value: "\(model.trainingVideoCount)"
                    )

                    StatRow(
                        icon: "externaldrive.fill",
                        title: "Model Size",
                        value: ByteCountFormatter.string(fromByteCount: model.modelSize, countStyle: .file)
                    )
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            Spacer()

            // Done button
            Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Done")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Training Info Row

struct TrainingInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 30)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Phase Row

struct PhaseRow: View {
    let phase: TrainingPhase
    let isCurrent: Bool
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if isCurrent {
                ProgressView()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }

            // Phase name
            Text(phase.displayName)
                .font(.subheadline)
                .foregroundColor(isCurrent ? .primary : .secondary)
                .fontWeight(isCurrent ? .semibold : .regular)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ModelTrainingView()
}
