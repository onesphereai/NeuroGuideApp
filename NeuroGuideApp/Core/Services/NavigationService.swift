//
//  NavigationService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import Foundation

/// Protocol defining navigation capabilities
/// Allows for testable navigation logic
protocol NavigationService {
    /// Navigate to a specific screen
    /// - Parameter screen: The destination screen
    func navigate(to screen: Screen)

    /// Present a modal view
    /// - Parameter modal: The modal to present
    func presentModal(_ modal: Modal)

    /// Dismiss the current modal
    func dismissModal()

    /// Navigate back to previous screen (if applicable)
    func navigateBack()
}

// MARK: - Screen Enum

/// Represents the main screens in the app
enum Screen: Equatable {
    case welcome
    case home
    case settings
    case liveCoach  // Placeholder for future Bolt
    case emotionCheck  // Placeholder for future Bolt
    case askQuestion  // Placeholder for future Bolt
    case profile  // Placeholder for future Bolt
}

// MARK: - Modal Enum

/// Represents modal views that can be presented
enum Modal: Identifiable, Equatable {
    case alert(title: String, message: String)
    case confirmation(title: String, message: String, action: () -> Void)
    case info(title: String, content: String)
    case onboarding  // Onboarding tutorial (Bolt 1.2)
    case emergencyResources  // Emergency resources (Bolt 1.3)
    case profileCreation  // Profile creation wizard (Unit 3)
    case profileDetail(profile: ChildProfile)  // Profile detail view (Unit 3)

    var id: String {
        switch self {
        case .alert(let title, _):
            return "alert_\(title)"
        case .confirmation(let title, _, _):
            return "confirmation_\(title)"
        case .info(let title, _):
            return "info_\(title)"
        case .onboarding:
            return "onboarding"
        case .emergencyResources:
            return "emergency_resources"
        case .profileCreation:
            return "profile_creation"
        case .profileDetail:
            return "profile_detail"
        }
    }

    static func == (lhs: Modal, rhs: Modal) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Default Implementation

/// Default implementation of NavigationService
/// Used by AppCoordinator to provide navigation capabilities
class DefaultNavigationService: NavigationService {

    // Reference to NavigationState (injected)
    private weak var navigationState: NavigationState?

    init(navigationState: NavigationState) {
        self.navigationState = navigationState
    }

    func navigate(to screen: Screen) {
        navigationState?.currentScreen = screen
    }

    func presentModal(_ modal: Modal) {
        navigationState?.presentedModal = modal
    }

    func dismissModal() {
        navigationState?.presentedModal = nil
    }

    func navigateBack() {
        // For Bolt 1.1, we don't have a navigation stack
        // Future Bolts will implement proper back navigation
        // For now, return to home
        navigate(to: .home)
    }
}
