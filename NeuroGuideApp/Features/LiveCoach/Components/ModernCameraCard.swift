//
//  ModernCameraCard.swift
//  NeuroGuide
//
//  Modern camera preview with emotional state overlay
//

import SwiftUI
import AVFoundation

struct ModernCameraCard: View {
    let session: AVCaptureSession
    let title: String
    let emotionalState: String?
    let arousalBand: ArousalBand?
    let confidence: Double?
    let featureVisualization: FeatureVisualization?
    let showStability: Bool
    let stabilityInfo: (isStable: Bool, motion: CameraMotion?)?
    let isPersonDetected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Camera preview
            ZStack(alignment: .topLeading) {
                CameraPreviewView(session: session)
                    .aspectRatio(4/3, contentMode: .fit)
                    .background(Color.black)

                // Micro-sparkbars (top-left)
                if title.contains("Child"), let features = featureVisualization {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            MicroSparkbars(features: features)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(16)
                }

                // Status pill (top-right)
                if title.contains("Child"), let band = arousalBand {
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack {
                            Spacer()
                            statusPill(band: band)
                        }
                        Spacer()
                    }
                    .padding(16)
                }

                // Emotional state overlay
                if let state = emotionalState {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            emotionalStateChip(state: state)
                                .padding(16)
                        }
                    }
                }

                // Stability indicator (bottom-left)
                if showStability, let stability = stabilityInfo {
                    VStack {
                        Spacer()
                        HStack {
                            stabilityIndicator(isStable: stability.isStable)
                            Spacer()
                        }
                    }
                    .padding(16)
                }

                // No person detected overlay (center)
                if !isPersonDetected && title.contains("Child") {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            noPersonDetectedIndicator()
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(borderColor, lineWidth: 4)
            )
        }
    }

    private var titleIcon: String {
        title.contains("Child") ? "figure.child" : "figure.stand"
    }

    private var borderColor: Color {
        if let band = arousalBand {
            return bandColor(for: band)  // Full opacity for better visibility
        }
        return Color.gray.opacity(0.3)
    }

    private func bandColor(for band: ArousalBand) -> Color {
        switch band {
        case .shutdown: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        }
    }

    private func emotionalStateChip(state: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: emotionIcon(for: state))
                .font(.system(size: 13, weight: .semibold))
            Text(state.capitalized)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(emotionColor(for: state))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
        )
    }

    private func emotionIcon(for state: String) -> String {
        let lowercased = state.lowercased()
        if lowercased.contains("calm") || lowercased.contains("happy") {
            return "face.smiling"
        } else if lowercased.contains("anxious") || lowercased.contains("worried") {
            return "exclamationmark.triangle.fill"
        } else if lowercased.contains("frustrated") || lowercased.contains("angry") {
            return "flame.fill"
        } else if lowercased.contains("sad") {
            return "cloud.rain.fill"
        } else {
            return "brain.head.profile"
        }
    }

    private func emotionColor(for state: String) -> Color {
        let lowercased = state.lowercased()
        if lowercased.contains("calm") || lowercased.contains("happy") {
            return .green.opacity(0.9)
        } else if lowercased.contains("anxious") || lowercased.contains("worried") {
            return .yellow.opacity(0.9)
        } else if lowercased.contains("frustrated") || lowercased.contains("angry") {
            return .orange.opacity(0.9)
        } else if lowercased.contains("sad") {
            return .blue.opacity(0.9)
        } else {
            return .purple.opacity(0.9)
        }
    }

    private func stabilityIndicator(isStable: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isStable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
            Text(isStable ? "Stable" : "Unstable")
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isStable ? Color.green.opacity(0.9) : Color.orange.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        )
    }

    private func statusPill(band: ArousalBand) -> some View {
        HStack(spacing: 8) {
            // Pulsing dot
            PulsingDot(color: bandColor(for: band))
                .frame(width: 8, height: 8)

            // Band name and confidence
            HStack(spacing: 4) {
                Text(bandDisplayName(for: band))
                    .font(.system(size: 13, weight: .bold))

                if let conf = confidence {
                    Text("• \(Int(conf * 100))%")
                        .font(.system(size: 13, weight: .semibold))
                        .opacity(0.9)
                }
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func bandDisplayName(for band: ArousalBand) -> String {
        switch band {
        case .shutdown: return "Shutdown"
        case .green: return "Calm"
        case .yellow: return "Elevated"
        case .orange: return "High"
        case .red: return "Crisis"
        }
    }

    private func noPersonDetectedIndicator() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 48))
                .foregroundColor(.white)

            Text("No Person Detected")
                .font(.headline)
                .foregroundColor(.white)

            Text("Please position the child in frame")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
        )
    }
}

// MARK: - Pulsing Dot Animation

struct PulsingDot: View {
    let color: Color
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(color)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
