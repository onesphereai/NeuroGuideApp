//
//  HomeViewModel.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import Foundation
import Combine

/// View model for the home screen
/// Manages feature cards and home screen state
@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    /// List of feature cards to display
    @Published var features: [FeatureCard]

    /// Greeting message for the user
    @Published var greetingMessage: String

    /// Indicates whether profile summary should be shown
    @Published var shouldShowProfileSummary: Bool = false

    /// Current child profile (if exists)
    @Published var currentProfile: ChildProfile?

    // MARK: - Internal Properties

    /// Reference to app coordinator for navigation
    weak var coordinator: AppCoordinator?

    /// Profile manager for loading profile
    private let profileManager = ChildProfileManager.shared

    // MARK: - Initialization

    /// Initialize with coordinator
    /// - Parameter coordinator: The app coordinator
    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator
        self.features = FeatureCard.allFeatures
        self.greetingMessage = HomeViewModel.generateGreeting()
        // Load initial profile state from cache
        self.currentProfile = profileManager.currentProfile
        self.shouldShowProfileSummary = profileManager.currentProfile != nil
    }

    // MARK: - Public Methods

    /// Handle feature card tap
    /// - Parameter feature: The feature card that was tapped
    func handleFeatureTap(_ feature: FeatureCard) {
        coordinator?.handleFeatureTap(feature)
    }

    /// Navigate to settings
    func navigateToSettings() {
        coordinator?.navigateToSettings()
    }

    /// Handle emergency access button tap
    func handleEmergencyAccess() {
        coordinator?.handleEmergencyAccess()
    }

    /// Switch to a different profile
    func switchProfile() {
        coordinator?.navigateToProfileSelection()
    }

    /// Refresh the home screen content
    func refresh() async {
        // Update greeting in case time of day changed
        greetingMessage = HomeViewModel.generateGreeting()

        // Reload profile
        await loadProfile()
    }

    /// Load the current profile
    func loadProfile() async {
        do {
            if let profile = try await profileManager.getProfile() {
                currentProfile = profile
                shouldShowProfileSummary = true
            } else {
                currentProfile = nil
                shouldShowProfileSummary = false
            }
        } catch {
            print("Error loading profile: \(error)")
            currentProfile = nil
            shouldShowProfileSummary = false
        }
    }

    // MARK: - Private Methods

    /// Generate time-based greeting message
    /// - Returns: Greeting string based on time of day
    private static func generateGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "Hello"
        }
    }
}
