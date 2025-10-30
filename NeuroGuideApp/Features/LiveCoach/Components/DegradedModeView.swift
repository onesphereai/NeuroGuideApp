//
//  DegradedModeView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 5 - Live Coach System
//

import SwiftUI

/// View shown when session is operating in degraded mode
/// Provides guidance on how to use the app with limited permissions
struct DegradedModeView: View {
    let mode: DegradationMode

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: mode.icon)
                .font(.system(size: 48))
                .foregroundColor(.orange)

            // Title
            Text("Limited Mode Active")
                .font(.title3)
                .fontWeight(.semibold)

            // Description
            Text(mode.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Mode-specific guidance
            VStack(alignment: .leading, spacing: 12) {
                Text("What you can do:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(guidanceItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(item)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // Settings link
            if canEnablePermissions {
                Button(action: {
                    openSettings()
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Enable in Settings")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var guidanceItems: [String] {
        switch mode {
        case .cameraOnly:
            return [
                "Video-based arousal detection available",
                "Manual audio observations recommended",
                "Gesture and movement tracking active",
                "Real-time coaching suggestions provided"
            ]

        case .microphoneOnly:
            return [
                "Audio-based arousal detection available",
                "Manual video observations recommended",
                "Voice pattern analysis active",
                "Real-time coaching suggestions provided"
            ]

        case .manualOnly:
            return [
                "Manual observation mode",
                "Record observations as you see them",
                "Get coaching suggestions based on your input",
                "Session data still saved for review"
            ]
        }
    }

    private var canEnablePermissions: Bool {
        // Only show settings link if permissions were denied (not restricted)
        return true
    }

    // MARK: - Actions

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Manual Observation Entry

/// Component for manual observation entry in degraded mode
struct ManualObservationEntry: View {
    @Binding var observationText: String
    @Binding var selectedArousalBand: ArousalBand?
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Observation")
                .font(.headline)

            // Observation text
            TextField("What are you observing?", text: $observationText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Arousal band selection
            Text("Current state (optional)")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                ForEach(ArousalBand.allCases, id: \.self) { band in
                    arousalBandButton(band: band)
                }
            }

            // Submit button
            Button(action: {
                onSubmit()
                observationText = ""
                selectedArousalBand = nil
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(observationText.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
            }
            .disabled(observationText.isEmpty)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Arousal Band Button

    private func arousalBandButton(band: ArousalBand) -> some View {
        Button(action: {
            selectedArousalBand = band
        }) {
            VStack(spacing: 4) {
                Circle()
                    .fill(colorForArousalBand(band))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                selectedArousalBand == band ? Color.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                Text(bandLabel(band))
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func bandLabel(_ band: ArousalBand) -> String {
        switch band {
        case .shutdown:
            return "Low"
        case .green:
            return "Calm"
        case .yellow:
            return "Alert"
        case .orange:
            return "High"
        case .red:
            return "Crisis"
        }
    }

    private func colorForArousalBand(_ band: ArousalBand) -> Color {
        switch band {
        case .shutdown:
            return Color.blue
        case .green:
            return Color.green
        case .yellow:
            return Color.yellow
        case .orange:
            return Color.orange
        case .red:
            return Color.red
        }
    }
}

// MARK: - Permission Explanation

/// Explains why permissions are needed
struct PermissionExplanationView: View {
    let permissionType: PermissionType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(explanation)
                .font(.body)
                .foregroundColor(.primary)

            // Privacy note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Privacy Protected")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(privacyNote)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Content

    private var icon: String {
        switch permissionType {
        case .camera:
            return "video.fill"
        case .microphone:
            return "mic.fill"
        }
    }

    private var title: String {
        switch permissionType {
        case .camera:
            return "Camera Access"
        case .microphone:
            return "Microphone Access"
        }
    }

    private var subtitle: String {
        switch permissionType {
        case .camera:
            return "For visual arousal detection"
        case .microphone:
            return "For audio arousal detection"
        }
    }

    private var explanation: String {
        switch permissionType {
        case .camera:
            return "The camera helps detect visual cues like body language, facial expressions, and movement patterns to identify your child's arousal level."
        case .microphone:
            return "The microphone helps detect audio cues like voice patterns, volume, and speech rate to identify your child's arousal level."
        }
    }

    private var privacyNote: String {
        switch permissionType {
        case .camera:
            return "Video is processed on-device only. Nothing is stored or transmitted."
        case .microphone:
            return "Audio is processed on-device only. Nothing is stored or transmitted."
        }
    }

    enum PermissionType {
        case camera
        case microphone
    }
}

// MARK: - Preview

#Preview("Camera Only Mode") {
    DegradedModeView(mode: .cameraOnly)
}

#Preview("Manual Only Mode") {
    DegradedModeView(mode: .manualOnly)
}

#Preview("Camera Permission") {
    PermissionExplanationView(permissionType: .camera)
}
