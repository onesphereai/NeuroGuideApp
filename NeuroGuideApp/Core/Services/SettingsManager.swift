//
//  SettingsManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.3 - Settings & Help System
//

import Foundation
import Combine
import SwiftUI

/// Manages app settings and user preferences
class SettingsManager: ObservableObject {

    // MARK: - Published Properties

    /// Notification settings
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: SettingsKeys.notificationsEnabled)
        }
    }

    @Published var sessionRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(sessionRemindersEnabled, forKey: SettingsKeys.sessionReminders)
        }
    }

    @Published var wellbeingCheckInsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(wellbeingCheckInsEnabled, forKey: SettingsKeys.wellbeingCheckIns)
        }
    }

    /// Accessibility settings
    @Published var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: SettingsKeys.haptics)
        }
    }

    @Published var reduceMotionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(reduceMotionEnabled, forKey: SettingsKeys.reduceMotion)
        }
    }

    @Published var textSize: TextSizePreference {
        didSet {
            UserDefaults.standard.set(textSize.rawValue, forKey: SettingsKeys.textSize)
        }
    }

    @Published var highContrastEnabled: Bool {
        didSet {
            UserDefaults.standard.set(highContrastEnabled, forKey: SettingsKeys.highContrast)
        }
    }

    /// Data retention settings
    @Published var sessionHistoryRetentionDays: Int {
        didSet {
            UserDefaults.standard.set(sessionHistoryRetentionDays, forKey: SettingsKeys.sessionRetention)
        }
    }

    @Published var autoDeleteOldSessions: Bool {
        didSet {
            UserDefaults.standard.set(autoDeleteOldSessions, forKey: SettingsKeys.autoDelete)
        }
    }

    /// Offline mode settings
    @Published var offlineModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(offlineModeEnabled, forKey: SettingsKeys.offlineMode)
        }
    }

    @Published var autoDownloadUpdates: Bool {
        didSet {
            UserDefaults.standard.set(autoDownloadUpdates, forKey: SettingsKeys.autoDownload)
        }
    }

    /// Live Coach mode settings
    @Published var liveCoachMode: LiveCoachMode {
        didSet {
            UserDefaults.standard.set(liveCoachMode.rawValue, forKey: SettingsKeys.liveCoachMode)
        }
    }

    /// Claude API key for LLM-based arousal detection (Personalized Mode)
    @Published var claudeAPIKey: String? {
        didSet {
            if let key = claudeAPIKey, !key.isEmpty {
                KeychainHelper.save(key, forKey: SettingsKeys.claudeAPIKey)
            } else {
                KeychainHelper.delete(forKey: SettingsKeys.claudeAPIKey)
            }
        }
    }

    /// Groq API key (legacy support)
    @Published var groqAPIKey: String? {
        didSet {
            if let key = groqAPIKey, !key.isEmpty {
                KeychainHelper.save(key, forKey: SettingsKeys.groqAPIKey)
            } else {
                KeychainHelper.delete(forKey: SettingsKeys.groqAPIKey)
            }
        }
    }

    /// Arousal band analysis duration
    @Published var arousalBandDuration: ArousalBandDuration {
        didSet {
            UserDefaults.standard.set(arousalBandDuration.rawValue, forKey: SettingsKeys.arousalBandDuration)
        }
    }

    /// Baseline calibration duration
    @Published var baselineCalibrationDuration: BaselineCalibrationDuration {
        didSet {
            UserDefaults.standard.set(baselineCalibrationDuration.rawValue, forKey: SettingsKeys.baselineCalibrationDuration)
        }
    }

    // MARK: - Initialization

    init() {
        // Load settings from UserDefaults
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: SettingsKeys.notificationsEnabled)
        self.sessionRemindersEnabled = UserDefaults.standard.bool(forKey: SettingsKeys.sessionReminders)
        self.wellbeingCheckInsEnabled = UserDefaults.standard.bool(forKey: SettingsKeys.wellbeingCheckIns)

        self.hapticsEnabled = UserDefaults.standard.object(forKey: SettingsKeys.haptics) as? Bool ?? true
        self.reduceMotionEnabled = UserDefaults.standard.bool(forKey: SettingsKeys.reduceMotion)

        let textSizeRaw = UserDefaults.standard.string(forKey: SettingsKeys.textSize) ?? TextSizePreference.medium.rawValue
        self.textSize = TextSizePreference(rawValue: textSizeRaw) ?? .medium

        self.highContrastEnabled = UserDefaults.standard.bool(forKey: SettingsKeys.highContrast)

        self.sessionHistoryRetentionDays = UserDefaults.standard.object(forKey: SettingsKeys.sessionRetention) as? Int ?? 90
        self.autoDeleteOldSessions = UserDefaults.standard.object(forKey: SettingsKeys.autoDelete) as? Bool ?? false

        self.offlineModeEnabled = UserDefaults.standard.object(forKey: SettingsKeys.offlineMode) as? Bool ?? true
        self.autoDownloadUpdates = UserDefaults.standard.object(forKey: SettingsKeys.autoDownload) as? Bool ?? true

        let modeRaw = UserDefaults.standard.string(forKey: SettingsKeys.liveCoachMode) ?? LiveCoachMode.standard.rawValue
        self.liveCoachMode = LiveCoachMode(rawValue: modeRaw) ?? .standard

        let arousalDurationRaw = UserDefaults.standard.string(forKey: SettingsKeys.arousalBandDuration) ?? ArousalBandDuration.twentySeconds.rawValue
        self.arousalBandDuration = ArousalBandDuration(rawValue: arousalDurationRaw) ?? .twentySeconds

        let baselineDurationRaw = UserDefaults.standard.string(forKey: SettingsKeys.baselineCalibrationDuration) ?? BaselineCalibrationDuration.tenSeconds.rawValue
        self.baselineCalibrationDuration = BaselineCalibrationDuration(rawValue: baselineDurationRaw) ?? .tenSeconds

        // Load API keys from Keychain
        self.claudeAPIKey = KeychainHelper.load(forKey: SettingsKeys.claudeAPIKey)
        self.groqAPIKey = KeychainHelper.load(forKey: SettingsKeys.groqAPIKey)
    }

    // MARK: - Public Methods

    /// Reset all settings to defaults
    func resetToDefaults() {
        notificationsEnabled = false
        sessionRemindersEnabled = false
        wellbeingCheckInsEnabled = false
        hapticsEnabled = true
        reduceMotionEnabled = false
        textSize = .medium
        highContrastEnabled = false
        sessionHistoryRetentionDays = 90
        autoDeleteOldSessions = false
        offlineModeEnabled = true
        autoDownloadUpdates = true
        liveCoachMode = .standard
        arousalBandDuration = .twentySeconds
        baselineCalibrationDuration = .tenSeconds
    }

    /// Export settings as dictionary (for backup/restore)
    func exportSettings() -> [String: Any] {
        return [
            SettingsKeys.notificationsEnabled: notificationsEnabled,
            SettingsKeys.sessionReminders: sessionRemindersEnabled,
            SettingsKeys.wellbeingCheckIns: wellbeingCheckInsEnabled,
            SettingsKeys.haptics: hapticsEnabled,
            SettingsKeys.reduceMotion: reduceMotionEnabled,
            SettingsKeys.textSize: textSize.rawValue,
            SettingsKeys.highContrast: highContrastEnabled,
            SettingsKeys.sessionRetention: sessionHistoryRetentionDays,
            SettingsKeys.autoDelete: autoDeleteOldSessions,
            SettingsKeys.offlineMode: offlineModeEnabled,
            SettingsKeys.autoDownload: autoDownloadUpdates,
            SettingsKeys.liveCoachMode: liveCoachMode.rawValue,
            SettingsKeys.arousalBandDuration: arousalBandDuration.rawValue,
            SettingsKeys.baselineCalibrationDuration: baselineCalibrationDuration.rawValue
        ]
    }

    /// Import settings from dictionary (for backup/restore)
    func importSettings(_ settings: [String: Any]) {
        if let value = settings[SettingsKeys.notificationsEnabled] as? Bool {
            notificationsEnabled = value
        }
        if let value = settings[SettingsKeys.sessionReminders] as? Bool {
            sessionRemindersEnabled = value
        }
        if let value = settings[SettingsKeys.wellbeingCheckIns] as? Bool {
            wellbeingCheckInsEnabled = value
        }
        if let value = settings[SettingsKeys.haptics] as? Bool {
            hapticsEnabled = value
        }
        if let value = settings[SettingsKeys.reduceMotion] as? Bool {
            reduceMotionEnabled = value
        }
        if let value = settings[SettingsKeys.textSize] as? String,
           let textSizePref = TextSizePreference(rawValue: value) {
            textSize = textSizePref
        }
        if let value = settings[SettingsKeys.highContrast] as? Bool {
            highContrastEnabled = value
        }
        if let value = settings[SettingsKeys.sessionRetention] as? Int {
            sessionHistoryRetentionDays = value
        }
        if let value = settings[SettingsKeys.autoDelete] as? Bool {
            autoDeleteOldSessions = value
        }
        if let value = settings[SettingsKeys.offlineMode] as? Bool {
            offlineModeEnabled = value
        }
        if let value = settings[SettingsKeys.autoDownload] as? Bool {
            autoDownloadUpdates = value
        }
        if let value = settings[SettingsKeys.liveCoachMode] as? String,
           let mode = LiveCoachMode(rawValue: value) {
            liveCoachMode = mode
        }
        if let value = settings[SettingsKeys.arousalBandDuration] as? String,
           let duration = ArousalBandDuration(rawValue: value) {
            arousalBandDuration = duration
        }
        if let value = settings[SettingsKeys.baselineCalibrationDuration] as? String,
           let duration = BaselineCalibrationDuration(rawValue: value) {
            baselineCalibrationDuration = duration
        }
    }
}

