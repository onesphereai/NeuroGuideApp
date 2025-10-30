//
//  OnboardingViewModelTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.2 - Onboarding & Tutorial
//

import XCTest
import Combine
@testable import NeuroGuideApp

/// Unit tests for OnboardingViewModel
/// Tests page navigation, progress tracking, skip, and completion logic
final class OnboardingViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: OnboardingViewModel!
    var mockCoordinator: MockAppCoordinator!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockCoordinator = MockAppCoordinator()
        sut = OnboardingViewModel(coordinator: mockCoordinator)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockCoordinator = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_LoadsAllPages() {
        // Given: OnboardingViewModel

        // Then: Should load all 5 pages
        XCTAssertEqual(sut.pages.count, 5, "Should load all 5 onboarding pages")
        XCTAssertEqual(sut.pages, OnboardingPage.allPages, "Should load pages in correct order")
    }

    func testInit_StartsAtFirstPage() {
        // Given: OnboardingViewModel

        // Then: Should start at page 0
        XCTAssertEqual(sut.currentPageIndex, 0, "Should start at first page")
        XCTAssertEqual(sut.currentPage, OnboardingPage.welcome, "Current page should be welcome")
    }

    func testInit_WithoutCoordinator_DoesNotCrash() {
        // Given: OnboardingViewModel without coordinator

        // When: Create ViewModel without coordinator
        let viewModel = OnboardingViewModel()

        // Then: Should not crash
        XCTAssertNotNil(viewModel, "Should initialize without coordinator")
    }

    // MARK: - Navigation State Tests

    func testCanGoBack_ReturnsFalse_OnFirstPage() {
        // Given: OnboardingViewModel at first page

        // Then: Cannot go back
        XCTAssertFalse(sut.canGoBack, "Should not be able to go back from first page")
    }

    func testCanGoBack_ReturnsTrue_OnSecondPage() {
        // Given: OnboardingViewModel at second page
        sut.nextPage()

        // Then: Can go back
        XCTAssertTrue(sut.canGoBack, "Should be able to go back from second page")
    }

    func testCanGoForward_ReturnsTrue_OnFirstPage() {
        // Given: OnboardingViewModel at first page

        // Then: Can go forward
        XCTAssertTrue(sut.canGoForward, "Should be able to go forward from first page")
    }

    func testCanGoForward_ReturnsFalse_OnLastPage() {
        // Given: OnboardingViewModel at last page
        sut.currentPageIndex = sut.pages.count - 1

        // Then: Cannot go forward
        XCTAssertFalse(sut.canGoForward, "Should not be able to go forward from last page")
    }

    func testIsLastPage_ReturnsFalse_OnFirstPage() {
        // Given: OnboardingViewModel at first page

        // Then: Is not last page
        XCTAssertFalse(sut.isLastPage, "First page should not be last page")
    }

    func testIsLastPage_ReturnsTrue_OnLastPage() {
        // Given: OnboardingViewModel at last page
        sut.currentPageIndex = sut.pages.count - 1

        // Then: Is last page
        XCTAssertTrue(sut.isLastPage, "Last page should be identified correctly")
    }

    // MARK: - Progress Tests

    func testProgress_Returns20Percent_OnFirstPage() {
        // Given: OnboardingViewModel at first page (1 of 5)

        // Then: Progress should be 0.2 (20%)
        XCTAssertEqual(sut.progress, 0.2, accuracy: 0.01, "Progress should be 20% on first page")
    }

    func testProgress_Returns100Percent_OnLastPage() {
        // Given: OnboardingViewModel at last page (5 of 5)
        sut.currentPageIndex = sut.pages.count - 1

        // Then: Progress should be 1.0 (100%)
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.01, "Progress should be 100% on last page")
    }

    func testProgress_Returns60Percent_OnThirdPage() {
        // Given: OnboardingViewModel at third page (3 of 5)
        sut.currentPageIndex = 2

        // Then: Progress should be 0.6 (60%)
        XCTAssertEqual(sut.progress, 0.6, accuracy: 0.01, "Progress should be 60% on third page")
    }

    // MARK: - Current Page Tests

    func testCurrentPage_ReturnsWelcomePage_OnFirstPage() {
        // Given: OnboardingViewModel at first page

        // Then: Current page should be welcome
        XCTAssertEqual(sut.currentPage, OnboardingPage.welcome, "Current page should be welcome")
    }

    func testCurrentPage_ReturnsCorrectPage_WhenIndexChanges() {
        // Given: OnboardingViewModel

        // When: Move to second page
        sut.currentPageIndex = 1

        // Then: Current page should be live coach
        XCTAssertEqual(sut.currentPage, OnboardingPage.liveCoach, "Current page should be live coach")
    }

    func testCurrentPage_ReturnsNil_WhenIndexOutOfBounds() {
        // Given: OnboardingViewModel

        // When: Set invalid index
        sut.currentPageIndex = 99

        // Then: Current page should be nil
        XCTAssertNil(sut.currentPage, "Current page should be nil for invalid index")
    }

    // MARK: - Next Page Tests

    func testNextPage_IncrementsIndex() {
        // Given: OnboardingViewModel at first page
        XCTAssertEqual(sut.currentPageIndex, 0)

        // When: Go to next page
        sut.nextPage()

        // Then: Index should be incremented
        XCTAssertEqual(sut.currentPageIndex, 1, "Index should be incremented")
    }

    func testNextPage_UpdatesCurrentPage() {
        // Given: OnboardingViewModel at first page

        // When: Go to next page
        sut.nextPage()

        // Then: Current page should be updated
        XCTAssertEqual(sut.currentPage, OnboardingPage.liveCoach, "Current page should be updated")
    }

    func testNextPage_OnLastPage_CallsCompleteOnboarding() {
        // Given: OnboardingViewModel at last page
        sut.currentPageIndex = sut.pages.count - 1

        // When: Try to go to next page
        sut.nextPage()

        // Then: Should call complete onboarding
        XCTAssertTrue(mockCoordinator.completeOnboardingCalled, "Should call completeOnboarding")
    }

    // MARK: - Previous Page Tests

    func testPreviousPage_DecrementsIndex() {
        // Given: OnboardingViewModel at second page
        sut.currentPageIndex = 1

        // When: Go to previous page
        sut.previousPage()

        // Then: Index should be decremented
        XCTAssertEqual(sut.currentPageIndex, 0, "Index should be decremented")
    }

    func testPreviousPage_OnFirstPage_DoesNothing() {
        // Given: OnboardingViewModel at first page
        XCTAssertEqual(sut.currentPageIndex, 0)

        // When: Try to go to previous page
        sut.previousPage()

        // Then: Index should remain at 0
        XCTAssertEqual(sut.currentPageIndex, 0, "Index should remain at 0")
    }

    // MARK: - Skip Onboarding Tests

    func testSkipOnboarding_CallsCoordinatorCompleteOnboarding() {
        // Given: OnboardingViewModel

        // When: Skip onboarding
        sut.skipOnboarding()

        // Then: Should call completeOnboarding
        XCTAssertTrue(mockCoordinator.completeOnboardingCalled, "Should call completeOnboarding")
    }

    func testSkipOnboarding_CanBeCalledFromAnyPage() {
        // Given: OnboardingViewModel at third page
        sut.currentPageIndex = 2

        // When: Skip onboarding
        sut.skipOnboarding()

        // Then: Should call completeOnboarding
        XCTAssertTrue(mockCoordinator.completeOnboardingCalled, "Should call completeOnboarding from any page")
    }

    // MARK: - Complete Onboarding Tests

    func testCompleteOnboarding_CallsCoordinatorCompleteOnboarding() {
        // Given: OnboardingViewModel

        // When: Complete onboarding
        sut.completeOnboarding()

        // Then: Should call completeOnboarding
        XCTAssertTrue(mockCoordinator.completeOnboardingCalled, "Should call completeOnboarding")
    }

    // MARK: - Published Property Tests

    func testCurrentPageIndex_PublishesChanges() {
        // Given: OnboardingViewModel
        let expectation = XCTestExpectation(description: "currentPageIndex should publish changes")
        var publishedValue: Int?

        sut.$currentPageIndex
            .dropFirst() // Skip initial value
            .sink { value in
                publishedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Change page index
        sut.currentPageIndex = 2

        // Then: Should publish the change
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(publishedValue, 2)
    }
}

// MARK: - Mock AppCoordinator

/// Mock AppCoordinator for testing
class MockAppCoordinator: AppCoordinator {
    var completeOnboardingCalled = false

    override func completeOnboarding() {
        completeOnboardingCalled = true
    }
}
