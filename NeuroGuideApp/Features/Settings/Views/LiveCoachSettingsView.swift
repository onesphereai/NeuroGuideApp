//
//  LiveCoachSettingsView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Unit 5 - Live Coach Record-First Flow
//

import SwiftUI

/// Settings for Live Coach mode selection
struct LiveCoachSettingsView: View {

    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            // Mode Selection
            Section {
                ForEach(LiveCoachMode.allCases, id: \.self) { mode in
                    ModeSelectionRow(
                        mode: mode,
                        isSelected: settingsManager.liveCoachMode == mode,
                        action: {
                            withAnimation {
                                AccessibilityHelper.shared.buttonTap()
                                settingsManager.liveCoachMode = mode
                            }
                        }
                    )
                }
            } header: {
                Text("Live Coach Mode")
            } footer: {
                Text("Choose how you want to use Live Coach. You can change this anytime in Settings.")
            }

            // Current Mode Details
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: settingsManager.liveCoachMode.icon)
                            .font(.title2)
                            .foregroundColor(.blue)

                        Text(settingsManager.liveCoachMode.displayName)
                            .font(.headline)
                    }

                    Text(settingsManager.liveCoachMode.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Current Mode")
            }

            // Feature Comparison
            Section {
                ComparisonRow(
                    feature: "Processing",
                    realTimeValue: "Live",
                    recordFirstValue: "After Session"
                )

                ComparisonRow(
                    feature: "Battery Usage",
                    realTimeValue: "Higher",
                    recordFirstValue: "Lower"
                )

                ComparisonRow(
                    feature: "Privacy",
                    realTimeValue: "Good",
                    recordFirstValue: "Excellent"
                )

                ComparisonRow(
                    feature: "Analysis Depth",
                    realTimeValue: "Basic",
                    recordFirstValue: "Comprehensive"
                )

                ComparisonRow(
                    feature: "Video Replay",
                    realTimeValue: "No",
                    recordFirstValue: "Yes"
                )

                ComparisonRow(
                    feature: "Session History",
                    realTimeValue: "Limited",
                    recordFirstValue: "Full (4 weeks)"
                )
            } header: {
                Text("Feature Comparison")
            }

            // Info Box
            Section {
                InfoBox()
            }
        }
        .navigationTitle("Live Coach Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Mode Selection Row

struct ModeSelectionRow: View {
    let mode: LiveCoachMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: mode.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .gray)
                }

                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.displayName). \(mode.description)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let feature: String
    let realTimeValue: String
    let recordFirstValue: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(feature)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()
            }

            HStack(spacing: 0) {
                // Real-Time
                VStack(spacing: 4) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text(realTimeValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                // Record-First
                VStack(spacing: 4) {
                    Image(systemName: "video.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(recordFirstValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Info Box

struct InfoBox: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 8) {
                Text("About These Modes")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("**Real-Time Mode**: Traditional Live Coach experience with instant feedback.\n\n**Record-First Mode** (Recommended): New privacy-focused mode that records your session first, then provides comprehensive analysis including behavior spectrum, arousal timeline, and parent emotion insights.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// MARK: - Preview

struct LiveCoachSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LiveCoachSettingsView()
                .environmentObject(SettingsManager())
        }
    }
}