// MARK: - Live Coach Mode

enum LiveCoachMode: String, CaseIterable {
    case standard = "standard"
    case personalized = "personalized"

    var displayName: String {
        switch self {
        case .standard:
            return "Standard Mode"
        case .personalized:
            return "Personalized Mode (LLM)"
        }
    }

    var description: String {
        switch self {
        case .standard:
            return "Uses rule-based ML models with child profile. Works immediately without additional setup."
        case .personalized:
            return "Uses Claude Sonnet 4.5 AI with complete child profile for holistic, context-aware detection. Requires Claude API key."
        }
    }

    var detailedDescription: String {
        switch self {
        case .standard:
            return """
            Standard Mode provides arousal detection using:
            • Rule-based weighted fusion (Pose 50%, Facial 40%, Vocal 10%)
            • Generic pose detection (Vision framework)
            • Facial expression analysis
            • Basic audio analysis
            • Profile-based personalization (baseline calibration)
            • Diagnosis-aware threshold adjustments

            Best for: Getting started immediately, offline use, or when LLM setup isn't feasible.
            """
        case .personalized:
            return """
            Personalized Mode (Claude AI) enhances detection with:
            • Advanced AI reasoning from Claude Sonnet 4.5
            • Holistic analysis of ALL child profile data
            • Context-aware decision making (behaviors, environment, session history)
            • Neurodiversity-affirming understanding
            • Explainable results with detailed reasoning
            • All Standard Mode features PLUS Claude's intelligence

            Requirements: Claude API key (get at console.anthropic.com)
            Best for: Maximum accuracy and quality when internet available.

            Note: Falls back to Standard Mode automatically if LLM fails.
            """
        }
    }

