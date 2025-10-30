//
//  Spacing.swift
//  NeuroGuide
//
//  Unit 12 - Branding & Visual Identity
//  Spacing and layout constants using 8pt grid system
//

import SwiftUI

/// Spacing constants following 8pt grid system
enum NGSpacing {
    // MARK: - Base Units (8pt grid)

    /// Extra extra small spacing (4pt)
    static let xxs: CGFloat = 4

    /// Extra small spacing (8pt)
    static let xs: CGFloat = 8

    /// Small spacing (12pt)
    static let sm: CGFloat = 12

    /// Medium spacing (16pt) - Default for most layouts
    static let md: CGFloat = 16

    /// Large spacing (24pt)
    static let lg: CGFloat = 24

    /// Extra large spacing (32pt)
    static let xl: CGFloat = 32

    /// Extra extra large spacing (40pt)
    static let xxl: CGFloat = 40

    /// Extra extra extra large spacing (48pt)
    static let xxxl: CGFloat = 48

    // MARK: - Semantic Spacing

    /// Standard screen horizontal padding
    static let screenPadding: CGFloat = md // 16pt

    /// Standard card padding
    static let cardPadding: CGFloat = md // 16pt

    /// Standard section spacing
    static let sectionSpacing: CGFloat = lg // 24pt

    /// Standard item spacing in lists
    static let itemSpacing: CGFloat = sm // 12pt

    /// Standard button padding (horizontal)
    static let buttonPaddingHorizontal: CGFloat = lg // 24pt

    /// Standard button padding (vertical)
    static let buttonPaddingVertical: CGFloat = sm // 12pt
}

/// Border radius constants
enum NGRadius {
    /// Extra small radius (4pt)
    static let xs: CGFloat = 4

    /// Small radius (8pt) - For small elements like badges
    static let sm: CGFloat = 8

    /// Medium radius (12pt) - Default for most UI elements
    static let md: CGFloat = 12

    /// Large radius (16pt) - For cards and containers
    static let lg: CGFloat = 16

    /// Extra large radius (20pt) - For prominent elements
    static let xl: CGFloat = 20

    /// Full radius (very large number) - For pills and circular elements
    static let full: CGFloat = 9999
}

/// Shadow and elevation constants
enum NGShadow {
    /// Subtle shadow for cards
    static let card = (
        color: Color.black.opacity(0.08),
        radius: CGFloat(8),
        x: CGFloat(0),
        y: CGFloat(2)
    )

    /// Medium shadow for elevated elements
    static let elevated = (
        color: Color.black.opacity(0.12),
        radius: CGFloat(12),
        x: CGFloat(0),
        y: CGFloat(4)
    )

    /// Strong shadow for floating elements
    static let floating = (
        color: Color.black.opacity(0.16),
        radius: CGFloat(16),
        x: CGFloat(0),
        y: CGFloat(8)
    )
}

/// Icon sizes
enum NGIconSize {
    /// Small icon (16pt)
    static let sm: CGFloat = 16

    /// Medium icon (24pt) - Default
    static let md: CGFloat = 24

    /// Large icon (32pt)
    static let lg: CGFloat = 32

    /// Extra large icon (48pt)
    static let xl: CGFloat = 48

    /// Extra extra large icon (64pt)
    static let xxl: CGFloat = 64
}

/// Touch target sizes (iOS Human Interface Guidelines)
enum NGTouchTarget {
    /// Minimum recommended touch target (44x44pt)
    static let minimum: CGFloat = 44

    /// Comfortable touch target (48x48pt)
    static let comfortable: CGFloat = 48

    /// Large touch target (56x56pt)
    static let large: CGFloat = 56
}

// MARK: - View Modifiers for Consistent Spacing

extension View {
    /// Apply standard screen padding
    func ngScreenPadding() -> some View {
        self.padding(.horizontal, NGSpacing.screenPadding)
    }

    /// Apply standard card padding
    func ngCardPadding() -> some View {
        self.padding(NGSpacing.cardPadding)
    }

    /// Apply standard card style (padding + background + rounded corners)
    func ngCardStyle() -> some View {
        self
            .ngCardPadding()
            .background(Color.ngSurface)
            .cornerRadius(NGRadius.lg)
            .shadow(
                color: NGShadow.card.color,
                radius: NGShadow.card.radius,
                x: NGShadow.card.x,
                y: NGShadow.card.y
            )
    }
}
