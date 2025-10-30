//
//  AccessibilitySettingsView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.3 - Settings & Help System
//

import SwiftUI

/// Accessibility preferences screen
struct AccessibilitySettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settingsManager: SettingsManager

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Toggle("Haptic Feedback", isOn: $settingsManager.hapticsEnabled)
                    .accessibilityLabel("Haptic feedback")
                    .accessibilityHint("Enable vibration feedback for button taps and interactions")

                Toggle("Reduce Motion", isOn: $settingsManager.reduceMotionEnabled)
                    .accessibilityLabel("Reduce motion")
                    .accessibilityHint("Minimize animations and transitions")
            } header: {
                Text("Motion & Feedback")
            }

            Section {
                Picker("Text Size", selection: $settingsManager.textSize) {
                    ForEach(TextSizePreference.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .accessibilityLabel("Text size")
                .accessibilityHint("Choose preferred text size")

                Toggle("High Contrast", isOn: $settingsManager.highContrastEnabled)
                    .accessibilityLabel("High contrast")
                    .accessibilityHint("Increase contrast for better readability")
            } header: {
                Text("Visual")
            } footer: {
                Text("Text size affects all text in the app. High contrast improves readability in bright environments.")
            }

            Section {
                NavigationLink(destination: AccessibilityAuditView()) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.ngPrimaryBlue)
                        Text("View Accessibility Audit")
                    }
                }
                .accessibilityLabel("View accessibility audit")
                .accessibilityHint("See detailed compliance report")

                Button("Open System Accessibility Settings") {
                    openSystemSettings()
                }
                .accessibilityLabel("Open system accessibility settings")
                .accessibilityHint("Opens iOS Settings for additional accessibility options")
            } header: {
                Text("iOS Accessibility")
            } footer: {
                Text("Configure VoiceOver, Dynamic Type, and other system-wide accessibility features in iOS Settings")
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AccessibilityHelper.announce("Accessibility settings")
        }
    }

    // MARK: - Private Methods

    private func openSystemSettings() {
        AccessibilityHelper.shared.buttonTap()

        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AccessibilitySettingsView()
            .environmentObject(SettingsManager())
    }
}
