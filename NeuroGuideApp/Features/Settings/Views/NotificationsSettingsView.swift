//
//  NotificationsSettingsView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.3 - Settings & Help System
//

import SwiftUI

/// Notifications preferences screen
struct NotificationsSettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settingsManager: SettingsManager

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Toggle("Enable Notifications", isOn: $settingsManager.notificationsEnabled)
                    .accessibilityLabel("Enable notifications")
                    .accessibilityHint("Toggle to enable or disable all notifications")
            } header: {
                Text("General")
            } footer: {
                Text("Allow attune to send you helpful reminders and check-ins")
            }

            if settingsManager.notificationsEnabled {
                Section {
                    Toggle("Session Reminders", isOn: $settingsManager.sessionRemindersEnabled)
                        .accessibilityLabel("Session reminders")
                        .accessibilityHint("Get reminders to check in with your child")

                    Toggle("Well-being Check-Ins", isOn: $settingsManager.wellbeingCheckInsEnabled)
                        .accessibilityLabel("Well-being check-ins")
                        .accessibilityHint("Receive prompts for parent self-care check-ins")
                } header: {
                    Text("Notification Types")
                }
            }

            Section {
                Button("Open System Settings") {
                    openSystemSettings()
                }
                .accessibilityLabel("Open system notification settings")
                .accessibilityHint("Opens iOS Settings to configure notification permissions")
            } header: {
                Text("iOS Permissions")
            } footer: {
                Text("Manage notification permissions in iOS Settings")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AccessibilityHelper.announce("Notifications settings")
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
        NotificationsSettingsView()
            .environmentObject(SettingsManager())
    }
}
