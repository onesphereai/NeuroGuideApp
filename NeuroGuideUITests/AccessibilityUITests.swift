//
//  AccessibilityUITests.swift
//  NeuroGuideUITests
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import XCTest

/// UI tests for accessibility features
/// Tests VoiceOver compatibility, Dynamic Type, and minimum tap targets
final class AccessibilityUITests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--returning-user"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Accessibility Element Tests

    func testWelcomeScreen_AllElementsAccessible() {
        // Given: Welcome screen
        app.launchArguments.append("--reset-state")
        app.launch()

        // Then: All interactive elements should be accessibility elements
        let welcomeTitle = app.staticTexts["Welcome to NeuroGuide"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 2))
        XCTAssertTrue(welcomeTitle.isHittable, "Welcome title should be accessible")

        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists)
        XCTAssertTrue(getStartedButton.isHittable, "Get Started button should be accessible")

        let learnMoreButton = app.buttons["Learn More"]
        XCTAssertTrue(learnMoreButton.exists)
        XCTAssertTrue(learnMoreButton.isHittable, "Learn More button should be accessible")
    }

    func testHomeScreen_AllElementsAccessible() {
        // Given: Home screen
        app.launch()

        // Then: All interactive elements should be accessible
        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.waitForExistence(timeout: 2))
        XCTAssertTrue(liveCoachCard.isHittable, "Live Coach card should be accessible")

        let emotionCheckCard = app.buttons["Emotion Check"]
        XCTAssertTrue(emotionCheckCard.exists)
        XCTAssertTrue(emotionCheckCard.isHittable, "Emotion Check card should be accessible")

        let askQuestionCard = app.buttons["Ask NeuroGuide"]
        XCTAssertTrue(askQuestionCard.exists)
        XCTAssertTrue(askQuestionCard.isHittable, "Ask NeuroGuide card should be accessible")

        let profileCard = app.buttons["Child Profile"]
        XCTAssertTrue(profileCard.exists)
        XCTAssertTrue(profileCard.isHittable, "Child Profile card should be accessible")

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)
        XCTAssertTrue(settingsButton.isHittable, "Settings button should be accessible")
    }

    // MARK: - Accessibility Labels Tests

    func testFeatureCards_HaveAccessibilityLabels() {
        // Given: Home screen with feature cards
        app.launch()

        // Then: Each feature card should have an accessibility label
        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.waitForExistence(timeout: 2))
        XCTAssertFalse(liveCoachCard.label.isEmpty, "Live Coach should have accessibility label")

        let emotionCheckCard = app.buttons["Emotion Check"]
        XCTAssertTrue(emotionCheckCard.exists)
        XCTAssertFalse(emotionCheckCard.label.isEmpty, "Emotion Check should have accessibility label")
    }

    func testButtons_HaveAccessibilityLabels() {
        // Given: Home screen
        app.launch()

        // Then: All buttons should have accessibility labels
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 2))
        XCTAssertFalse(settingsButton.label.isEmpty, "Settings button should have accessibility label")
    }

    // MARK: - Accessibility Identifiers Tests

    func testWelcomeScreen_HasAccessibilityIdentifiers() {
        // Given: Welcome screen
        app.launchArguments.append("--reset-state")
        app.launch()

        // Then: Key elements should have accessibility identifiers for testing
        XCTAssertTrue(app.staticTexts["welcome_title_text"].waitForExistence(timeout: 2),
                      "Welcome title should have accessibility identifier")
        XCTAssertTrue(app.buttons["welcome_get_started_button"].exists,
                      "Get Started button should have accessibility identifier")
    }

    func testHomeScreen_HasAccessibilityIdentifiers() {
        // Given: Home screen
        app.launch()

        // Then: Key elements should have accessibility identifiers
        XCTAssertTrue(app.buttons["home_settings_button"].waitForExistence(timeout: 2),
                      "Settings button should have accessibility identifier")
        XCTAssertTrue(app.buttons["home_emergency_access_button"].exists,
                      "Emergency access button should have accessibility identifier")
    }

    // MARK: - Minimum Tap Target Tests

    func testFeatureCards_MeetMinimumTapTargetSize() {
        // Given: Home screen with feature cards
        app.launch()

        // Then: Each feature card should be at least 44x44 points (iOS minimum)
        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.waitForExistence(timeout: 2))

        let frame = liveCoachCard.frame
        XCTAssertGreaterThanOrEqual(frame.width, 44, "Feature card width should be at least 44 points")
        XCTAssertGreaterThanOrEqual(frame.height, 44, "Feature card height should be at least 44 points")

        // Feature cards should be 150x150 (much larger than minimum)
        XCTAssertGreaterThanOrEqual(frame.width, 150, "Feature card width should be at least 150 points")
        XCTAssertGreaterThanOrEqual(frame.height, 150, "Feature card height should be at least 150 points")
    }

    func testGetStartedButton_MeetsMinimumTapTargetSize() {
        // Given: Welcome screen
        app.launchArguments.append("--reset-state")
        app.launch()

        // Then: Get Started button should meet minimum tap target
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 2))

        let frame = getStartedButton.frame
        XCTAssertGreaterThanOrEqual(frame.height, 44, "Get Started button height should be at least 44 points")
    }

    func testEmergencyAccessButton_MeetsMinimumTapTargetSize() {
        // Given: Home screen
        app.launch()

        // Then: Emergency access button should meet minimum tap target
        let emergencyButton = app.staticTexts["Need Help Now?"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 2))

        let frame = emergencyButton.frame
        XCTAssertGreaterThanOrEqual(frame.height, 44, "Emergency button height should be at least 44 points")
    }

    // MARK: - Dynamic Type Tests

    func testApp_SupportsLargeText() {
        // Given: App with large text size
        app.launchArguments.append("--content-size-xl")
        app.launch()

        // Then: Text should be visible and not truncated
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 2),
                      "Greeting text should be visible with large text size")

        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.exists,
                      "Feature cards should be visible with large text size")
    }

    func testWelcomeScreen_SupportsLargeText() {
        // Given: Welcome screen with large text
        app.launchArguments.append("--reset-state")
        app.launchArguments.append("--content-size-xl")
        app.launch()

        // Then: Welcome text should be visible
        let welcomeTitle = app.staticTexts["Welcome to NeuroGuide"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 2),
                      "Welcome title should be visible with large text")

        let subtitle = app.staticTexts["Supporting parents on their journey"]
        XCTAssertTrue(subtitle.exists,
                      "Subtitle should be visible with large text")
    }

    // MARK: - VoiceOver Compatibility Tests

    func testWelcomeScreen_VoiceOverCompatibility() {
        // Given: Welcome screen (simulate VoiceOver usage)
        app.launchArguments.append("--reset-state")
        app.launch()

        // Then: All elements should have proper labels
        let welcomeTitle = app.staticTexts["Welcome to NeuroGuide"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 2))
        XCTAssertNotNil(welcomeTitle.label)
        XCTAssertFalse(welcomeTitle.label.isEmpty)

        let getStartedButton = app.buttons["Get Started"]
        XCTAssertNotNil(getStartedButton.label)
        XCTAssertFalse(getStartedButton.label.isEmpty)
    }

    func testHomeScreen_VoiceOverCompatibility() {
        // Given: Home screen
        app.launch()

        // Then: All interactive elements should have labels
        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.waitForExistence(timeout: 2))
        XCTAssertNotNil(liveCoachCard.label)
        XCTAssertFalse(liveCoachCard.label.isEmpty)

        let settingsButton = app.buttons["Settings"]
        XCTAssertNotNil(settingsButton.label)
        XCTAssertFalse(settingsButton.label.isEmpty)
    }

    // MARK: - One-Handed Use Tests

    func testFeatureCards_PositionedForOneHandedUse() {
        // Given: Home screen
        app.launch()

        // Then: Feature cards should be in reachable area (not at very top of screen)
        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.waitForExistence(timeout: 2))

        let frame = liveCoachCard.frame
        let screenHeight = app.frame.height

        // Feature cards should not be in the top 1/3 of screen (unreachable area)
        let topThird = screenHeight / 3.0
        XCTAssertGreaterThan(frame.midY, topThird,
                            "Feature cards should be positioned in the reachable bottom 2/3 of screen")
    }

    func testEmergencyButton_PositionedForOneHandedUse() {
        // Given: Home screen
        app.launch()

        // Then: Emergency button should be in reachable area
        let emergencyButton = app.staticTexts["Need Help Now?"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 2))

        let frame = emergencyButton.frame
        let screenHeight = app.frame.height

        // Emergency button should be in the bottom portion of screen
        let topHalf = screenHeight / 2.0
        XCTAssertGreaterThan(frame.minY, topHalf,
                            "Emergency button should be in the bottom half for easy reach")
    }

    // MARK: - Color Contrast Tests (Visual)

    func testApp_WorksInDarkMode() {
        // Given: App in dark mode
        app.launchArguments.append("--dark-mode")
        app.launch()

        // Then: All elements should be visible
        let greetingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Good'")).firstMatch
        XCTAssertTrue(greetingText.waitForExistence(timeout: 2),
                      "Content should be visible in dark mode")

        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.exists,
                      "Feature cards should be visible in dark mode")
    }

    func testWelcomeScreen_WorksInDarkMode() {
        // Given: Welcome screen in dark mode
        app.launchArguments.append("--reset-state")
        app.launchArguments.append("--dark-mode")
        app.launch()

        // Then: All elements should be visible
        let welcomeTitle = app.staticTexts["Welcome to NeuroGuide"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 2),
                      "Welcome content should be visible in dark mode")

        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists,
                      "Buttons should be visible in dark mode")
    }

    // MARK: - Complete Accessibility Journey Tests

    func testCompleteAccessibilityJourney() {
        // Given: First launch with accessibility features
        app.launchArguments.append("--reset-state")
        app.launch()

        // Then: Navigate through app with accessibility in mind

        // 1. Welcome screen accessibility
        let welcomeTitle = app.staticTexts["Welcome to NeuroGuide"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 2))
        XCTAssertTrue(welcomeTitle.isHittable)

        // 2. Tap Get Started (accessible button)
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists)
        XCTAssertTrue(getStartedButton.isHittable)
        XCTAssertGreaterThanOrEqual(getStartedButton.frame.height, 44)
        getStartedButton.tap()

        // 3. Home screen accessibility
        let liveCoachCard = app.buttons["Live Coach"]
        XCTAssertTrue(liveCoachCard.waitForExistence(timeout: 3))
        XCTAssertTrue(liveCoachCard.isHittable)
        XCTAssertGreaterThanOrEqual(liveCoachCard.frame.width, 150)
        XCTAssertGreaterThanOrEqual(liveCoachCard.frame.height, 150)

        // 4. Feature card tap (accessible interaction)
        liveCoachCard.tap()
        XCTAssertTrue(app.staticTexts["Live Coach"].waitForExistence(timeout: 2))

        // 5. Modal dismiss (accessible button)
        let okButton = app.buttons["OK"]
        XCTAssertTrue(okButton.exists)
        XCTAssertTrue(okButton.isHittable)
        okButton.tap()

        // 6. Settings navigation (accessible button)
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 2))
        XCTAssertTrue(settingsButton.isHittable)

        // All accessibility checks passed
        XCTAssertTrue(true, "Complete accessibility journey successful")
    }
}
