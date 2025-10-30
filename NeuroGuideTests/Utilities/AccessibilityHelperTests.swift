//
//  AccessibilityHelperTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import XCTest
@testable import NeuroGuideApp

/// Unit tests for AccessibilityHelper
/// Tests haptic feedback, VoiceOver utilities, and one-handed layout calculations
final class AccessibilityHelperTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Haptic Feedback Tests

    func testButtonTap_DoesNotCrash() {
        // Given: AccessibilityHelper singleton

        // When: Trigger button tap haptic
        AccessibilityHelper.shared.buttonTap()

        // Then: Should not crash
        XCTAssertTrue(true, "Button tap haptic should not crash")
    }

    func testSuccess_DoesNotCrash() {
        // Given: AccessibilityHelper singleton

        // When: Trigger success haptic
        AccessibilityHelper.shared.success()

        // Then: Should not crash
        XCTAssertTrue(true, "Success haptic should not crash")
    }

    func testError_DoesNotCrash() {
        // Given: AccessibilityHelper singleton

        // When: Trigger error haptic
        AccessibilityHelper.shared.error()

        // Then: Should not crash
        XCTAssertTrue(true, "Error haptic should not crash")
    }

    func testWarning_DoesNotCrash() {
        // Given: AccessibilityHelper singleton

        // When: Trigger warning haptic
        AccessibilityHelper.shared.warning()

        // Then: Should not crash
        XCTAssertTrue(true, "Warning haptic should not crash")
    }

    func testSelection_DoesNotCrash() {
        // Given: AccessibilityHelper singleton

        // When: Trigger selection haptic
        AccessibilityHelper.shared.selection()

        // Then: Should not crash
        XCTAssertTrue(true, "Selection haptic should not crash")
    }

    func testMultipleHaptics_DoesNotCrash() {
        // Given: AccessibilityHelper singleton

        // When: Trigger multiple haptics in sequence
        AccessibilityHelper.shared.buttonTap()
        AccessibilityHelper.shared.success()
        AccessibilityHelper.shared.selection()
        AccessibilityHelper.shared.buttonTap()
        AccessibilityHelper.shared.error()

        // Then: Should not crash
        XCTAssertTrue(true, "Multiple haptics should not crash")
    }

    // MARK: - VoiceOver Tests

    func testIsVoiceOverRunning_ReturnsBool() {
        // Given: System VoiceOver state

        // When: Check if VoiceOver is running
        let isRunning = AccessibilityHelper.isVoiceOverRunning()

        // Then: Should return a boolean (true or false, depending on system state)
        XCTAssertNotNil(isRunning, "Should return a boolean value")
    }

    func testAnnounce_DoesNotCrash() {
        // Given: Announcement string

        // When: Post VoiceOver announcement
        AccessibilityHelper.announce("Test announcement")

        // Then: Should not crash
        XCTAssertTrue(true, "VoiceOver announcement should not crash")
    }

    func testScreenChanged_DoesNotCrash() {
        // Given: Screen change notification

        // When: Post screen changed notification
        AccessibilityHelper.screenChanged()

        // Then: Should not crash
        XCTAssertTrue(true, "Screen changed notification should not crash")
    }

    func testScreenChanged_WithElement_DoesNotCrash() {
        // Given: Screen change with element

        // When: Post screen changed with element
        let testElement = "Test Element"
        AccessibilityHelper.screenChanged(newElement: testElement)

        // Then: Should not crash
        XCTAssertTrue(true, "Screen changed with element should not crash")
    }

    // MARK: - Dynamic Type Tests

    func testIsAccessibilityTextSizeEnabled_ReturnsBool() {
        // Given: System accessibility text size setting

        // When: Check if accessibility text size is enabled
        let isEnabled = AccessibilityHelper.isAccessibilityTextSizeEnabled()

        // Then: Should return a boolean
        XCTAssertNotNil(isEnabled, "Should return a boolean value")
    }

    func testCurrentContentSizeCategory_ReturnsCategory() {
        // Given: System content size category

        // When: Get current content size category
        let category = AccessibilityHelper.currentContentSizeCategory()

        // Then: Should return a valid content size category
        XCTAssertNotNil(category, "Should return a content size category")
    }

    // MARK: - Contrast Tests

    func testIsDarkerSystemColorsEnabled_ReturnsBool() {
        // Given: System darker colors setting

        // When: Check if darker colors is enabled
        let isEnabled = AccessibilityHelper.isDarkerSystemColorsEnabled()

        // Then: Should return a boolean
        XCTAssertNotNil(isEnabled, "Should return a boolean value")
    }

    func testIsReduceTransparencyEnabled_ReturnsBool() {
        // Given: System reduce transparency setting

        // When: Check if reduce transparency is enabled
        let isEnabled = AccessibilityHelper.isReduceTransparencyEnabled()

        // Then: Should return a boolean
        XCTAssertNotNil(isEnabled, "Should return a boolean value")
    }

    // MARK: - Motion Tests

    func testIsReduceMotionEnabled_ReturnsBool() {
        // Given: System reduce motion setting

        // When: Check if reduce motion is enabled
        let isEnabled = AccessibilityHelper.isReduceMotionEnabled()

        // Then: Should return a boolean
        XCTAssertNotNil(isEnabled, "Should return a boolean value")
    }

    // MARK: - One-Handed Layout Tests

    func testOneHandedReachableHeight_ReturnsBottomTwoThirds() {
        // Given: Screen height
        let screenHeight: CGFloat = 900.0

        // When: Calculate reachable height
        let reachableHeight = AccessibilityHelper.oneHandedReachableHeight(screenHeight: screenHeight)

        // Then: Should return bottom 2/3 (67% = 0.67)
        let expectedHeight = screenHeight * 0.67
        XCTAssertEqual(reachableHeight, expectedHeight, accuracy: 0.01, "Should return 67% of screen height")
    }

    func testOneHandedTopPadding_ReturnsTopOneThird() {
        // Given: Screen height
        let screenHeight: CGFloat = 900.0

        // When: Calculate top padding
        let topPadding = AccessibilityHelper.oneHandedTopPadding(screenHeight: screenHeight)

        // Then: Should return top 1/3 (33% = 0.33)
        let expectedPadding = screenHeight * 0.33
        XCTAssertEqual(topPadding, expectedPadding, accuracy: 0.01, "Should return 33% of screen height")
    }

    func testOneHandedLayout_SumsToScreenHeight() {
        // Given: Screen height
        let screenHeight: CGFloat = 900.0

        // When: Calculate both values
        let reachableHeight = AccessibilityHelper.oneHandedReachableHeight(screenHeight: screenHeight)
        let topPadding = AccessibilityHelper.oneHandedTopPadding(screenHeight: screenHeight)

        // Then: Should sum to approximately screen height
        let sum = reachableHeight + topPadding
        XCTAssertEqual(sum, screenHeight, accuracy: 1.0, "Reachable height + top padding should equal screen height")
    }

    func testOneHandedLayout_WithRealScreenDimensions() {
        // Given: Typical iPhone screen heights
        let testScreenHeights: [CGFloat] = [
            667.0,  // iPhone SE (3rd gen)
            844.0,  // iPhone 13/14
            926.0   // iPhone 14 Pro Max
        ]

        for screenHeight in testScreenHeights {
            // When: Calculate reachable height
            let reachableHeight = AccessibilityHelper.oneHandedReachableHeight(screenHeight: screenHeight)
            let topPadding = AccessibilityHelper.oneHandedTopPadding(screenHeight: screenHeight)

            // Then: Values should be reasonable
            XCTAssertGreaterThan(reachableHeight, 0, "Reachable height should be positive")
            XCTAssertGreaterThan(topPadding, 0, "Top padding should be positive")
            XCTAssertLessThan(reachableHeight, screenHeight, "Reachable height should be less than screen height")
            XCTAssertLessThan(topPadding, screenHeight, "Top padding should be less than screen height")
        }
    }

    // MARK: - Minimum Tap Target Tests

    func testMinimumTapTargetSize_Is44Points() {
        // Given: iOS Human Interface Guidelines

        // When: Get minimum tap target size
        let minimumSize = AccessibilityHelper.minimumTapTargetSize

        // Then: Should be 44 points
        XCTAssertEqual(minimumSize, 44.0, "Minimum tap target should be 44 points per iOS HIG")
    }
}
