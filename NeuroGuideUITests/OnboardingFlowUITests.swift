//
//  OnboardingFlowUITests.swift
//  NeuroGuideUITests
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.2 - Onboarding & Tutorial
//

import XCTest

/// UI tests for onboarding tutorial flow
/// Tests page navigation, skip, completion, and replay functionality
final class OnboardingFlowUITests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - First Launch Onboarding Tests

    func testFirstLaunch_ShowsOnboardingAfterWelcome() {
        // Given: First launch (reset state)
        app.launchArguments.append("--reset-state")
        app.launch()

        // When: Complete welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 2))
        app.buttons["Get Started"].tap()

        // Then: Onboarding should appear
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3),
                      "Onboarding welcome page should appear")
        XCTAssertTrue(app.buttons["Skip"].exists,
                      "Skip button should be visible")
        XCTAssertTrue(app.buttons["Next"].exists,
                      "Next button should be visible")
    }

    func testOnboarding_DisplaysFirstPage() {
        // Given: Onboarding screen
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()

        // Then: First page content should be visible
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3),
                      "Onboarding title should be visible")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'compassionate'")).firstMatch.exists,
                      "Onboarding description should be visible")
        XCTAssertTrue(app.buttons["Skip"].exists,
                      "Skip button should be visible")
        XCTAssertTrue(app.buttons["Next"].exists,
                      "Next button should be visible")
    }

    // MARK: - Page Navigation Tests

    func testOnboarding_NavigateToNextPage() {
        // Given: Onboarding first page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3))

        // When: Tap Next button
        app.buttons["Next"].tap()

        // Then: Second page should appear
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2),
                      "Second page title should appear")
        XCTAssertTrue(app.buttons["Back"].exists,
                      "Back button should appear on second page")
    }

    func testOnboarding_NavigateToPreviousPage() {
        // Given: Onboarding second page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2))

        // When: Tap Back button
        app.buttons["Back"].tap()

        // Then: First page should appear again
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 2),
                      "Should return to first page")
        XCTAssertFalse(app.buttons["Back"].exists,
                       "Back button should not exist on first page")
    }

    func testOnboarding_NavigateToAllPages() {
        // Given: Onboarding first page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()

        // When/Then: Navigate through all 5 pages
        // Page 1: Welcome
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // Page 2: Live Coach
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()

        // Page 3: Emotion Interface
        XCTAssertTrue(app.staticTexts["Emotion Check"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()

        // Page 4: Ask NeuroGuide
        XCTAssertTrue(app.staticTexts["Ask NeuroGuide"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()

        // Page 5: Child Profile
        XCTAssertTrue(app.staticTexts["Personalized Support"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Get Started"].exists,
                      "Get Started button should appear on last page")
    }

    func testOnboarding_SwipeNavigation() {
        // Given: Onboarding first page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3))

        // When: Swipe left to next page
        let pageView = app.otherElements.containing(.staticText, identifier: "Welcome to NeuroGuide").firstMatch
        pageView.swipeLeft()

        // Then: Second page should appear
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2),
                      "Should navigate to second page via swipe")
    }

    // MARK: - Progress Indicator Tests

    func testOnboarding_ProgressIndicatorUpdates() {
        // Given: Onboarding first page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()

        // When: Navigate to next page
        app.buttons["Next"].tap()

        // Then: Progress indicator should update (we can't directly test the dots,
        // but we can verify the page changed which would update the progress)
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2))
    }

    // MARK: - Skip Functionality Tests

    func testOnboarding_SkipFromFirstPage() {
        // Given: Onboarding first page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3))

        // When: Tap Skip button
        app.buttons["Skip"].tap()

        // Then: Should navigate to home screen
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 3),
                      "Should skip to home screen")
    }

    func testOnboarding_SkipFromMiddlePage() {
        // Given: Onboarding third page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()
        app.buttons["Next"].tap()
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Emotion Check"].waitForExistence(timeout: 2))

        // When: Tap Skip button
        app.buttons["Skip"].tap()

        // Then: Should navigate to home screen
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 3),
                      "Should skip to home screen from any page")
    }

    // MARK: - Completion Tests

    func testOnboarding_CompleteFromLastPage() {
        // Given: Onboarding last page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()

        // Navigate to last page
        for _ in 0..<4 {
            app.buttons["Next"].tap()
            sleep(1) // Wait for animation
        }

        XCTAssertTrue(app.staticTexts["Personalized Support"].waitForExistence(timeout: 2))

        // When: Tap Get Started button
        app.buttons["Get Started"].tap()

        // Then: Should navigate to home screen
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 3),
                      "Should complete onboarding and go to home screen")
    }

    func testOnboarding_GetStartedButtonOnlyAppearsOnLastPage() {
        // Given: Onboarding first page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()

        // Then: Get Started button should not exist (only Next)
        XCTAssertFalse(app.buttons["Get Started"].exists,
                       "Get Started button should not appear on first page")
        XCTAssertTrue(app.buttons["Next"].exists,
                      "Next button should appear on first page")
    }

    // MARK: - Replay Tutorial Tests

    func testReplayTutorial_FromSettings() {
        // Given: Home screen (completed onboarding)
        app.launchArguments.append("--returning-user")
        app.launch()

        // When: Navigate to settings
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 2))

        // And: Tap Replay Tutorial button
        app.buttons["Replay Tutorial"].tap()

        // Then: Onboarding should appear again
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3),
                      "Onboarding should appear when replaying tutorial")
        XCTAssertTrue(app.buttons["Skip"].exists,
                      "Skip button should be visible in replayed tutorial")
    }

    func testReplayTutorial_CanBeCompletedAgain() {
        // Given: Replayed tutorial
        app.launchArguments.append("--returning-user")
        app.launch()
        app.buttons["Settings"].tap()
        app.buttons["Replay Tutorial"].tap()
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3))

        // When: Complete tutorial again
        for _ in 0..<4 {
            app.buttons["Next"].tap()
            sleep(1)
        }
        app.buttons["Get Started"].tap()

        // Then: Should return to home screen
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 3),
                      "Should complete replayed tutorial and return to home")
    }

    func testReplayTutorial_CanBeSkipped() {
        // Given: Replayed tutorial
        app.launchArguments.append("--returning-user")
        app.launch()
        app.buttons["Settings"].tap()
        app.buttons["Replay Tutorial"].tap()
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3))

        // When: Skip tutorial
        app.buttons["Skip"].tap()

        // Then: Should return to home screen
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 3),
                      "Should skip replayed tutorial and return to home")
    }

    // MARK: - Complete User Journey Tests

    func testCompleteOnboardingJourney_FirstLaunchToHome() {
        // Given: First launch
        app.launchArguments.append("--reset-state")
        app.launch()

        // When: Complete welcome
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 2))
        app.buttons["Get Started"].tap()

        // And: Complete onboarding
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 3))

        for _ in 0..<4 {
            app.buttons["Next"].tap()
            sleep(1)
        }

        app.buttons["Get Started"].tap()

        // Then: Should arrive at home screen
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 3),
                      "Should complete full onboarding journey")

        // And: All feature cards should be visible
        XCTAssertTrue(app.buttons["Live Coach"].exists,
                      "Feature cards should be visible after onboarding")
    }

    func testReturningUser_NoOnboarding() {
        // Given: Returning user (onboarding completed)
        app.launchArguments.append("--returning-user-with-onboarding")
        app.launch()

        // Then: Home screen should appear directly
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 2),
                      "Returning user should see home screen directly")

        // And: Onboarding should not appear
        XCTAssertFalse(app.buttons["Skip"].exists,
                       "Onboarding Skip button should not appear for returning users")
    }

    // MARK: - Accessibility Tests

    func testOnboarding_SkipButtonAccessibility() {
        // Given: Onboarding first page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()

        // Then: Skip button should have accessibility label
        let skipButton = app.buttons["Skip tutorial"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 3),
                      "Skip button should have proper accessibility label")
    }

    func testOnboarding_NavigationButtonsAccessibility() {
        // Given: Onboarding second page
        app.launchArguments.append("--reset-state")
        app.launch()
        app.buttons["Get Started"].tap()
        app.buttons["Next"].tap()

        // Then: Navigation buttons should have accessibility labels
        XCTAssertTrue(app.buttons["Previous page"].exists,
                      "Back button should have accessibility label")
        XCTAssertTrue(app.buttons["Next page"].exists,
                      "Next button should have accessibility label")
    }
}
