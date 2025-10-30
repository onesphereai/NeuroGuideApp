//
//  ModelCardView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import SwiftUI

/// Displays emotion model card with accuracy metrics and limitations
/// Transparency about model capabilities and limitations
struct ModelCardView: View {
    let modelCard: EmotionModelCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About the Emotion Model")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Transparency is important. Here's what you should know about how emotion detection works.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    // Overall Accuracy
                    accuracySection

                    // Limitations
                    limitationsSection

                    // Neurodiversity Considerations
                    neurodiversitySection

                    // Data Sources
                    dataSourcesSection

                    // Model Info
                    modelInfoSection
                }
                .padding()
            }
            .navigationTitle("Model Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Accuracy Section

    private var accuracySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Accuracy Metrics", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                accuracyRow(label: "Overall", value: modelCard.accuracyMetrics.formattedOverall, isOverall: true)
                Divider()
                accuracyRow(label: "Joy", value: modelCard.accuracyMetrics.joyAccuracy)
                accuracyRow(label: "Calm", value: modelCard.accuracyMetrics.calmAccuracy)
                accuracyRow(label: "Frustration", value: modelCard.accuracyMetrics.frustrationAccuracy)
                accuracyRow(label: "Overwhelm", value: modelCard.accuracyMetrics.overwhelmAccuracy)
                accuracyRow(label: "Focused", value: modelCard.accuracyMetrics.focusedAccuracy)
                accuracyRow(label: "Dysregulated", value: modelCard.accuracyMetrics.dysregulatedAccuracy)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private func accuracyRow(label: String, value: Double, isOverall: Bool = false) -> some View {
        HStack {
            Text(label)
                .fontWeight(isOverall ? .semibold : .regular)
            Spacer()
            Text("\(Int(value * 100))%")
                .fontWeight(isOverall ? .bold : .medium)
                .foregroundColor(colorForAccuracy(value))
        }
    }

    private func accuracyRow(label: String, value: String, isOverall: Bool = false) -> some View {
        HStack {
            Text(label)
                .fontWeight(isOverall ? .semibold : .regular)
            Spacer()
            Text(value)
                .fontWeight(isOverall ? .bold : .medium)
                .foregroundColor(.blue)
        }
    }

    private func colorForAccuracy(_ value: Double) -> Color {
        if value >= 0.80 {
            return .green
        } else if value >= 0.65 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Limitations Section

    private var limitationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Important Limitations", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(modelCard.limitations, id: \.self) { limitation in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(limitation)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Neurodiversity Section

    private var neurodiversitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Neurodiversity-Affirming Design", systemImage: "heart.fill")
                .font(.headline)
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(modelCard.neurodiversityConsiderations, id: \.self) { consideration in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                        Text(consideration)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Data Sources Section

    private var dataSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Training Data", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(modelCard.dataSources, id: \.self) { source in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(source)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Model Info Section

    private var modelInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Technical Details")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                infoRow(label: "Model Name", value: modelCard.modelName)
                infoRow(label: "Version", value: modelCard.modelVersion)
                infoRow(label: "Last Updated", value: formatDate(modelCard.lastUpdated))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ModelCardView(modelCard: EmotionModelCard.current)
}
