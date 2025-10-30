//
//  OnboardingViewModel.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.2 - Onboarding & Tutorial
//

import Foundation
import Combine

/// View model for the onboarding tutorial flow
/// Manages page navigation, progress tracking, and completion
class OnboardingViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current page index (0-based)
    @Published var currentPageIndex: Int = 0

    /// All onboarding pages
    @Published var pages: [OnboardingPage]

    // MARK: - Internal Properties

    /// Reference to app coordinator for navigation
    weak var coordinator: AppCoordinator?

    // MARK: - Computed Properties

    /// Whether the user can navigate back
    var canGoBack: Bool {
        return currentPageIndex > 0
    }

    /// Whether the user can navigate forward
    var canGoForward: Bool {
        return currentPageIndex < pages.count - 1
    }

    /// Whether this is the last page
    var isLastPage: Bool {
        return currentPageIndex == pages.count - 1
    }

    /// Progress from 0.0 to 1.0
    var progress: Double {
        guard pages.count > 0 else { return 0.0 }
        return Double(currentPageIndex + 1) / Double(pages.count)
    }

    /// Current page
    var currentPage: OnboardingPage? {
        guard currentPageIndex >= 0 && currentPageIndex < pages.count else {
            return nil
        }
        return pages[currentPageIndex]
    }

    // MARK: - Initialization

    /// Initialize with coordinator
    /// - Parameter coordinator: The app coordinator
    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator
        self.pages = OnboardingPage.allPages
    }

    // MARK: - Public Methods

    /// Navigate to the next page
    func nextPage() {
        guard canGoForward else {
            // Already on last page, complete onboarding
            completeOnboarding()
            return
        }

        // Trigger haptic feedback
        AccessibilityHelper.shared.selection()

        // Move to next page
        currentPageIndex += 1

        // Announce page change to VoiceOver
        if let page = currentPage {
            let announcement = "Page \(currentPageIndex + 1) of \(pages.count). \(page.title)"
            AccessibilityHelper.announce(announcement)
        }
    }

    /// Navigate to the previous page
    func previousPage() {
        guard canGoBack else { return }

        // Trigger haptic feedback
        AccessibilityHelper.shared.selection()

        // Move to previous page
        currentPageIndex -= 1

        // Announce page change to VoiceOver
        if let page = currentPage {
            let announcement = "Page \(currentPageIndex + 1) of \(pages.count). \(page.title)"
            AccessibilityHelper.announce(announcement)
        }
    }

    /// Skip the onboarding tutorial
    func skipOnboarding() {
        // Trigger haptic feedback
        AccessibilityHelper.shared.buttonTap()

        // Announce skip to VoiceOver
        AccessibilityHelper.announce("Tutorial skipped")

        // Mark as complete (skipped counts as completed)
        coordinator?.completeOnboarding()
    }

    /// Complete the onboarding tutorial
    func completeOnboarding() {
        // Trigger success haptic
        AccessibilityHelper.shared.success()

        // Announce completion to VoiceOver
        AccessibilityHelper.announce("Tutorial complete. Welcome to attune")

        // Tell coordinator to complete onboarding
        coordinator?.completeOnboarding()
    }

    /// Navigate directly to a specific page (for testing or manual navigation)
    /// - Parameter index: The page index to navigate to
    func goToPage(_ index: Int) {
        guard index >= 0 && index < pages.count else { return }
        currentPageIndex = index
    }
}
