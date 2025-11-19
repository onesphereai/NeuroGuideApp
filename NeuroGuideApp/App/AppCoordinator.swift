//
//  AppCoordinator.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import Foundation
import SwiftUI
import Combine

/// Root coordinator managing app-wide navigation and state
/// Coordinates between LaunchStateManager, NavigationState, and NavigationService
class AppCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// The navigation state for the entire app
    @Published var navigationState: NavigationState

    /// The launch state manager
    @Published var launchStateManager: LaunchStateManager

    // MARK: - Private Properties

    /// Navigation service for handling navigation logic
    private var navigationService: NavigationService

    /// Cancellable subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Initialize launch state manager first
        let tempLaunchStateManager = LaunchStateManager()

        // Use the shared NavigationState singleton
        let sharedNavigationState = NavigationState.shared

        // Determine starting screen based on launch state
        let startingScreen: Screen
        if tempLaunchStateManager.checkFirstLaunch() || !tempLaunchStateManager.hasCompletedWelcome {
            startingScreen = .welcome
        } else {
            // Navigate to profile selection instead of directly to home
            startingScreen = .profileSelection
        }

        // Set the starting screen on the singleton
        sharedNavigationState.reset(to: startingScreen)

        // Initialize all stored properties before using self
        self.launchStateManager = tempLaunchStateManager
        self.navigationState = sharedNavigationState
        self.navigationService = DefaultNavigationService(navigationState: sharedNavigationState)

        // Now we can safely use self - increment launch count
        self.launchStateManager.incrementLaunchCount()
    }

    // MARK: - Public Methods

    /// Start the app coordinator
    /// Sets up any necessary subscriptions or initializations
    func start() {
        // Post screen changed notification for VoiceOver
        AccessibilityHelper.screenChanged()

        // Log first launch for debugging
        if launchStateManager.checkFirstLaunch() {
            print("NeuroGuide: First launch detected")
        } else {
            print("NeuroGuide: Returning user (launch #\(launchStateManager.launchCount))")
        }
    }

    /// Navigate to a specific screen
    /// - Parameter screen: The destination screen
    func navigate(to screen: Screen) {
        navigationService.navigate(to: screen)

        // Trigger haptic feedback for navigation
        AccessibilityHelper.shared.selection()

        // Post screen changed notification for VoiceOver
        AccessibilityHelper.screenChanged()
    }

    /// Present a modal view
    /// - Parameter modal: The modal to present
    func presentModal(_ modal: Modal) {
        navigationService.presentModal(modal)

        // Trigger haptic feedback
        AccessibilityHelper.shared.buttonTap()
    }

    /// Dismiss the current modal
    func dismissModal() {
        navigationService.dismissModal()

        // Trigger haptic feedback
        AccessibilityHelper.shared.buttonTap()
    }

    /// Navigate back to previous screen
    func navigateBack() {
        if navigationState.canNavigateBack() {
            _ = navigationState.pop()

            // Trigger haptic feedback
            AccessibilityHelper.shared.selection()

            // Post screen changed notification for VoiceOver
            AccessibilityHelper.screenChanged()
        }
    }

    /// Complete the welcome flow and check if onboarding is needed
    func completeWelcome() {
        launchStateManager.markWelcomeComplete()

        // Trigger success haptic
        AccessibilityHelper.shared.success()

        // Check if onboarding has been completed
        if !launchStateManager.hasCompletedOnboarding {
            // Show onboarding
            showOnboarding()
        } else {
            // Go to profile selection
            navigate(to: .profileSelection)
            AccessibilityHelper.announce("Welcome back to attune.")
        }
    }

    /// Show the onboarding tutorial
    func showOnboarding() {
        // For now, we'll use modal presentation
        // In production, this would be integrated into NavigationState
        presentModal(.onboarding)

        // Announce to VoiceOver
        AccessibilityHelper.announce("Starting tutorial")
    }

    /// Complete the onboarding tutorial and navigate to profile selection
    func completeOnboarding() {
        launchStateManager.markOnboardingComplete()

        // Dismiss onboarding modal
        dismissModal()

        // Navigate to profile selection
        navigate(to: .profileSelection)

        // Trigger success haptic
        AccessibilityHelper.shared.success()

        // Announce completion to VoiceOver
        AccessibilityHelper.announce("Tutorial complete. Let's create your first profile.")
    }

    /// Replay the onboarding tutorial (from Settings)
    func replayOnboarding() {
        // Reset onboarding state temporarily
        launchStateManager.resetOnboarding()

        // Show onboarding
        showOnboarding()

        // Announce to VoiceOver
        AccessibilityHelper.announce("Replaying tutorial")
    }

    /// Handle feature card tap
    /// - Parameter feature: The feature that was tapped
    func handleFeatureTap(_ feature: FeatureCard) {
        // Trigger haptic feedback
        AccessibilityHelper.shared.buttonTap()

        switch feature.id {
        case "live_coach":
            // Navigate to Live Coach screen
            navigate(to: .liveCoach)
            AccessibilityHelper.announce("Opening Live Coach")
        case "emotion_check":
            presentModal(.info(
                title: "Emotion Check",
                content: "Check in with your emotions and your child's with personalized emotion cards. Coming soon!"
            ))
        case "ask_question":
            // Navigate to Ask NeuroGuide screen
            navigate(to: .askQuestion)
            AccessibilityHelper.announce("Opening Ask attune")
        case "profile":
            // Show profile creation wizard
            presentModal(.profileCreation)
        case "session_history":
            // Navigate to Session History screen
            navigate(to: .sessionHistory)
            AccessibilityHelper.announce("Opening Session History")
        case "model_training":
            // Navigate to Model Training screen
            navigate(to: .trainingLibrary)
            AccessibilityHelper.announce("Opening Model Training")
        default:
            break
        }
    }

    /// Navigate to settings
    func navigateToSettings() {
        navigate(to: .settings)
    }

    /// Navigate to profile selection
    func navigateToProfileSelection() {
        navigate(to: .profileSelection)
        AccessibilityHelper.announce("Profile selection")
    }

    /// Navigate to profile creation
    func navigateToProfileCreation() {
        presentModal(.profileCreation)
        AccessibilityHelper.announce("Create new profile")
    }

    /// Handle emergency access button tap
    func handleEmergencyAccess() {
        // Trigger haptic feedback
        AccessibilityHelper.shared.buttonTap()

        // Bolt 1.3: Show emergency resources modal
        presentModal(.emergencyResources)

        // Announce to VoiceOver
        AccessibilityHelper.announce("Opening emergency resources")
    }

    /// Show profile detail view
    /// - Parameter profile: The profile to display
    func showProfileDetail(profile: ChildProfile) {
        presentModal(.profileDetail(profile: profile))

        // Announce to VoiceOver
        AccessibilityHelper.announce("Opening profile for \(profile.displayName)")
    }
}

