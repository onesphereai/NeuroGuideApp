//
//  LiveCoachSettingsView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Live Coach Settings - Standard vs Personalized Mode
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

            // Arousal Band Duration Settings
            Section {
                ForEach(ArousalBandDuration.allCases, id: \.self) { duration in
                    DurationSelectionRow(
                        title: duration.displayName,
                        description: duration.description,
                        isSelected: settingsManager.arousalBandDuration == duration,
                        action: {
                            withAnimation {
                                AccessibilityHelper.shared.buttonTap()
                                settingsManager.arousalBandDuration = duration
                            }
                        }
                    )
                }
            } header: {
                Text("Arousal Band Analysis Duration")
            } footer: {
                Text("How long to observe behavior before identifying a stable arousal band. Shorter durations respond faster but may be less stable.")
            }

            // Feature Comparison
            Section {
                ComparisonRow(
                    feature: "ML Models",
                    standardValue: "Generic",
                    personalizedValue: "Custom + Generic"
                )

                ComparisonRow(
                    feature: "Accuracy",
                    standardValue: "Good",
                    personalizedValue: "Excellent"
                )

                ComparisonRow(
                    feature: "Setup Time",
                    standardValue: "Immediate",
                    personalizedValue: "Requires Training"
                )

                ComparisonRow(
                    feature: "Training Required",
                    standardValue: "None",
                    personalizedValue: "25+ videos"
                )

                ComparisonRow(
                    feature: "Child Specificity",
                    standardValue: "Profile-based",
                    personalizedValue: "Fully Customized"
                )
            } header: {
                Text("Feature Comparison")
            }

            // API Key Configuration (iOS 18.0+)
            if #available(iOS 18.0, *) {
                Section {
                    ClaudeAPIKeyConfigurationView()
                } header: {
                    Text("Claude API Configuration")
                } footer: {
                    Text("Required for Personalized Mode: Configure your Claude API key to enable AI-powered arousal detection with complete child profile context. Get your key at console.anthropic.com")
                }
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

// MARK: - Claude API Key Configuration View

@available(iOS 18.0, *)
struct ClaudeAPIKeyConfigurationView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var apiKey: String = ""
    @State private var showingKeyInput: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private var isConfigured: Bool {
        settingsManager.claudeAPIKey != nil && !(settingsManager.claudeAPIKey?.isEmpty ?? true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isConfigured {
                // API key is configured
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text("Claude API Key Configured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Change") {
                        showingKeyInput = true
                    }
                    .font(.subheadline)

                    Button("Clear", role: .destructive) {
                        clearAPIKey()
                    }
                    .font(.subheadline)
                }
            } else {
                // No API key configured
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)

                    Text("No Claude API Key")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Configure") {
                        showingKeyInput = true
                    }
                    .font(.subheadline)
                }
            }

            // Success/Error messages
            if let success = successMessage {
                Text(success)
                    .font(.caption)
                    .foregroundColor(.green)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingKeyInput) {
            ClaudeAPIKeyInputSheet(
                apiKey: $apiKey,
                onSave: { saveAPIKey() },
                onCancel: { showingKeyInput = false }
            )
        }
    }

    private func saveAPIKey() {
        errorMessage = nil
        successMessage = nil

        guard !apiKey.isEmpty else {
            errorMessage = "Please enter a valid API key"
            return
        }

        settingsManager.claudeAPIKey = apiKey
        successMessage = "Claude API key saved successfully"
        showingKeyInput = false
        apiKey = ""

        // Clear messages after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            successMessage = nil
        }
    }

    private func clearAPIKey() {
        settingsManager.claudeAPIKey = nil
        successMessage = "API key cleared"

        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            successMessage = nil
        }
    }
}

// MARK: - Legacy API Key Configuration View (for Groq - deprecated)

@available(iOS 18.0, *)
struct APIKeyConfigurationView: View {
    @State private var apiKey: String = ""
    @State private var isConfigured: Bool = false
    @State private var showingKeyInput: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let llmService = LLMCoachingService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isConfigured {
                // API key is configured
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text("API Key Configured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Change") {
                        showingKeyInput = true
                    }
                    .font(.subheadline)

                    Button("Clear", role: .destructive) {
                        clearAPIKey()
                    }
                    .font(.subheadline)
                }
            } else {
                // No API key configured
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)

                    Text("No API Key Configured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Configure") {
                        showingKeyInput = true
                    }
                    .font(.subheadline)
                }
            }

            // Success/Error messages
            if let success = successMessage {
                Text(success)
                    .font(.caption)
                    .foregroundColor(.green)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingKeyInput) {
            APIKeyInputSheet(
                apiKey: $apiKey,
                onSave: { saveAPIKey() },
                onCancel: { showingKeyInput = false }
            )
        }
        .onAppear {
            checkAPIKeyStatus()
        }
    }

    private func checkAPIKeyStatus() {
        isConfigured = llmService.hasAPIKey()
    }

    private func saveAPIKey() {
        errorMessage = nil
        successMessage = nil

        do {
            try llmService.configureGroqAPI(apiKey: apiKey)
            isConfigured = true
            successMessage = "API key saved successfully"
            showingKeyInput = false
            apiKey = ""

            // Clear messages after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearAPIKey() {
        llmService.clearAPIKey(provider: .claude)
        isConfigured = false
        successMessage = "API key cleared"

        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            successMessage = nil
        }
    }
}

// MARK: - Claude API Key Input Sheet

@available(iOS 18.0, *)
struct ClaudeAPIKeyInputSheet: View {
    @Binding var apiKey: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Enter Claude API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Claude API Key")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Claude API key should start with 'sk-ant-' and be around 100+ characters long.")
                            .font(.caption)

                        Link("Get API Key from Anthropic Console", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                            .font(.caption)
                    }
                }

                Section {
                    Text("Your API key is stored securely in the device keychain and never leaves your device except when making API calls to Claude.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Configure Claude API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
        }
    }
}

// MARK: - Legacy Groq API Key Input Sheet

@available(iOS 18.0, *)
struct APIKeyInputSheet: View {
    @Binding var apiKey: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Enter Groq API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Groq API Key")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Groq API key should start with 'gsk_' and be 56 characters long.")
                            .font(.caption)

                        Link("Get API Key from Groq", destination: URL(string: "https://console.groq.com/keys")!)
                            .font(.caption)
                    }
                }

                Section {
                    Text("Your API key is stored securely in the device keychain and never leaves your device except when making API calls to Groq.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Configure API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
        }
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

// MARK: - Duration Selection Row

struct DurationSelectionRow: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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
        .accessibilityLabel("\(title). \(description)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let feature: String
    let standardValue: String
    let personalizedValue: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(feature)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()
            }

            HStack(spacing: 0) {
                // Standard Mode
                VStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(standardValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                // Personalized Mode
                VStack(spacing: 4) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.caption)
                        .foregroundColor(.purple)

                    Text(personalizedValue)
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

                Text("**Standard Mode**: Uses generic ML models and child profile information. Works immediately without training data. Best for getting started or when custom training isn't feasible.\n\n**Personalized Mode**: Uses custom ML model trained on YOUR child's videos for higher accuracy. Requires minimum 25 training videos (5 per arousal state). Best for ongoing use after collecting training data.")
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
