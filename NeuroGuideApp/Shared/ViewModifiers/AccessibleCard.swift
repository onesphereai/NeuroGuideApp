//
//  AccessibleCard.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import SwiftUI

/// ViewModifier for creating accessible card components
/// Ensures minimum tap target size and proper accessibility traits
/// Implements US-071, US-072: Accessibility requirements
struct AccessibleCard: ViewModifier {

    // MARK: - Properties

    /// Minimum dimension for tap target (44x44 points per iOS HIG)
    private let minimumTapTarget: CGFloat = AccessibilityHelper.minimumTapTargetSize

    /// Background color for the card
    let backgroundColor: Color

    /// Corner radius for the card
    let cornerRadius: CGFloat

    /// Whether to add shadow
    let addShadow: Bool

    // MARK: - Initialization

    init(
        backgroundColor: Color = Color(UIColor.systemBackground),
        cornerRadius: CGFloat = 12,
        addShadow: Bool = true
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.addShadow = addShadow
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .frame(minWidth: minimumTapTarget, minHeight: minimumTapTarget)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(
                        color: addShadow ? Color.black.opacity(0.08) : Color.clear,
                        radius: addShadow ? 8 : 0,
                        x: 0,
                        y: addShadow ? 2 : 0
                    )
            )
            .contentShape(Rectangle()) // Makes entire card tappable
    }
}

// MARK: - View Extension

extension View {
    /// Apply accessible card styling
    /// Ensures minimum tap target size and proper visual feedback
    /// - Parameters:
    ///   - backgroundColor: Background color of the card
    ///   - cornerRadius: Corner radius of the card
    ///   - addShadow: Whether to add a shadow
    /// - Returns: Modified view with accessible card styling
    func accessibleCard(
        backgroundColor: Color = Color(UIColor.systemBackground),
        cornerRadius: CGFloat = 12,
        addShadow: Bool = true
    ) -> some View {
        modifier(AccessibleCard(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            addShadow: addShadow
        ))
    }
}

// MARK: - Preview Provider

struct AccessibleCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small content in accessible card (ensures minimum size)
            Text("Tap Me")
                .font(.caption)
                .accessibleCard()
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Small Content (Meets Minimum)")

            // Regular content
            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.red)

                Text("Like")
                    .font(.headline)
            }
            .accessibleCard()
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Regular Content")

            // Without shadow
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)

                Text("Featured")
                    .font(.subheadline)
            }
            .accessibleCard(addShadow: false)
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Without Shadow")

            // Custom background
            Text("Custom Style")
                .font(.headline)
                .foregroundColor(.white)
                .accessibleCard(
                    backgroundColor: Color.blue,
                    cornerRadius: 20
                )
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Custom Background")

            // Dark mode
            VStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 30))

                Text("Dark Mode")
                    .font(.headline)
            }
            .accessibleCard()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Dark Mode")

            // Comparison: Multiple cards
            HStack(spacing: 16) {
                VStack {
                    Image(systemName: "house.fill")
                    Text("Home")
                        .font(.caption)
                }
                .accessibleCard()

                VStack {
                    Image(systemName: "person.fill")
                    Text("Profile")
                        .font(.caption)
                }
                .accessibleCard()

                VStack {
                    Image(systemName: "gear")
                    Text("Settings")
                        .font(.caption)
                }
                .accessibleCard()
            }
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Multiple Cards")
        }
    }
}