// MARK: - FeatureCard Model

/// Represents a feature card on the home screen
struct FeatureCard: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let color: String  // Color name from Assets
    let isAvailable: Bool  // For Bolt 1.1, most features are not yet available

    static let liveCoach = FeatureCard(
        id: "live_coach",
        title: "Live Coach",
        description: "Real-time support for challenging moments",
        iconName: "figure.walk",
        color: "Primary",
        isAvailable: true
    )

    static let emotionCheck = FeatureCard(
        id: "emotion_check",
        title: "Emotion Check",
        description: "Personalized emotion awareness",
        iconName: "heart.circle",
        color: "Secondary",
        isAvailable: false
    )

    static let askQuestion = FeatureCard(
        id: "ask_question",
        title: "Ask attune",
        description: "Evidence-based guidance",
        iconName: "questionmark.circle",
        color: "Primary",
        isAvailable: true
    )

    static let profile = FeatureCard(
        id: "profile",
        title: "Child Profile",
        description: "Personalize for your child",
        iconName: "person.circle",
        color: "Secondary",
        isAvailable: true
    )

    static let sessionHistory = FeatureCard(
        id: "session_history",
        title: "Session History",
        description: "View past coaching sessions",
        iconName: "clock.arrow.circlepath",
        color: "Primary",
        isAvailable: true
    )

    static let modelTraining = FeatureCard(
        id: "model_training",
        title: "Model Training",
        description: "Train personalized AI models",
        iconName: "sparkles.rectangle.stack.fill",
        color: "Secondary",
        isAvailable: true
    )

    static let allFeatures: [FeatureCard] = [
        .liveCoach,
        // .emotionCheck,  // Hidden per user request
        .askQuestion,
        // .profile,  // Hidden per user request
        .sessionHistory
        // .modelTraining  // Hidden per user request
    ]
}
