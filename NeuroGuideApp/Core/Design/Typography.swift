//
//  Typography.swift
//  NeuroGuide
//
//  Unit 12 - Branding & Visual Identity
//  Typography system with Dynamic Type support
//

import SwiftUI

extension Font {
    // MARK: - Display & Titles

    /// Large display text (32pt, bold)
    /// Use sparingly for key screens
    static let ngDisplay = Font.system(size: 32, weight: .bold, design: .default)

    /// Title 1 (28pt, bold)
    /// Main screen titles
    static let ngTitle1 = Font.system(size: 28, weight: .bold, design: .default)

    /// Title 2 (22pt, semibold)
    /// Section headings
    static let ngTitle2 = Font.system(size: 22, weight: .semibold, design: .default)

    /// Title 3 (20pt, semibold)
    /// Sub-section headings
    static let ngTitle3 = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: - Body Text

    /// Body (17pt, regular)
    /// Primary body text - optimized for readability
    static let ngBody = Font.system(size: 17, weight: .regular, design: .default)

    /// Body semibold (17pt, semibold)
    /// Emphasized body text
    static let ngBodySemibold = Font.system(size: 17, weight: .semibold, design: .default)

    /// Body bold (17pt, bold)
    /// Strong emphasis in body text
    static let ngBodyBold = Font.system(size: 17, weight: .bold, design: .default)

    /// Callout (16pt, regular)
    /// Secondary body text, slightly smaller
    static let ngCallout = Font.system(size: 16, weight: .regular, design: .default)

    /// Callout semibold (16pt, semibold)
    /// Emphasized callout text
    static let ngCalloutSemibold = Font.system(size: 16, weight: .semibold, design: .default)

    // MARK: - Small Text

    /// Subheadline (15pt, regular)
    /// Supporting text, labels
    static let ngSubheadline = Font.system(size: 15, weight: .regular, design: .default)

    /// Footnote (13pt, regular)
    /// Small descriptive text
    static let ngFootnote = Font.system(size: 13, weight: .regular, design: .default)

    /// Caption (12pt, regular) - Alias for ngCaption1
    /// Very small descriptive text
    static let ngCaption = Font.system(size: 12, weight: .regular, design: .default)

    /// Caption 1 (12pt, regular)
    /// Very small descriptive text
    static let ngCaption1 = Font.system(size: 12, weight: .regular, design: .default)

    /// Caption 2 (11pt, regular)
    /// Smallest text size
    static let ngCaption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Dynamic Type Support

    /// Body with Dynamic Type support
    static let ngBodyDynamic = Font.system(.body, design: .default)

    /// Headline with Dynamic Type support
    static let ngHeadlineDynamic = Font.system(.headline, design: .default)

    /// Subheadline with Dynamic Type support
    static let ngSubheadlineDynamic = Font.system(.subheadline, design: .default)

    /// Caption with Dynamic Type support
    static let ngCaptionDynamic = Font.system(.caption, design: .default)
}

// MARK: - Text Style Helpers

extension Text {
    /// Apply neurodiversity-friendly body text style
    func ngBodyStyle() -> some View {
        self
            .font(.ngBody)
            .foregroundColor(.ngTextPrimary)
            .lineSpacing(4) // Increased line spacing for readability
    }

    /// Apply section heading style
    func ngSectionHeading() -> some View {
        self
            .font(.ngTitle2)
            .foregroundColor(.ngTextPrimary)
            .fontWeight(.semibold)
    }

    /// Apply secondary caption style
    func ngCaption() -> some View {
        self
            .font(.ngFootnote)
            .foregroundColor(.ngTextSecondary)
    }
}

// MARK: - Line Height and Spacing Constants

enum NGTypography {
    /// Line height multiplier for body text (1.4x)
    static let bodyLineHeight: CGFloat = 1.4

    /// Line height multiplier for headings (1.2x)
    static let headingLineHeight: CGFloat = 1.2

    /// Letter spacing for display text
    static let displayLetterSpacing: CGFloat = -0.5

    /// Letter spacing for body text
    static let bodyLetterSpacing: CGFloat = 0.0
}
