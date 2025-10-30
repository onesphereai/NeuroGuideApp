//
//  AccessibilityHelper.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import UIKit

/// Provides accessibility utilities including haptic feedback
/// Supports VoiceOver and other assistive technologies
class AccessibilityHelper {

    // MARK: - Singleton

    static let shared = AccessibilityHelper()

    // MARK: - Haptic Generators

    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        // Prepare generators for reduced latency
        impactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Haptic Feedback

    /// Trigger haptic feedback for button tap
    /// Light impact for standard button interactions
    func buttonTap() {
        impactGenerator.impactOccurred()
    }

    /// Trigger haptic feedback for success action
    /// Used when an action completes successfully
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Trigger haptic feedback for error
    /// Used when an action fails or validation error occurs
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    /// Trigger haptic feedback for warning
    /// Used for non-critical warnings or alerts
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Trigger haptic feedback for selection change
    /// Used when user navigates through a list or changes selection
    func selection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - VoiceOver Utilities

    /// Check if VoiceOver is currently running
    /// - Returns: true if VoiceOver is enabled
    static func isVoiceOverRunning() -> Bool {
        return UIAccessibility.isVoiceOverRunning
    }

    /// Post an announcement to VoiceOver
    /// - Parameter announcement: The text to announce
    static func announce(_ announcement: String) {
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    /// Post a screen changed notification to VoiceOver
    /// Useful when transitioning between screens
    /// - Parameter newElement: Optional element to focus
    static func screenChanged(newElement: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: newElement)
    }

    // MARK: - Dynamic Type Utilities

    /// Check if user prefers larger accessibility text sizes
    /// - Returns: true if accessibility text sizes are enabled
    static func isAccessibilityTextSizeEnabled() -> Bool {
        return UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
    }

    /// Get the current content size category
    /// - Returns: The user's preferred content size
    static func currentContentSizeCategory() -> UIContentSizeCategory {
        return UIApplication.shared.preferredContentSizeCategory
    }

    // MARK: - Contrast Utilities

    /// Check if user prefers increased contrast
    /// - Returns: true if increased contrast is enabled
    static func isDarkerSystemColorsEnabled() -> Bool {
        return UIAccessibility.isDarkerSystemColorsEnabled
    }

    /// Check if reduce transparency is enabled
    /// - Returns: true if reduce transparency is enabled
    static func isReduceTransparencyEnabled() -> Bool {
        return UIAccessibility.isReduceTransparencyEnabled
    }

    // MARK: - Motion Utilities

    /// Check if user prefers reduced motion
    /// - Returns: true if reduce motion is enabled
    static func isReduceMotionEnabled() -> Bool {
        return UIAccessibility.isReduceMotionEnabled
    }

    // MARK: - One-Handed Use Utilities

    /// Calculate the safe reachable area for one-handed use
    /// Returns the bottom 2/3 of the screen height
    /// - Parameter screenHeight: Total screen height
    /// - Returns: Height of the reachable area
    static func oneHandedReachableHeight(screenHeight: CGFloat) -> CGFloat {
        return screenHeight * 0.67  // Bottom 2/3
    }

    /// Calculate the top padding for one-handed layout
    /// Returns the top 1/3 of the screen height
    /// - Parameter screenHeight: Total screen height
    /// - Returns: Height of the top padding
    static func oneHandedTopPadding(screenHeight: CGFloat) -> CGFloat {
        return screenHeight * 0.33  // Top 1/3
    }

    // MARK: - Minimum Tap Target

    /// Minimum tap target size for accessibility (44x44 points)
    static let minimumTapTargetSize: CGFloat = 44.0
}
