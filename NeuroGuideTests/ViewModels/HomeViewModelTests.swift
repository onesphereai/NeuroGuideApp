//
//  HomeViewModelTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import XCTest
import Combine
@testable import NeuroGuideApp

/// Unit tests for HomeViewModel
/// Tests feature card handling, navigation, and state management
final class HomeViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: HomeViewModel!
    var mockCoordinator: ExtendedMockAppCoordinator!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockCoordinator = ExtendedMockAppCoordinator()
        sut = HomeViewModel(coordinator: mockCoordinator)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockCoordinator = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_LoadsAllFeatures() {
        // Given: Fresh HomeViewModel
        // When: Initialized

        // Then: All 4 feature cards should be loaded
        XCTAssertEqual(sut.features.count, 4, "Should load all 4 feature cards")

        let featureIds = sut.features.map { $0.id }
        XCTAssertTrue(featureIds.contains("live_coach"), "Should include Live Coach")
        XCTAssertTrue(featureIds.contains("emotion_check"), "Should include Emotion Check")
        XCTAssertTrue(featureIds.contains("ask_question"), "Should include Ask Question")
        XCTAssertTrue(featureIds.contains("profile"), "Should include Profile")
    }

    func testInit_GeneratesGreetingMessage() {
        // Given: Fresh HomeViewModel
        // When: Initialized

        // Then: Greeting message should be set
        XCTAssertFalse(sut.greetingMessage.isEmpty, "Greeting message should not be empty")

        // Verify it's one of the expected greetings
        let validGreetings = ["Good Morning", "Good Afternoon", "Good Evening", "Hello"]
        XCTAssertTrue(validGreetings.contains(sut.greetingMessage), "Greeting should be one of the valid time-based greetings")
    }

    func testInit_ProfileSummaryNotShownForBolt1_1() {
        // Given: Fresh HomeViewModel
        // When: Initialized

        // Then: Profile summary should not be shown (stub for Bolt 1.1)
        XCTAssertFalse(sut.shouldShowProfileSummary, "Profile summary should not be shown in Bolt 1.1")
    }

    // MARK: - Feature Card Tap Tests

    func testHandleFeatureTap_LiveCoach_CallsCoordinator() {
        // Given: HomeViewModel with Live Coach feature
        let liveCoachFeature = FeatureCard.liveCoach

        // When: User taps Live Coach feature card
        sut.handleFeatureTap(liveCoachFeature)

        // Then: Coordinator is notified
        XCTAssertTrue(mockCoordinator.didCallHandleFeatureTap, "Coordinator should be notified of feature tap")
        XCTAssertEqual(mockCoordinator.lastTappedFeature?.id, "live_coach")
    }

    func testHandleFeatureTap_EmotionCheck_CallsCoordinator() {
        // Given: HomeViewModel with Emotion Check feature
        let emotionCheckFeature = FeatureCard.emotionCheck

        // When: User taps Emotion Check feature card
        sut.handleFeatureTap(emotionCheckFeature)

        // Then: Coordinator is notified
        XCTAssertTrue(mockCoordinator.didCallHandleFeatureTap)
        XCTAssertEqual(mockCoordinator.lastTappedFeature?.id, "emotion_check")
    }

    func testHandleFeatureTap_AskQuestion_CallsCoordinator() {
        // Given: HomeViewModel with Ask Question feature
        let askQuestionFeature = FeatureCard.askQuestion

        // When: User taps Ask Question feature card
        sut.handleFeatureTap(askQuestionFeature)

        // Then: Coordinator is notified
        XCTAssertTrue(mockCoordinator.didCallHandleFeatureTap)
        XCTAssertEqual(mockCoordinator.lastTappedFeature?.id, "ask_question")
    }

    func testHandleFeatureTap_Profile_CallsCoordinator() {
        // Given: HomeViewModel with Profile feature
        let profileFeature = FeatureCard.profile

        // When: User taps Profile feature card
        sut.handleFeatureTap(profileFeature)

        // Then: Coordinator is notified
        XCTAssertTrue(mockCoordinator.didCallHandleFeatureTap)
        XCTAssertEqual(mockCoordinator.lastTappedFeature?.id, "profile")
    }

    // MARK: - Navigation Tests

    func testNavigateToSettings_CallsCoordinator() {
        // Given: HomeViewModel

        // When: User navigates to settings
        sut.navigateToSettings()

        // Then: Coordinator is notified
        XCTAssertTrue(mockCoordinator.didCallNavigateToSettings, "Coordinator should be notified to navigate to settings")
    }

    // MARK: - Emergency Access Tests

    func testHandleEmergencyAccess_CallsCoordinator() {
        // Given: HomeViewModel

        // When: User taps emergency access button
        sut.handleEmergencyAccess()

        // Then: Coordinator is notified
        XCTAssertTrue(mockCoordinator.didCallHandleEmergencyAccess, "Coordinator should be notified of emergency access")
    }

    // MARK: - Refresh Tests

    func testRefresh_UpdatesGreeting() {
        // Given: HomeViewModel with initial greeting
        let initialGreeting = sut.greetingMessage

        // When: Refresh is called
        sut.refresh()

        // Then: Greeting may have updated (if time changed)
        // Note: This test is timing-dependent, so we just verify it doesn't crash
        XCTAssertNotNil(sut.greetingMessage, "Greeting should still be set after refresh")

        // Verify it's still a valid greeting
        let validGreetings = ["Good Morning", "Good Afternoon", "Good Evening", "Hello"]
        XCTAssertTrue(validGreetings.contains(sut.greetingMessage), "Greeting should still be valid after refresh")
    }

    func testRefresh_DoesNotCrash() {
        // Given: HomeViewModel

        // When: Refresh is called multiple times
        sut.refresh()
        sut.refresh()
        sut.refresh()

        // Then: Should not crash
        XCTAssertEqual(sut.features.count, 4, "Features should still be loaded")
    }
}

// MARK: - Extended Mock App Coordinator

class ExtendedMockAppCoordinator: MockAppCoordinator {
    var didCallHandleFeatureTap = false
    var lastTappedFeature: FeatureCard?
    var didCallNavigateToSettings = false
    var didCallHandleEmergencyAccess = false

    override func handleFeatureTap(_ feature: FeatureCard) {
        didCallHandleFeatureTap = true
        lastTappedFeature = feature
    }

    override func navigateToSettings() {
        didCallNavigateToSettings = true
    }

    override func handleEmergencyAccess() {
        didCallHandleEmergencyAccess = true
    }
}
