//
//  NavigationState.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import Foundation
import Combine

/// Observable navigation state for the entire app
/// Manages current screen and modal presentation state
class NavigationState: ObservableObject {

    // MARK: - Singleton

    static let shared = NavigationState()

    // MARK: - Published Properties

    /// The currently displayed screen
    @Published var currentScreen: Screen

    /// Optional modal currently being presented
    @Published var presentedModal: Modal?

    /// Navigation history for back navigation (future implementation)
    @Published var navigationHistory: [Screen] = []

    // MARK: - Initialization

    /// Initialize with a starting screen
    /// - Parameter startScreen: The initial screen to display (default: .welcome)
    private init(startScreen: Screen = .welcome) {
        self.currentScreen = startScreen
        self.presentedModal = nil
        self.navigationHistory = [startScreen]
    }

    // MARK: - Public Methods

    /// Push a new screen onto the navigation history
    /// Updates currentScreen and adds to history
    /// - Parameter screen: The screen to navigate to
    func push(_ screen: Screen) {
        navigationHistory.append(screen)
        currentScreen = screen
    }

    /// Pop the current screen from navigation history
    /// Returns to the previous screen if available
    /// - Returns: true if successfully popped, false if already at root
    @discardableResult
    func pop() -> Bool {
        guard navigationHistory.count > 1 else {
            return false
        }

        navigationHistory.removeLast()
        if let previousScreen = navigationHistory.last {
            currentScreen = previousScreen
            return true
        }

        return false
    }

    /// Pop to root screen (first screen in history)
    func popToRoot() {
        guard let rootScreen = navigationHistory.first else {
            return
        }

        navigationHistory = [rootScreen]
        currentScreen = rootScreen
    }

    /// Reset navigation to a specific screen
    /// Clears history and starts fresh
    /// - Parameter screen: The screen to reset to
    func reset(to screen: Screen) {
        navigationHistory = [screen]
        currentScreen = screen
        presentedModal = nil
    }

    /// Check if we can navigate back
    /// - Returns: true if there's a previous screen in history
    func canNavigateBack() -> Bool {
        return navigationHistory.count > 1
    }
}
