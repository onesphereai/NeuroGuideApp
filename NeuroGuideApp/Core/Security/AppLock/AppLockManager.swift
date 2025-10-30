//
//  AppLockManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation
import SwiftUI
import Combine

/// Manages app-wide biometric lock functionality
@MainActor
class AppLockManager: ObservableObject {

    // MARK: - Singleton

    static let shared = AppLockManager()

    // MARK: - Published Properties

    @Published var isLocked: Bool = false
    @Published var showLockScreen: Bool = false

    // MARK: - Properties

    private let biometricAuth: BiometricAuthService
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTime: Date?

    private let lockTimeoutSeconds: TimeInterval = 30 // Lock after 30 seconds in background

    // MARK: - Initialization

    init(biometricAuth: BiometricAuthService = BiometricAuthManager.shared) {
        self.biometricAuth = biometricAuth
        setupAppLifecycleObservers()
    }

    // MARK: - Lifecycle Observers

    private func setupAppLifecycleObservers() {
        // Observe app entering background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)

        // Observe app entering foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)

        // Observe app becoming active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
    }

    // MARK: - Lock Management

    func lockApp() {
        isLocked = true
        showLockScreen = true
        print("🔒 App locked")
    }

    func unlockApp() {
        isLocked = false
        showLockScreen = false
        backgroundTime = nil
        print("🔓 App unlocked")
    }

    func attemptUnlock() async {
        guard biometricAuth.isEnabled() else {
            // Biometric not enabled, unlock immediately
            unlockApp()
            return
        }

        guard biometricAuth.isBiometricAvailable() else {
            // Biometric not available, unlock immediately
            unlockApp()
            return
        }

        do {
            let success = try await biometricAuth.authenticate(
                reason: "Unlock NeuroGuide to continue"
            )

            if success {
                unlockApp()
            } else {
                print("⚠️ Biometric authentication failed")
            }
        } catch {
            print("❌ Biometric authentication error: \(error.localizedDescription)")
            // On error, unlock anyway (don't lock user out)
            unlockApp()
        }
    }

    // MARK: - Lifecycle Handlers

    private func handleAppDidEnterBackground() {
        // Record time when app entered background
        backgroundTime = Date()
        print("💤 App entered background at \(backgroundTime!)")
    }

    private func handleAppWillEnterForeground() {
        // Check if enough time has passed to require lock
        guard biometricAuth.isEnabled() else {
            return
        }

        if let backgroundTime = backgroundTime {
            let elapsedTime = Date().timeIntervalSince(backgroundTime)
            if elapsedTime > lockTimeoutSeconds {
                lockApp()
                print("🔒 App locked after \(elapsedTime)s in background")
            } else {
                print("⏱️ App returned within \(elapsedTime)s, no lock needed")
            }
        }
    }

    private func handleAppDidBecomeActive() {
        // This is called after willEnterForeground
        // Prompt for unlock if locked
        if isLocked {
            Task {
                await attemptUnlock()
            }
        }
    }

    // MARK: - Settings

    func isBiometricEnabled() -> Bool {
        return biometricAuth.isEnabled()
    }

    func setBiometricEnabled(_ enabled: Bool) throws {
        try biometricAuth.setEnabled(enabled)

        if !enabled {
            // If disabling, unlock immediately
            unlockApp()
        }
    }

    func getBiometricType() -> BiometricType {
        return biometricAuth.biometricType()
    }

    func canUseBiometric() -> Bool {
        return biometricAuth.isBiometricAvailable()
    }
}

// MARK: - Launch Handling

extension AppLockManager {
    /// Check if app should be locked on launch
    func checkLockOnLaunch() async {
        guard biometricAuth.isEnabled() else {
            return
        }

        // Lock app on launch if biometric is enabled
        lockApp()
        await attemptUnlock()
    }
}
