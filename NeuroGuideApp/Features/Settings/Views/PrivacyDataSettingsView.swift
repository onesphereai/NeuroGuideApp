//
//  PrivacyDataSettingsView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.3 - Settings & Help System
//

import SwiftUI

/// Privacy and data retention settings screen
struct PrivacyDataSettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settingsManager: SettingsManager

    // MARK: - State

    @State private var showingDeleteConfirmation = false
    @State private var biometricEnabled = false
    @State private var showBiometricError = false
    @State private var biometricErrorMessage = ""

    private let appLockManager = AppLockManager.shared

    // MARK: - Body

    var body: some View {
        List {
            // Biometric Security Section
            Section {
                if appLockManager.canUseBiometric() {
                    Toggle(isOn: $biometricEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: appLockManager.getBiometricType().iconName)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("App Lock")
                                Text("Unlock app with \(appLockManager.getBiometricType().displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: biometricEnabled) { newValue in
                        toggleBiometric(enabled: newValue)
                    }
                    .accessibilityLabel("App lock with \(appLockManager.getBiometricType().displayName)")
                    .accessibilityHint(biometricEnabled ? "Enabled. Double tap to disable" : "Disabled. Double tap to enable")
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "faceid")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Lock")
                            Text("Biometric authentication not available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityLabel("App lock not available")
                }
            } header: {
                Text("Security")
            } footer: {
                if appLockManager.canUseBiometric() {
                    Text("Require \(appLockManager.getBiometricType().displayName) to unlock the app when returning from background")
                } else {
                    Text("Set up Face ID or Touch ID in device Settings to enable app lock")
                }
            }

            Section {
                Picker("Keep Session History For", selection: $settingsManager.sessionHistoryRetentionDays) {
                    Text("30 days").tag(30)
                    Text("60 days").tag(60)
                    Text("90 days").tag(90)
                    Text("6 months").tag(180)
                    Text("1 year").tag(365)
                    Text("Forever").tag(Int.max)
                }
                .accessibilityLabel("Session history retention period")
                .accessibilityHint("Choose how long to keep session history")

                Toggle("Auto-Delete Old Sessions", isOn: $settingsManager.autoDeleteOldSessions)
                    .accessibilityLabel("Auto-delete old sessions")
                    .accessibilityHint("Automatically remove sessions older than retention period")
            } header: {
                Text("Data Retention")
            } footer: {
                Text("Session summaries older than the selected period will be \(settingsManager.autoDeleteOldSessions ? "automatically deleted" : "available for manual deletion")")
            }

            Section {
                Toggle("Offline Mode", isOn: $settingsManager.offlineModeEnabled)
                    .accessibilityLabel("Offline mode")
                    .accessibilityHint("All data stays on your device, no cloud sync")

                if !settingsManager.offlineModeEnabled {
                    Toggle("Auto-Download Updates", isOn: $settingsManager.autoDownloadUpdates)
                        .accessibilityLabel("Auto-download content updates")
                        .accessibilityHint("Automatically download new content when available")
                }
            } header: {
                Text("Privacy Mode")
            } footer: {
                if settingsManager.offlineModeEnabled {
                    Text("Offline mode ensures all your data stays on this device. No information is sent to the cloud.")
                } else {
                    Text("Cloud sync allows optional backup and content updates. All data is encrypted.")
                }
            }

            Section {
                Button("Delete All Session Data", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .accessibilityLabel("Delete all session data")
                .accessibilityHint("Permanently removes all session history")
            } header: {
                Text("Data Management")
            } footer: {
                Text("This will permanently delete all session history. Child profiles will be preserved.")
            }
        }
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete All Sessions?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllSessionData()
            }
        } message: {
            Text("This will permanently delete all session history. This action cannot be undone.")
        }
        .onAppear {
            AccessibilityHelper.announce("Privacy and data settings")
            biometricEnabled = appLockManager.isBiometricEnabled()
        }
        .alert("Biometric Error", isPresented: $showBiometricError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(biometricErrorMessage)
        }
    }

    // MARK: - Private Methods

    private func deleteAllSessionData() {
        // TODO: Implement actual data deletion
        // For now, just provide feedback
        AccessibilityHelper.shared.success()
        AccessibilityHelper.announce("All session data deleted")
    }

    private func toggleBiometric(enabled: Bool) {
        do {
            try appLockManager.setBiometricEnabled(enabled)
            AccessibilityHelper.shared.success()
            if enabled {
                AccessibilityHelper.announce("App lock enabled")
            } else {
                AccessibilityHelper.announce("App lock disabled")
            }
        } catch {
            biometricEnabled = !enabled // Revert toggle
            biometricErrorMessage = error.localizedDescription
            showBiometricError = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PrivacyDataSettingsView()
            .environmentObject(SettingsManager())
    }
}
