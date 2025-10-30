//
//  AppearanceSettingsView.swift
//  NeuroGuide
//
//  Unit 12 - Theme Support/Manager (US-039)
//  Appearance and theme settings screen
//

import SwiftUI

/// Settings screen for appearance and theme customization
struct AppearanceSettingsView: View {

    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            // Theme Selection
            Section {
                ThemePickerView(themeManager: themeManager)
                    .listRowInsets(EdgeInsets(top: NGSpacing.md, leading: NGSpacing.md, bottom: NGSpacing.md, trailing: NGSpacing.md))
                    .listRowBackground(Color.clear)
            } header: {
                Text("Color Scheme")
            } footer: {
                Text("Choose how attune appears. System automatically switches between light and dark based on your device settings.")
            }

            // Visual Accessibility
            Section {
                Toggle(isOn: $themeManager.highContrast) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("High Contrast")
                            .font(.ngBody)
                            .foregroundColor(.ngTextPrimary)

                        Text("Increases contrast for better visibility")
                            .font(.ngCaption)
                            .foregroundColor(.ngTextSecondary)
                    }
                }
                .tint(.ngPrimaryBlue)

                Toggle(isOn: $themeManager.reduceMotion) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reduce Motion")
                            .font(.ngBody)
                            .foregroundColor(.ngTextPrimary)

                        Text("Minimizes animations and transitions")
                            .font(.ngCaption)
                            .foregroundColor(.ngTextSecondary)
                    }
                }
                .tint(.ngPrimaryBlue)
            } header: {
                Text("Visual Accessibility")
            } footer: {
                Text("These settings help make attune more comfortable to use for different visual needs.")
            }

            // Info Section
            Section {
                HStack(spacing: NGSpacing.sm) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.ngPrimaryBlue)

                    Text("attune adapts its colors automatically for light and dark modes while maintaining accessibility standards.")
                        .font(.ngCaption)
                        .foregroundColor(.ngTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .listRowBackground(Color.ngSurface)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AccessibilityHelper.announce("Appearance settings")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AppearanceSettingsView()
    }
}
