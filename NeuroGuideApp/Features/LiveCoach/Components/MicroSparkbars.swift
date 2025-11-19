//
//  MicroSparkbars.swift
//  NeuroGuide
//
//  Minimal visual indicators showing ML detection activity
//  Design: Tiny bars (8-12px) with no axes, no labels
//

import SwiftUI

/// Micro-sparkbars showing Body, Face, Voice activity levels
struct MicroSparkbars: View {
    let features: FeatureVisualization

    var body: some View {
        HStack(spacing: 6) {
            // Body & Movement
            if features.poseAvailable {
                modalityBar(
                    label: "Body",
                    value: features.movementIntensity ?? 0,
                    color: .blue
                )
            }

            // Facial Expression
            if features.facialAvailable {
                modalityBar(
                    label: "Face",
                    value: features.expressionIntensity ?? 0,
                    color: .purple
                )
            }

            // Voice & Audio
            if features.vocalAvailable {
                modalityBar(
                    label: "Voice",
                    value: features.volume ?? 0,
                    color: .red
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }

    private func modalityBar(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            // Label
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            // Divider
            Text("│")
                .font(.system(size: 10, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.3))

            // Mini bar visualization (5 segments)
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(segmentColor(index: index, value: value, baseColor: color))
                        .frame(width: 2, height: 10)
                        .cornerRadius(1)
                }
            }
        }
    }

    private func segmentColor(index: Int, value: Double, baseColor: Color) -> Color {
        let threshold = Double(index) * 0.2
        if value > threshold {
            return baseColor.opacity(0.9)
        } else {
            return Color.white.opacity(0.15)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // High activity
        MicroSparkbars(features: FeatureVisualization(
            poseAvailable: true,
            movementIntensity: 0.8,
            bodyTension: 0.6,
            postureOpenness: 0.4,
            poseConfidence: 0.85,
            facialAvailable: true,
            expressionIntensity: 0.7,
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
            usingCustomModel: false
        ))

        // Low activity
        MicroSparkbars(features: FeatureVisualization(
            poseAvailable: true,
            movementIntensity: 0.2,
            bodyTension: 0.1,
            postureOpenness: 0.8,
            poseConfidence: 0.75,
            facialAvailable: true,
            expressionIntensity: 0.3,
            mouthOpenness: 0.1,
            eyeWideness: 0.4,
            browRaised: false,
            facialConfidence: 0.8,
            vocalAvailable: false,
            volume: nil,
            pitch: nil,
            energy: nil,
            speechRate: nil,
            predictedBand: .green,
            overallConfidence: 0.72,
            usingCustomModel: false
        ))

        // Only body available
        MicroSparkbars(features: FeatureVisualization(
            poseAvailable: true,
            movementIntensity: 0.5,
            bodyTension: 0.4,
            postureOpenness: 0.6,
            poseConfidence: 0.7,
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
            overallConfidence: 0.6,
            usingCustomModel: false
        ))
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
