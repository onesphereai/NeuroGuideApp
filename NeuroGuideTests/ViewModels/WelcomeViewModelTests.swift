	//
//  WelcomeViewModelTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import XCTest
import Combine
@testable import NeuroGuideApp

/// Unit tests for WelcomeViewModel
/// Tests welcome completion flow and state management
final class WelcomeViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: WelcomeViewModel!
    var mockCoordinator: MockAppCoordinator!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockCoordinator = MockAppCoordinator()
        sut = WelcomeViewModel(coordinator: mockCoordinator)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockCoordinator = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_HasAnimationCompletedIsFalse() {
        // Given: Fresh WelcomeViewModel
        // When: Initialized

        // Then: Animation not yet completed
        XCTAssertFalse(sut.hasAnimationCompleted, "Animation should not be completed on init")
    }

    func testInit_GetStartedButtonInitiallyDisabled() {
        // Given: Fresh WelcomeViewModel
        // When: Initialized

        // Then: Get started button should be disabled initially
        XCTAssertFalse(sut.isGetStartedEnabled, "Get started button should be disabled initially to prevent accidental taps")
    }

    // MARK: - Animation Tests

    func testAnimation_EnablesGetStartedButtonAfterDelay() {
        // Given: Fresh WelcomeViewModel
        let expectation = XCTestExpectation(description: "Get started button should be enabled after delay")

        // When: Wait for animation delay
        sut.$isGetStartedEnabled
            .dropFirst() // Skip initial value
            .sink { isEnabled in
                if isEnabled {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Then: Get started button is enabled after delay
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(sut.isGetStartedEnabled)
        XCTAssertTrue(sut.hasAnimationCompleted)
    }

    // MARK: - Complete Welcome Tests

    func testCompleteWelcome_CallsCoordinator() {
        // Given: WelcomeViewModel with mock coordinator
        sut.isGetStartedEnabled = true // Manually enable for testing

        // When: User completes welcome
        sut.completeWelcome()

        // Then: Coordinator's completeWelcome is called
        XCTAssertTrue(mockCoordinator.didCallCompleteWelcome, "Coordinator should be notified of welcome completion")
    }

    func testCompleteWelcome_CanBeCalledMultipleTimes() {
        // Given: WelcomeViewModel
        sut.isGetStartedEnabled = true

        // When: Complete welcome multiple times
        sut.completeWelcome()
        sut.completeWelcome()
        sut.completeWelcome()

        // Then: Should not crash and coordinator is called each time
        XCTAssertEqual(mockCoordinator.completeWelcomeCallCount, 3, "Coordinator should be called for each completion")
    }

    // MARK: - Skip Welcome Tests

    func testSkipWelcome_CallsCompleteWelcome() {
        // Given: WelcomeViewModel
        sut.isGetStartedEnabled = true

        // When: User skips welcome
        sut.skipWelcome()

        // Then: Should have same behavior as complete welcome (for Bolt 1.1)
        XCTAssertTrue(mockCoordinator.didCallCompleteWelcome, "Skip welcome should call complete welcome")
    }
}

// MARK: - Mock App Coordinator

/// Mock coordinator for testing
class MockAppCoordinator: AppCoordinator {
    var didCallCompleteWelcome = false
    var completeWelcomeCallCount = 0

    override func completeWelcome() {
        didCallCompleteWelcome = true
        completeWelcomeCallCount += 1
    }
}
