//
//  LaunchStateManagerTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import XCTest
import Combine
@testable import NeuroGuideApp

/// Unit tests for LaunchStateManager
/// Tests first launch detection and welcome completion persistence
final class LaunchStateManagerTests: XCTestCase {

    // MARK: - Properties

    var sut: LaunchStateManager!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Test UserDefaults Suite

    var testUserDefaults: UserDefaults!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Use a test suite to avoid polluting real UserDefaults
        testUserDefaults = UserDefaults(suiteName: "NeuroGuideTestSuite")
        testUserDefaults.removePersistentDomain(forName: "NeuroGuideTestSuite")

        sut = LaunchStateManager()
        cancellables = []

        // Reset state before each test
        sut.resetLaunchState()
    }

    override func tearDown() {
        sut.resetLaunchState()
        testUserDefaults.removePersistentDomain(forName: "NeuroGuideTestSuite")
        sut = nil
        cancellables = nil
        testUserDefaults = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_LoadsPersistedState() {
        // Given: LaunchStateManager with persisted welcome completion
        sut.markWelcomeComplete()
        XCTAssertTrue(sut.hasCompletedWelcome)

        // When: Create new LaunchStateManager instance
        let newManager = LaunchStateManager()

        // Then: Should load persisted state
        XCTAssertTrue(newManager.hasCompletedWelcome, "Should load persisted welcome completion state")
    }

    // MARK: - First Launch Tests

    func testCheckFirstLaunch_ReturnsTrue_WhenLaunchCountIsZero() {
        // Given: Fresh LaunchStateManager (launch count = 0)

        // When: Check if first launch
        let isFirstLaunch = sut.checkFirstLaunch()

        // Then: Should return true
        XCTAssertTrue(isFirstLaunch, "Should return true for first launch")
    }

    func testCheckFirstLaunch_ReturnsFalse_AfterIncrement() {
        // Given: LaunchStateManager after incrementing launch count

        // When: Increment launch count and check again
        sut.incrementLaunchCount()
        let isFirstLaunch = sut.checkFirstLaunch()

        // Then: Should return false
        XCTAssertFalse(isFirstLaunch, "Should return false after first launch")
    }

    // MARK: - Launch Count Tests

    func testIncrementLaunchCount_IncrementsCount() {
        // Given: Fresh LaunchStateManager
        XCTAssertTrue(sut.checkFirstLaunch())

        // When: Increment launch count
        sut.incrementLaunchCount()

        // Then: Launch count should be incremented
        XCTAssertFalse(sut.checkFirstLaunch())
    }

    func testIncrementLaunchCount_SetsLastLaunchDate() {
        // Given: Fresh LaunchStateManager
        XCTAssertNil(sut.lastLaunchDate())

        // When: Increment launch count
        sut.incrementLaunchCount()

        // Then: Last launch date should be set
        XCTAssertNotNil(sut.lastLaunchDate(), "Last launch date should be set")

        let lastLaunchDate = sut.lastLaunchDate()!
        let now = Date()
        let timeDifference = abs(lastLaunchDate.timeIntervalSince(now))

        XCTAssertLessThan(timeDifference, 2.0, "Last launch date should be approximately now")
    }

    func testIncrementLaunchCount_CanBeCalledMultipleTimes() {
        // Given: Fresh LaunchStateManager

        // When: Increment launch count multiple times
        sut.incrementLaunchCount()
        sut.incrementLaunchCount()
        sut.incrementLaunchCount()

        // Then: Should not crash and launch count should be > 0
        XCTAssertFalse(sut.checkFirstLaunch())
    }

    // MARK: - Welcome Completion Tests

    func testMarkWelcomeComplete_SetsHasCompletedWelcome() {
        // Given: Fresh LaunchStateManager
        XCTAssertFalse(sut.hasCompletedWelcome)

        // When: Mark welcome as complete
        sut.markWelcomeComplete()

        // Then: hasCompletedWelcome should be true
        XCTAssertTrue(sut.hasCompletedWelcome)
    }

    // MARK: - Onboarding Completion Tests

    func testMarkOnboardingComplete_SetsHasCompletedOnboarding() {
        // Given: Fresh LaunchStateManager
        XCTAssertFalse(sut.hasCompletedOnboarding)

        // When: Mark onboarding as complete
        sut.markOnboardingComplete()

        // Then: hasCompletedOnboarding should be true
        XCTAssertTrue(sut.hasCompletedOnboarding)
    }

    func testHasCompletedOnboarding_PublishesChanges() {
        // Given: LaunchStateManager
        let expectation = XCTestExpectation(description: "hasCompletedOnboarding should publish changes")
        var publishedValue: Bool?

        sut.$hasCompletedOnboarding
            .dropFirst() // Skip initial value
            .sink { value in
                publishedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Mark onboarding as complete
        sut.markOnboardingComplete()

        // Then: Should publish the change
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(publishedValue, true)
    }

    func testHasCompletedOnboarding_PersistsToUserDefaults() {
        // Given: LaunchStateManager

        // When: Mark onboarding as complete
        sut.markOnboardingComplete()

        // Then: Should persist to UserDefaults
        let persistedValue = UserDefaults.standard.bool(forKey: "com.neuroguide.hasCompletedOnboarding")
        XCTAssertTrue(persistedValue, "Should persist onboarding completion to UserDefaults")
    }

    func testResetOnboarding_ResetsOnboardingState() {
        // Given: LaunchStateManager with completed onboarding
        sut.markOnboardingComplete()
        XCTAssertTrue(sut.hasCompletedOnboarding)

        // When: Reset onboarding
        sut.resetOnboarding()

        // Then: Onboarding state should be reset
        XCTAssertFalse(sut.hasCompletedOnboarding, "Onboarding state should be reset")
    }

    func testResetOnboarding_DoesNotAffectWelcomeState() {
        // Given: LaunchStateManager with completed welcome and onboarding
        sut.markWelcomeComplete()
        sut.markOnboardingComplete()
        XCTAssertTrue(sut.hasCompletedWelcome)
        XCTAssertTrue(sut.hasCompletedOnboarding)

        // When: Reset onboarding
        sut.resetOnboarding()

        // Then: Welcome state should remain unchanged
        XCTAssertTrue(sut.hasCompletedWelcome, "Welcome state should not be affected")
        XCTAssertFalse(sut.hasCompletedOnboarding, "Onboarding state should be reset")
    }

    func testHasCompletedWelcome_PublishesChanges() {
        // Given: LaunchStateManager
        let expectation = XCTestExpectation(description: "hasCompletedWelcome should publish changes")
        var publishedValue: Bool?

        sut.$hasCompletedWelcome
            .dropFirst() // Skip initial value
            .sink { value in
                publishedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Mark welcome as complete
        sut.markWelcomeComplete()

        // Then: Should publish the change
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(publishedValue, true)
    }

    func testHasCompletedWelcome_PersistsToUserDefaults() {
        // Given: LaunchStateManager

        // When: Mark welcome as complete
        sut.markWelcomeComplete()

        // Then: Should persist to UserDefaults
        let persistedValue = UserDefaults.standard.bool(forKey: "com.neuroguide.hasCompletedWelcome")
        XCTAssertTrue(persistedValue, "Should persist welcome completion to UserDefaults")
    }

    // MARK: - Reset Tests

    func testResetLaunchState_ResetsAllState() {
        // Given: LaunchStateManager with completed welcome, onboarding and multiple launches
        sut.markWelcomeComplete()
        sut.markOnboardingComplete()
        sut.incrementLaunchCount()
        sut.incrementLaunchCount()

        XCTAssertTrue(sut.hasCompletedWelcome)
        XCTAssertTrue(sut.hasCompletedOnboarding)
        XCTAssertFalse(sut.checkFirstLaunch())
        XCTAssertNotNil(sut.lastLaunchDate())

        // When: Reset launch state
        sut.resetLaunchState()

        // Then: All state should be reset
        XCTAssertFalse(sut.hasCompletedWelcome, "Welcome completion should be reset")
        XCTAssertFalse(sut.hasCompletedOnboarding, "Onboarding completion should be reset")
        XCTAssertTrue(sut.checkFirstLaunch(), "Launch count should be reset to 0")
        XCTAssertNil(sut.lastLaunchDate(), "Last launch date should be cleared")
    }

    // MARK: - Last Launch Date Tests

    func testLastLaunchDate_ReturnsNil_WhenNeverLaunched() {
        // Given: Fresh LaunchStateManager

        // When: Get last launch date
        let lastLaunchDate = sut.lastLaunchDate()

        // Then: Should return nil
        XCTAssertNil(lastLaunchDate, "Should return nil when never launched")
    }

    func testLastLaunchDate_ReturnsDate_AfterIncrement() {
        // Given: LaunchStateManager

        // When: Increment launch count
        sut.incrementLaunchCount()
        let lastLaunchDate = sut.lastLaunchDate()

        // Then: Should return a date
        XCTAssertNotNil(lastLaunchDate, "Should return a date after incrementing launch count")
    }

    func testLastLaunchDate_UpdatesOnEachIncrement() {
        // Given: LaunchStateManager
        sut.incrementLaunchCount()
        let firstLaunchDate = sut.lastLaunchDate()!

        // When: Wait a moment and increment again
        Thread.sleep(forTimeInterval: 0.1)
        sut.incrementLaunchCount()
        let secondLaunchDate = sut.lastLaunchDate()!

        // Then: Second launch date should be after first
        XCTAssertGreaterThan(secondLaunchDate, firstLaunchDate, "Second launch date should be after first")
    }
}
