//
//  LaunchStateManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import Foundation
import Combine

/// Manages first launch detection and welcome completion state
/// Persists state using UserDefaults
class LaunchStateManager: ObservableObject {

    // MARK: - Published Properties

    /// Indicates whether the user has completed the welcome screen
    @Published var hasCompletedWelcome: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedWelcome, forKey: UserDefaultsKeys.hasCompletedWelcome)
        }
    }

    /// Indicates whether the user has completed the onboarding tutorial
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: UserDefaultsKeys.hasCompletedOnboarding)
        }
    }

    // MARK: - Internal Properties

    var launchCount: Int {
        get {
            UserDefaults.standard.integer(forKey: UserDefaultsKeys.appLaunchCount)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.appLaunchCount)
        }
    }

    // MARK: - Initialization

    init() {
        // Load saved state
        self.hasCompletedWelcome = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedWelcome)
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedOnboarding)
    }

    // MARK: - Public Methods

    /// Check if this is the first launch of the app
    /// - Returns: true if this is the first launch, false otherwise
    func checkFirstLaunch() -> Bool {
        return launchCount == 0
    }

    /// Increment the launch count and record the launch date
    /// Should be called on every app launch
    func incrementLaunchCount() {
        launchCount += 1
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastLaunchDate)
    }

    /// Mark the welcome flow as complete
    /// Persists the completion state to UserDefaults
    func markWelcomeComplete() {
        hasCompletedWelcome = true
    }

    /// Mark the onboarding tutorial as complete
    /// Persists the completion state to UserDefaults
    func markOnboardingComplete() {
        hasCompletedOnboarding = true
    }

    /// Reset onboarding state (for replay tutorial)
    /// Does not affect welcome or launch count
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    /// Reset all launch state (for testing or complete reset)
    func resetLaunchState() {
        hasCompletedWelcome = false
        hasCompletedOnboarding = false
        launchCount = 0
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastLaunchDate)
    }

    /// Get the date of the last app launch
    /// - Returns: Date of last launch, or nil if never launched
    func lastLaunchDate() -> Date? {
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.lastLaunchDate) as? Date
    }
}

// MARK: - UserDefaults Keys

/// Constants for UserDefaults keys used by LaunchStateManager
private enum UserDefaultsKeys {
    static let hasCompletedWelcome = "com.neuroguide.hasCompletedWelcome"
    static let hasCompletedOnboarding = "com.neuroguide.hasCompletedOnboarding"
    static let appLaunchCount = "com.neuroguide.appLaunchCount"
    static let lastLaunchDate = "com.neuroguide.lastLaunchDate"
}
