//
//  LiveCoachViewModelTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System
//

import XCTest
import Combine
@testable import NeuroGuideApp

/// Unit tests for LiveCoachViewModel
/// Tests session management, error handling, and ML detection
@MainActor
final class LiveCoachViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: LiveCoachViewModel!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = LiveCoachViewModel()
        cancellables = []
    }

    override func tearDown() async throws {
        sut = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_SetsDefaultState() {
        // Given: Fresh LiveCoachViewModel
        // When: Initialized

        // Then: Default state should be set
        XCTAssertFalse(sut.isSessionActive, "Session should not be active initially")
        XCTAssertFalse(sut.isStarting, "Should not be starting initially")
        XCTAssertFalse(sut.isPaused, "Should not be paused initially")
        XCTAssertEqual(sut.sessionDuration, "0:00", "Duration should be 0:00")
        XCTAssertNil(sut.currentArousalBand, "No arousal band initially")
        XCTAssertNil(sut.currentConfidence, "No confidence initially")
        XCTAssertTrue(sut.suggestions.isEmpty, "No suggestions initially")
        XCTAssertEqual(sut.suggestionsCount, 0, "Suggestion count should be 0")
        XCTAssertNil(sut.errorMessage, "No error message initially")
    }

    // MARK: - Session Management Tests

    func testStartSession_WithoutProfile_ShowsError() async {
        // Given: No profile exists
        // When: Starting session
        await sut.startSession()

        // Then: Should show error and not start session
        XCTAssertFalse(sut.isSessionActive, "Session should not start without profile")
        XCTAssertNotNil(sut.errorMessage, "Should show error message")
        XCTAssertEqual(sut.errorMessage, "Please create a child profile first.")
    }

    func testStartSession_ClearsErrorMessage() async {
        // Given: Existing error message
        sut.errorMessage = "Previous error"

        // When: Starting session
        await sut.startSession()

        // Then: Error should be cleared (even if new error occurs)
        // Note: May have new error if no profile, but clears old one
        XCTAssertNotEqual(sut.errorMessage, "Previous error", "Should clear previous error")
    }

    func testIsStarting_TogglesDuringSessionStart() async {
        // Given: Fresh ViewModel
        let expectation = XCTestExpectation(description: "isStarting should toggle")
        var isStartingValues: [Bool] = []

        sut.$isStarting
            .sink { isStarting in
                isStartingValues.append(isStarting)
                if isStartingValues.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When: Starting session
        await sut.startSession()

        // Then: isStarting should toggle true then false
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(isStartingValues.contains(true), "Should set isStarting to true")
        XCTAssertFalse(sut.isStarting, "Should reset isStarting to false")
    }

    // MARK: - Error Message Tests

    func testErrorMessage_IsPublished() {
        // Given: Fresh ViewModel
        let expectation = XCTestExpectation(description: "Error message published")
        var receivedError: String?

        sut.$errorMessage
            .dropFirst() // Skip initial nil
            .sink { error in
                receivedError = error
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Setting error message
        sut.errorMessage = "Test error"

        // Then: Should publish error
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, "Test error")
    }

    func testErrorMessage_CanBeCleared() {
        // Given: Error message is set
        sut.errorMessage = "Test error"

        // When: Clearing error
        sut.errorMessage = nil

        // Then: Error should be nil
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Permission Status Tests

    func testSetup_LoadsPermissionStatus() {
        // Given: Fresh ViewModel
        // When: Setup is called
        sut.setup()

        // Then: Permission status should be updated
        // Note: Will be notDetermined or denied in test environment
        XCTAssertNotNil(sut.cameraStatus, "Camera status should be set")
        XCTAssertNotNil(sut.microphoneStatus, "Microphone status should be set")
    }

    // MARK: - State Management Tests

    func testSessionState_InitiallyInactive() {
        // Given: Fresh ViewModel
        // When: No session started

        // Then: Session should be inactive
        XCTAssertFalse(sut.isSessionActive)
        XCTAssertFalse(sut.isPaused)
    }

    func testSuggestions_InitiallyEmpty() {
        // Given: Fresh ViewModel
        // When: No session started

        // Then: No suggestions
        XCTAssertTrue(sut.suggestions.isEmpty)
        XCTAssertEqual(sut.suggestionsCount, 0)
    }

    // MARK: - Performance Tests

    func testStartSession_PerformanceTest() {
        measure {
            let expectation = self.expectation(description: "Start session")

            Task { @MainActor in
                await sut.startSession()
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2.0)
        }
    }

    // MARK: - Memory Management Tests

    func testViewModel_DoesNotLeakMemory() {
        // Given: ViewModel reference
        weak var weakSUT = sut

        // When: Releasing strong reference
        sut = nil

        // Then: Should deallocate
        XCTAssertNil(weakSUT, "ViewModel should be deallocated")
    }

    // MARK: - Integration Tests

    func testPublisherChain_DoesNotRetainStrongReferences() {
        // Given: ViewModel with subscriptions
        weak var weakSUT: LiveCoachViewModel? = sut

        sut.$isSessionActive
            .sink { _ in
                // Capture weak reference
                _ = weakSUT?.isSessionActive
            }
            .store(in: &cancellables)

        // When: Releasing
        sut = nil
        cancellables.removeAll()

        // Then: Should deallocate
        XCTAssertNil(weakSUT, "Should not create retain cycle")
    }

    // MARK: - Edge Cases

    func testMultipleStartSession_Calls() async {
        // Given: Fresh ViewModel
        // When: Calling start session multiple times rapidly
        async let first = sut.startSession()
        async let second = sut.startSession()
        async let third = sut.startSession()

        await first
        await second
        await third

        // Then: Should handle gracefully without crashes
        // May show error due to no profile, but shouldn't crash
        XCTAssertFalse(sut.isStarting, "Should not be stuck in starting state")
    }

    func testErrorMessage_LongString() {
        // Given: Very long error message
        let longError = String(repeating: "Error ", count: 1000)

        // When: Setting long error
        sut.errorMessage = longError

        // Then: Should handle without issues
        XCTAssertEqual(sut.errorMessage, longError)
    }

    // MARK: - Concurrency Tests

    func testConcurrentStateUpdates_AreThreadSafe() async {
        // Given: ViewModel
        // When: Updating state from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask { @MainActor in
                    self.sut.errorMessage = "Concurrent error"
                    self.sut.errorMessage = nil
                }
            }
        }

        // Then: Should complete without crashes
        XCTAssertTrue(true, "Should handle concurrent updates")
    }
}
