//
//  FeatureVisualizationPanel.swift
//  NeuroGuide
//
//  Real-time display of ML model features for transparency
//

import SwiftUI

/// Displays what the ML model is detecting in real-time
struct FeatureVisualizationPanel: View {
    let features: FeatureVisualization
    @State private var isExpanded: Bool = false  // Start collapsed for cleaner UI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - use onTapGesture for better tap response
            HStack {
                Image(systemName: features.usingCustomModel ? "sparkles" : "chart.bar.fill")
                    .foregroundColor(features.usingCustomModel ? .purple : .blue)

                Text("Real Time Detections")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if features.usingCustomModel {
                    Text("(Personalized)")
                        .font(.caption)
                        .foregroundColor(.purple)
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())  // Make entire area tappable
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Result
                    resultSection

                    Divider()

                    // Modalities
                    if features.poseAvailable {
                        poseSection
                    }

                    if features.facialAvailable {
                        facialSection
                    }

                    if features.vocalAvailable {
                        vocalSection
                    }

                    // Show message if no modalities available
                    if !features.poseAvailable && !features.facialAvailable && !features.vocalAvailable {
                        Text("No signals detected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Detected Band")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Circle()
                    .fill(features.predictedBand.swiftUIColor)
                    .frame(width: 12, height: 12)

                Text(features.predictedBand.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Text("\(Int(features.overallConfidence * 100))% confident")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var poseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.arms.open")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("Body & Movement")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                if let confidence = features.poseConfidence {
                    confidenceBadge(confidence)
                }
            }

            VStack(spacing: 4) {
                if let movement = features.movementIntensity {
                    featureBar(label: "Movement", value: movement, color: .blue)
                }
                if let tension = features.bodyTension {
                    featureBar(label: "Tension", value: tension, color: .orange)
                }
                if let openness = features.postureOpenness {
                    featureBar(label: "Openness", value: openness, color: .green)
                }
            }
        }
    }

    private var facialSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundColor(.purple)
                    .font(.caption)
                Text("Facial Expression")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                if let confidence = features.facialConfidence {
                    confidenceBadge(confidence)
                }
            }

            VStack(spacing: 4) {
                if let intensity = features.expressionIntensity {
                    featureBar(label: "Intensity", value: intensity, color: .purple)
                }
                if let mouth = features.mouthOpenness {
                    featureBar(label: "Mouth", value: mouth, color: .pink)
                }
                if let eyes = features.eyeWideness {
                    featureBar(label: "Eyes", value: eyes, color: .cyan)
                }
                if let brow = features.browRaised {
                    HStack {
                        Text("Brows")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        Text(brow ? "Raised" : "Normal")
                            .font(.caption2)
                            .foregroundColor(brow ? .orange : .green)
                    }
                }
            }
        }
    }

    private var vocalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.red)
                    .font(.caption)
                Text("Voice & Audio")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            VStack(spacing: 4) {
                if let volume = features.volume {
                    featureBar(label: "Volume", value: volume, color: .red)
                }
                if let energy = features.energy {
                    featureBar(label: "Energy", value: energy, color: .orange)
                }
                if let rate = features.speechRate {
                    featureBar(label: "Speech Rate", value: rate, color: .yellow)
                }
                if let pitch = features.pitch {
                    HStack {
                        Text("Pitch")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        Text("\(Int(pitch)) Hz")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    private func confidenceBadge(_ confidence: Double) -> some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(confidenceColor(confidence).opacity(0.2))
            )
            .foregroundColor(confidenceColor(confidence))
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence > 0.8 {
            return .green
        } else if confidence > 0.6 {
            return .orange
        } else {
            return .red
        }
    }

    private func featureBar(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * value)
                }
            }
            .frame(height: 6)

            Text("\(Int(value * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FeatureVisualizationPanel(features: FeatureVisualization(
            poseAvailable: true,
            movementIntensity: 0.75,
            bodyTension: 0.6,
            postureOpenness: 0.4,
            poseConfidence: 0.85,
            facialAvailable: true,
            expressionIntensity: 0.8,
            mouthOpenness: 0.5,
            eyeWideness: 0.7,
            browRaised: true,
            facialConfidence: 0.9,
            vocalAvailable: true,
            volume: 0.65,
            pitch: 220,
            energy: 0.7,
            speechRate: 0.8,
            predictedBand: .yellow,
            overallConfidence: 0.85,
            usingCustomModel: true
        ))

        FeatureVisualizationPanel(features: FeatureVisualization(
            poseAvailable: true,
            movementIntensity: 0.3,
            bodyTension: 0.2,
            postureOpenness: 0.8,
            poseConfidence: 0.75,
            facialAvailable: false,
            expressionIntensity: nil,
            mouthOpenness: nil,
            eyeWideness: nil,
            browRaised: nil,
            facialConfidence: nil,
            vocalAvailable: false,
            volume: nil,
            pitch: nil,
            energy: nil,
            speechRate: nil,
            predictedBand: .green,
            overallConfidence: 0.72,
            usingCustomModel: false
        ))
    }
    .padding()
}