    var icon: String {
        switch self {
        case .standard:
            return "person.circle.fill"
        case .personalized:
            return "brain.head.profile"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .standard:
            return false
        case .personalized:
            return true
        }
    }
}

// MARK: - Text Size Preference

enum TextSizePreference: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"

    var sizeCategory: ContentSizeCategory {
        switch self {
        case .small:
            return .medium
        case .medium:
            return .large
        case .large:
            return .extraLarge
        case .extraLarge:
            return .accessibilityMedium
        }
    }
}

// MARK: - Settings Keys

private enum SettingsKeys {
    static let notificationsEnabled = "com.neuroguide.settings.notifications"
    static let sessionReminders = "com.neuroguide.settings.sessionReminders"
    static let wellbeingCheckIns = "com.neuroguide.settings.wellbeingCheckIns"
    static let haptics = "com.neuroguide.settings.haptics"
    static let reduceMotion = "com.neuroguide.settings.reduceMotion"
    static let textSize = "com.neuroguide.settings.textSize"
    static let highContrast = "com.neuroguide.settings.highContrast"
    static let sessionRetention = "com.neuroguide.settings.sessionRetention"
    static let autoDelete = "com.neuroguide.settings.autoDelete"
    static let offlineMode = "com.neuroguide.settings.offlineMode"
    static let autoDownload = "com.neuroguide.settings.autoDownload"
    static let liveCoachMode = "com.neuroguide.settings.liveCoachMode"
    static let arousalBandDuration = "com.neuroguide.settings.arousalBandDuration"
    static let baselineCalibrationDuration = "com.neuroguide.settings.baselineCalibrationDuration"
    static let claudeAPIKey = "com.neuroguide.settings.claudeAPIKey"
    static let groqAPIKey = "com.neuroguide.settings.groqAPIKey"
}

// MARK: - Arousal Band Duration

enum ArousalBandDuration: String, CaseIterable {
    case tenSeconds = "10"
    case fifteenSeconds = "15"
    case twentySeconds = "20"

    var displayName: String {
        switch self {
        case .tenSeconds:
            return "10 seconds"
        case .fifteenSeconds:
            return "15 seconds"
        case .twentySeconds:
            return "20 seconds"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .tenSeconds:
            return 10.0
        case .fifteenSeconds:
            return 15.0
        case .twentySeconds:
            return 20.0
        }
    }

    var description: String {
        switch self {
        case .tenSeconds:
            return "Faster response, less stable"
        case .fifteenSeconds:
            return "Balanced response and stability"
        case .twentySeconds:
            return "More stable, slower response"
        }
    }
}

// MARK: - Baseline Calibration Duration

enum BaselineCalibrationDuration: String, CaseIterable {
    case tenSeconds = "10"
    case fifteenSeconds = "15"
    case twentySeconds = "20"

    var displayName: String {
        switch self {
        case .tenSeconds:
            return "10 seconds"
        case .fifteenSeconds:
            return "15 seconds"
        case .twentySeconds:
            return "20 seconds"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .tenSeconds:
            return 10.0
        case .fifteenSeconds:
            return 15.0
        case .twentySeconds:
            return 20.0
        }
    }

    var description: String {
        switch self {
        case .tenSeconds:
            return "Quick baseline, may be less precise"
        case .fifteenSeconds:
            return "Balanced speed and precision"
        case .twentySeconds:
            return "Most precise baseline"
        }
    }
}
