//
//  SettingsManagerTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 1.3 - Settings & Help System Tests
//

import XCTest
@testable import NeuroGuideApp

final class SettingsManagerTests: XCTestCase {

    var settingsManager: SettingsManager!

    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager()
        // Clear UserDefaults before each test
        clearUserDefaults()
    }

    override func tearDown() {
        settingsManager = nil
        clearUserDefaults()
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func clearUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "com.neuroguide.settings.notifications")
        defaults.removeObject(forKey: "com.neuroguide.settings.sessionReminders")
        defaults.removeObject(forKey: "com.neuroguide.settings.wellbeingCheckIns")
        defaults.removeObject(forKey: "com.neuroguide.settings.haptics")
        defaults.removeObject(forKey: "com.neuroguide.settings.reduceMotion")
        defaults.removeObject(forKey: "com.neuroguide.settings.textSize")
        defaults.removeObject(forKey: "com.neuroguide.settings.highContrast")
        defaults.removeObject(forKey: "com.neuroguide.settings.sessionRetention")
        defaults.removeObject(forKey: "com.neuroguide.settings.autoDelete")
        defaults.removeObject(forKey: "com.neuroguide.settings.offlineMode")
        defaults.removeObject(forKey: "com.neuroguide.settings.autoDownload")
    }

    // MARK: - Initialization Tests

    func testDefaultValues() {
        let manager = SettingsManager()

        // Notification defaults
        XCTAssertFalse(manager.notificationsEnabled)
        XCTAssertFalse(manager.sessionRemindersEnabled)
        XCTAssertFalse(manager.wellbeingCheckInsEnabled)

        // Accessibility defaults
        XCTAssertTrue(manager.hapticsEnabled)
        XCTAssertFalse(manager.reduceMotionEnabled)
        XCTAssertEqual(manager.textSize, .medium)
        XCTAssertFalse(manager.highContrastEnabled)

        // Privacy defaults
        XCTAssertEqual(manager.sessionHistoryRetentionDays, 90)
        XCTAssertFalse(manager.autoDeleteOldSessions)
        XCTAssertTrue(manager.offlineModeEnabled)
        XCTAssertTrue(manager.autoDownloadUpdates)
    }

    // MARK: - Notification Settings Tests

    func testNotificationsEnabled() {
        settingsManager.notificationsEnabled = true
        XCTAssertTrue(settingsManager.notificationsEnabled)

        // Verify persistence
        let savedValue = UserDefaults.standard.bool(forKey: "com.neuroguide.settings.notifications")
        XCTAssertTrue(savedValue)
    }

    func testSessionRemindersEnabled() {
        settingsManager.sessionRemindersEnabled = true
        XCTAssertTrue(settingsManager.sessionRemindersEnabled)

        // Verify persistence
        let savedValue = UserDefaults.standard.bool(forKey: "com.neuroguide.settings.sessionReminders")
        XCTAssertTrue(savedValue)
    }

    // MARK: - Accessibility Settings Tests

    func testHapticsEnabled() {
        settingsManager.hapticsEnabled = false
        XCTAssertFalse(settingsManager.hapticsEnabled)

        // Verify persistence
        let savedValue = UserDefaults.standard.bool(forKey: "com.neuroguide.settings.haptics")
        XCTAssertFalse(savedValue)
    }

    func testTextSizePreference() {
        settingsManager.textSize = .large
        XCTAssertEqual(settingsManager.textSize, .large)

        // Verify persistence
        let savedValue = UserDefaults.standard.string(forKey: "com.neuroguide.settings.textSize")
        XCTAssertEqual(savedValue, "Large")
    }

    func testHighContrastEnabled() {
        settingsManager.highContrastEnabled = true
        XCTAssertTrue(settingsManager.highContrastEnabled)

        // Verify persistence
        let savedValue = UserDefaults.standard.bool(forKey: "com.neuroguide.settings.highContrast")
        XCTAssertTrue(savedValue)
    }

    // MARK: - Privacy Settings Tests

    func testSessionRetentionDays() {
        settingsManager.sessionHistoryRetentionDays = 180
        XCTAssertEqual(settingsManager.sessionHistoryRetentionDays, 180)

        // Verify persistence
        let savedValue = UserDefaults.standard.integer(forKey: "com.neuroguide.settings.sessionRetention")
        XCTAssertEqual(savedValue, 180)
    }

    func testAutoDeleteOldSessions() {
        settingsManager.autoDeleteOldSessions = true
        XCTAssertTrue(settingsManager.autoDeleteOldSessions)

        // Verify persistence
        let savedValue = UserDefaults.standard.bool(forKey: "com.neuroguide.settings.autoDelete")
        XCTAssertTrue(savedValue)
    }

    func testOfflineMode() {
        settingsManager.offlineModeEnabled = false
        XCTAssertFalse(settingsManager.offlineModeEnabled)

        // Verify persistence
        let savedValue = UserDefaults.standard.bool(forKey: "com.neuroguide.settings.offlineMode")
        XCTAssertFalse(savedValue)
    }

    // MARK: - Reset Tests

    func testResetToDefaults() {
        // Change all settings
        settingsManager.notificationsEnabled = true
        settingsManager.hapticsEnabled = false
        settingsManager.textSize = .extraLarge
        settingsManager.sessionHistoryRetentionDays = 365

        // Reset
        settingsManager.resetToDefaults()

        // Verify defaults restored
        XCTAssertFalse(settingsManager.notificationsEnabled)
        XCTAssertTrue(settingsManager.hapticsEnabled)
        XCTAssertEqual(settingsManager.textSize, .medium)
        XCTAssertEqual(settingsManager.sessionHistoryRetentionDays, 90)
    }

    // MARK: - Export/Import Tests

    func testExportSettings() {
        // Set some values
        settingsManager.notificationsEnabled = true
        settingsManager.textSize = .large
        settingsManager.sessionHistoryRetentionDays = 180

        // Export
        let exported = settingsManager.exportSettings()

        // Verify exported values
        XCTAssertEqual(exported["com.neuroguide.settings.notifications"] as? Bool, true)
        XCTAssertEqual(exported["com.neuroguide.settings.textSize"] as? String, "Large")
        XCTAssertEqual(exported["com.neuroguide.settings.sessionRetention"] as? Int, 180)
    }

    func testImportSettings() {
        let settings: [String: Any] = [
            "com.neuroguide.settings.notifications": true,
            "com.neuroguide.settings.textSize": "Extra Large",
            "com.neuroguide.settings.sessionRetention": 365
        ]

        settingsManager.importSettings(settings)

        XCTAssertTrue(settingsManager.notificationsEnabled)
        XCTAssertEqual(settingsManager.textSize, .extraLarge)
        XCTAssertEqual(settingsManager.sessionHistoryRetentionDays, 365)
    }

    func testImportSettingsWithInvalidData() {
        let settings: [String: Any] = [
            "com.neuroguide.settings.textSize": "Invalid",
            "com.neuroguide.settings.sessionRetention": "not a number"
        ]

        // Should not crash
        settingsManager.importSettings(settings)

        // Should keep defaults for invalid values
        XCTAssertEqual(settingsManager.textSize, .medium)
    }
}

// MARK: - TextSizePreference Tests

final class TextSizePreferenceTests: XCTestCase {

    func testAllCases() {
        let allCases = TextSizePreference.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.small))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.large))
        XCTAssertTrue(allCases.contains(.extraLarge))
    }

    func testRawValues() {
        XCTAssertEqual(TextSizePreference.small.rawValue, "Small")
        XCTAssertEqual(TextSizePreference.medium.rawValue, "Medium")
        XCTAssertEqual(TextSizePreference.large.rawValue, "Large")
        XCTAssertEqual(TextSizePreference.extraLarge.rawValue, "Extra Large")
    }

    func testSizeCategories() {
        XCTAssertEqual(TextSizePreference.small.sizeCategory, .medium)
        XCTAssertEqual(TextSizePreference.medium.sizeCategory, .large)
        XCTAssertEqual(TextSizePreference.large.sizeCategory, .extraLarge)
        XCTAssertEqual(TextSizePreference.extraLarge.sizeCategory, .accessibilityMedium)
    }
}
