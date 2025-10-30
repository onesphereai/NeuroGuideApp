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

        let modeRaw = UserDefaults.standard.string(forKey: SettingsKeys.liveCoachMode) ?? LiveCoachMode.recordFirst.rawValue
        self.liveCoachMode = LiveCoachMode(rawValue: modeRaw) ?? .recordFirst
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
        liveCoachMode = .recordFirst
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
            SettingsKeys.liveCoachMode: liveCoachMode.rawValue
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
    }
}

// MARK: - Live Coach Mode

enum LiveCoachMode: String, CaseIterable {
    case realTime = "realTime"
    case recordFirst = "recordFirst"

    var displayName: String {
        switch self {
        case .realTime:
            return "Real-Time"
        case .recordFirst:
            return "Record-First"
        }
    }

    var description: String {
        switch self {
        case .realTime:
            return "Get instant coaching suggestions as you interact with your child. Requires continuous camera and processing."
        case .recordFirst:
            return "Record a session first, then receive detailed analysis and coaching suggestions. More privacy-friendly and comprehensive."
        }
    }

    var icon: String {
        switch self {
        case .realTime:
            return "bolt.circle.fill"
        case .recordFirst:
            return "video.circle.fill"
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
}
