//
//  SettingsView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import SwiftUI

/// Settings screen
/// Fully implemented in Bolt 1.3
struct SettingsView: View {

    // MARK: - Environment

    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var settingsManager = SettingsManager()
    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    Button(action: {
                        AccessibilityHelper.shared.buttonTap()
                        coordinator.navigateToProfileSelection()
                    }) {
                        HStack(spacing: 12) {
                            // Icon
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .cornerRadius(8)
                                .accessibilityHidden(true)

                            // Title
                            Text("Switch Profile")
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            // Chevron
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Switch Profile")
                    .accessibilityHint("Double tap to select a different profile")
                    .accessibilityIdentifier("settings_switch_profile_button")
                } header: {
                    Text("Profile")
                }

                // App Settings Section
                Section {
                    NavigationLink(destination: LiveCoachSettingsView().environmentObject(settingsManager)) {
                        SettingsRowView(
                            icon: "video.circle.fill",
                            title: "Live Coach Mode",
                            iconColor: .blue
                        )
                    }

                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRowView(
                            icon: "paintbrush.fill",
                            title: "Appearance",
                            iconColor: .purple
                        )
                    }

                    NavigationLink(destination: NotificationsSettingsView().environmentObject(settingsManager)) {
                        SettingsRowView(
                            icon: "bell.fill",
                            title: "Notifications",
                            iconColor: .orange
                        )
                    }

                    NavigationLink(destination: AccessibilitySettingsView().environmentObject(settingsManager)) {
                        SettingsRowView(
                            icon: "accessibility",
                            title: "Accessibility",
                            iconColor: .blue
                        )
                    }

                    NavigationLink(destination: PrivacyDataSettingsView().environmentObject(settingsManager)) {
                        SettingsRowView(
                            icon: "lock.fill",
                            title: "Privacy & Data",
                            iconColor: .green
                        )
                    }
                } header: {
                    Text("App Settings")
                }

                // Help & Tutorial Section
                Section {
                    Button(action: {
                        AccessibilityHelper.shared.buttonTap()
                        coordinator.replayOnboarding()
                    }) {
                        HStack(spacing: 12) {
                            // Icon
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .cornerRadius(8)
                                .accessibilityHidden(true)

                            // Title
                            Text("Replay Tutorial")
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            // Chevron
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Replay Tutorial")
                    .accessibilityHint("Double tap to replay the onboarding tutorial")
                    .accessibilityIdentifier("settings_replay_tutorial_button")

                    NavigationLink(destination: HelpView()) {
                        SettingsRowView(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            iconColor: .purple
                        )
                    }
                } header: {
                    Text("Help & Tutorial")
                }

                // About Section
                Section {
                    NavigationLink(destination: AboutView()) {
                        SettingsRowView(
                            icon: "info.circle.fill",
                            title: "About attune",
                            iconColor: .blue
                        )
                    }

                    NavigationLink(destination: LegalView()) {
                        SettingsRowView(
                            icon: "doc.text.fill",
                            title: "Terms & Privacy Policy",
                            iconColor: .gray
                        )
                    }
                } header: {
                    Text("About")
                }

                // App Info
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("0.3.0 (Bolt 1.3)")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("App version 0.3.0, Bolt 1.3")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        AccessibilityHelper.shared.buttonTap()
                        coordinator.navigate(to: .home)
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Double tap to return to home screen")
                    .accessibilityIdentifier("settings_done_button")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            AccessibilityHelper.announce("Settings")
        }
    }
}

// MARK: - Settings Row Components

/// Reusable settings row for NavigationLink
struct SettingsRowView: View {
    let icon: String
    let title: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(iconColor)
                .cornerRadius(8)
                .accessibilityHidden(true)

            // Title
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

/// Reusable settings row with action button
struct SettingsActionRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            AccessibilityHelper.shared.buttonTap()
            action()
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(iconColor)
                    .cornerRadius(8)
                    .accessibilityHidden(true)

                // Title
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to open \(title)")
    }
}

// MARK: - Preview Provider

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default preview
            SettingsView()
                .environmentObject(AppCoordinator())
                .previewDisplayName("Default")

            // Dark mode preview
            SettingsView()
                .environmentObject(AppCoordinator())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")

            // Large text preview
            SettingsView()
                .environmentObject(AppCoordinator())
                .environment(\.sizeCategory, .accessibilityLarge)
                .previewDisplayName("Large Text")
        }
    }
}
