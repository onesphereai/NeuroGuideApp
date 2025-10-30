//
//  WelcomeViewModel.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import Foundation
import Combine

/// View model for the welcome screen
/// Handles welcome completion logic
class WelcomeViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Indicates whether the welcome animation has completed
    @Published var hasAnimationCompleted: Bool = false

    /// Indicates whether the get started button should be enabled
    @Published var isGetStartedEnabled: Bool = false

    // MARK: - Internal Properties

    /// Reference to app coordinator for navigation
    weak var coordinator: AppCoordinator?

    /// Cancellable subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initialize with coordinator for navigation
    /// - Parameter coordinator: The app coordinator
    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator

        // Enable get started button after a brief delay to prevent accidental taps
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isGetStartedEnabled = true
            self?.hasAnimationCompleted = true
        }
    }

    // MARK: - Public Methods

    /// Handle the completion of the welcome flow
    /// Marks welcome as complete and navigates to home
    func completeWelcome() {
        // Trigger haptic feedback
        AccessibilityHelper.shared.success()

        // Announce to VoiceOver
        AccessibilityHelper.announce("Welcome complete. Navigating to home screen.")

        // Tell coordinator to complete welcome (handles navigation)
        coordinator?.completeWelcome()
    }

    /// Handle skip welcome action (if user wants to skip)
    func skipWelcome() {
        // Same as complete welcome for Bolt 1.1
        // Future Bolts may have different behavior
        completeWelcome()
    }
}
