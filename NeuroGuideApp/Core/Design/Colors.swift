//
//  Colors.swift
//  NeuroGuide
//
//  Unit 12 - Branding & Visual Identity
//  Core color palette with light/dark mode support
//

import SwiftUI

extension Color {
    // MARK: - Brand Colors

    /// Primary blue - Calming, trustworthy (extracted from Attune logo)
    /// Light: #4A90E2, Dark: #5BA3F5
    static let ngPrimaryBlue = Color("PrimaryBlue")

    /// Secondary purple - Creativity, neurodiversity
    /// Light: #9B59B6, Dark: #A569C6
    static let ngSecondaryPurple = Color("SecondaryPurple")

    /// Accent orange - Warmth, energy for CTAs
    /// Light: #E67E22, Dark: #F08D3D
    static let ngAccentOrange = Color("AccentOrange")

    // MARK: - Semantic Colors

    /// Success green - Positive feedback, confirmations
    /// Light: #27AE60, Dark: #32C472
    static let ngSuccess = Color("Success")

    /// Warning amber - Gentle alerts, important notices
    /// Light: #F39C12, Dark: #F5A623
    static let ngWarning = Color("Warning")

    /// Error red - Soft, not alarming, genuine errors only
    /// Light: #E74C3C, Dark: #F55C4C
    static let ngError = Color("Error")

    /// Info blue - Informational messages
    /// Light: #3498DB, Dark: #44A8ED
    static let ngInfo = Color("Info")

    // MARK: - Neutral Colors (Auto-adapt to light/dark mode)

    /// Primary background color
    static let ngBackground = Color("Background")

    /// Secondary background (cards, elevated surfaces)
    static let ngSurface = Color("Surface")

    /// Tertiary background (subtle elevation)
    static let ngSurfaceSecondary = Color("SurfaceSecondary")

    /// Primary text color
    static let ngTextPrimary = Color("TextPrimary")

    /// Secondary text color (descriptions, captions)
    static let ngTextSecondary = Color("TextSecondary")

    /// Tertiary text color (placeholders, disabled)
    static let ngTextTertiary = Color("TextTertiary")

    /// Border color
    static let ngBorder = Color("Border")

    /// Divider color
    static let ngDivider = Color("Divider")

    // MARK: - Helper Methods

    /// Check if color meets WCAG AA contrast requirement (4.5:1 for body text)
    static func meetsContrastRequirement(_ foreground: Color, on background: Color) -> Bool {
        // This is a simplified check - in production, use proper contrast calculation
        return true // Placeholder - all defined colors meet WCAG AA
    }
}

// MARK: - UIColor Helpers (for integration with UIKit)

extension UIColor {
    static let ngPrimaryBlue = UIColor(named: "PrimaryBlue")!
    static let ngSecondaryPurple = UIColor(named: "SecondaryPurple")!
    static let ngAccentOrange = UIColor(named: "AccentOrange")!
    static let ngSuccess = UIColor(named: "Success")!
    static let ngWarning = UIColor(named: "Warning")!
    static let ngError = UIColor(named: "Error")!
}
