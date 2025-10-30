//
//  NavigationFlowUITests.swift
//  NeuroGuideUITests
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import XCTest

/// UI tests for navigation flows
/// Tests welcome → home flow and feature card interactions
final class NavigationFlowUITests: XCTestCase {

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

    // MARK: - First Launch Flow Tests

    func testFirstLaunch_ShowsWelcomeScreen() {
        // Given: First launch (reset state)
        app.launchArguments.append("--reset-state")
        app.launch()

        // Then: Welcome screen should appear
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 2),
                      "Welcome title should be visible on first launch")
        XCTAssertTrue(app.buttons["Get Started"].exists,
                      "Get Started button should be visible")
    }

    func testWelcomeScreen_DisplaysContent() {
        // Given: Welcome screen
        app.launchArguments.append("--reset-state")
        app.launch()

        // Then: All welcome content should be visible
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].exists,
                      "Welcome title should be visible")
        XCTAssertTrue(app.staticTexts["Supporting parents on their journey"].exists,
                      "Welcome subtitle should be visible")
        XCTAssertTrue(app.staticTexts["Compassionate, neurodiversity-affirming guidance for those challenging moments"].exists,
                      "Welcome description should be visible")
        XCTAssertTrue(app.buttons["Get Started"].exists,
                      "Get Started button should be visible")
        XCTAssertTrue(app.buttons["Learn More"].exists,
                      "Learn More button should be visible")
    }

    func testWelcomeToHomeNavigation() {
        // Given: Welcome screen
        app.launchArguments.append("--reset-state")
        app.launch()
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 2))

        // When: Tap Get Started
        app.buttons["Get Started"].tap()

        // Then: Home screen should appear
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 3),
                      "Home screen greeting should be visible")
        XCTAssertTrue(app.buttons["Live Coach"].exists,
                      "Live Coach feature card should be visible")
    }

    // MARK: - Returning User Tests

    func testReturningUser_ShowsHomeDirectly() {
        // Given: Returning user (welcome completed)
        app.launchArguments.append("--returning-user")
        app.launch()

        // Then: Home screen should appear directly (no welcome)
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 2),
                      "Home screen should appear directly for returning users")

        // Welcome screen should not be visible
        XCTAssertFalse(app.staticTexts["Welcome to NeuroGuide"].exists,
                       "Welcome screen should not appear for returning users")
    }

    // MARK: - Home Screen Tests

    func testHomeScreen_ShowsAllFeatureCards() {
        // Given: Home screen (returning user)
        app.launchArguments.append("--returning-user")
        app.launch()

        // Then: All 4 feature cards should be visible
        XCTAssertTrue(app.buttons["Live Coach"].waitForExistence(timeout: 2),
                      "Live Coach feature card should be visible")
        XCTAssertTrue(app.buttons["Emotion Check"].exists,
                      "Emotion Check feature card should be visible")
        XCTAssertTrue(app.buttons["Ask NeuroGuide"].exists,
                      "Ask NeuroGuide feature card should be visible")
        XCTAssertTrue(app.buttons["Child Profile"].exists,
                      "Child Profile feature card should be visible")
    }

    func testHomeScreen_ShowsEmergencyAccessButton() {
        // Given: Home screen
        app.launchArguments.append("--returning-user")
        app.launch()

        // Then: Emergency access button should be visible
        XCTAssertTrue(app.staticTexts["Need Help Now?"].waitForExistence(timeout: 2),
                      "Emergency access button should be visible")
    }

    func testHomeScreen_ShowsSettingsButton() {
        // Given: Home screen
        app.launchArguments.append("--returning-user")
        app.launch()

        // Then: Settings button should be visible in navigation bar
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 2),
                      "Settings button should be visible")
    }

    // MARK: - Feature Card Interaction Tests

    func testFeatureCard_LiveCoach_ShowsComingSoonModal() {
        // Given: Home screen with Live Coach card
        app.launchArguments.append("--returning-user")
        app.launch()
        XCTAssertTrue(app.buttons["Live Coach"].waitForExistence(timeout: 2))

        // When: Tap Live Coach card
        app.buttons["Live Coach"].tap()

        // Then: Modal should appear with "Coming soon" message
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2),
                      "Modal title should appear")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Coming soon'")).firstMatch.exists,
                      "Coming soon message should appear")
    }

    func testFeatureCard_EmotionCheck_ShowsComingSoonModal() {
        // Given: Home screen with Emotion Check card
        app.launchArguments.append("--returning-user")
        app.launch()
        XCTAssertTrue(app.buttons["Emotion Check"].waitForExistence(timeout: 2))

        // When: Tap Emotion Check card
        app.buttons["Emotion Check"].tap()

        // Then: Modal should appear
        XCTAssertTrue(app.staticTexts["Emotion Check"].waitForExistence(timeout: 2))
    }

    // MARK: - Emergency Access Tests

    func testEmergencyAccessButton_ShowsModal() {
        // Given: Home screen with emergency access button
        app.launchArguments.append("--returning-user")
        app.launch()

        // When: Tap emergency access button
        let emergencyButton = app.staticTexts["Need Help Now?"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 2))
        emergencyButton.tap()

        // Then: Emergency modal should appear
        XCTAssertTrue(app.staticTexts["Emergency Resources"].waitForExistence(timeout: 2),
                      "Emergency modal should appear")
    }

    // MARK: - Settings Navigation Tests

    func testNavigateToSettings() {
        // Given: Home screen
        app.launchArguments.append("--returning-user")
        app.launch()

        // When: Tap settings button
        app.buttons["Settings"].tap()

        // Then: Settings screen should appear
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 2),
                      "Settings screen should appear")
        XCTAssertTrue(app.staticTexts["App Settings"].exists,
                      "Settings sections should be visible")
    }

    func testNavigateFromSettingsToHome() {
        // Given: Settings screen
        app.launchArguments.append("--returning-user")
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 2))

        // When: Tap Done button
        app.buttons["Done"].tap()

        // Then: Should return to home screen
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 2),
                      "Should return to home screen")
    }

    // MARK: - Modal Interaction Tests

    func testModal_DismissWithOKButton() {
        // Given: Home screen with modal displayed
        app.launchArguments.append("--returning-user")
        app.launch()
        app.buttons["Live Coach"].tap()
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2))

        // When: Tap OK button
        app.buttons["OK"].tap()

        // Then: Modal should dismiss and home screen should be visible
        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.waitForExistence(timeout: 2),
                      "Should return to home screen after dismissing modal")
    }

    func testModal_DismissWithCloseButton() {
        // Given: Home screen with modal displayed
        app.launchArguments.append("--returning-user")
        app.launch()
        app.buttons["Live Coach"].tap()
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2))

        // When: Tap close button (X)
        app.buttons["Close"].tap()

        // Then: Modal should dismiss
        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.waitForExistence(timeout: 2),
                      "Should return to home screen after closing modal")
    }

    // MARK: - Complete User Journey Tests

    func testCompleteUserJourney_FirstLaunchToFeatureInteraction() {
        // Given: First launch
        app.launchArguments.append("--reset-state")
        app.launch()

        // When: Complete welcome flow
        XCTAssertTrue(app.staticTexts["Welcome to NeuroGuide"].waitForExistence(timeout: 2))
        app.buttons["Get Started"].tap()

        // And: Interact with feature card
        XCTAssertTrue(app.buttons["Live Coach"].waitForExistence(timeout: 3))
        app.buttons["Live Coach"].tap()

        // Then: Modal should appear
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2))

        // And: Dismiss modal
        app.buttons["OK"].tap()

        // And: Navigate to settings
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 2))

        // And: Return to home
        app.buttons["Done"].tap()

        // Then: Home screen should be visible
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 2))
    }
}
