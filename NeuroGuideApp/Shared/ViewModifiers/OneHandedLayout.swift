//
//  OneHandedLayout.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import SwiftUI

/// ViewModifier for one-handed use accessibility
/// Positions interactive elements in the bottom 2/3 of the screen
/// Implements US-062: One-handed use requirement
struct OneHandedLayout: ViewModifier {

    // MARK: - Properties

    /// Top padding representing the top 1/3 of screen (unreachable area)
    private var topPadding: CGFloat {
        return AccessibilityHelper.oneHandedTopPadding(screenHeight: UIScreen.main.bounds.height)
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            // Top 1/3: Empty space or read-only content
            Spacer()
                .frame(height: topPadding)
                .accessibilityHidden(true)

            // Bottom 2/3: Interactive content (reachable with one hand)
            content
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply one-handed layout modifier
    /// Positions content in the bottom 2/3 of screen for easy reach
    func oneHandedLayout() -> some View {
        modifier(OneHandedLayout())
    }
}

// MARK: - Preview Provider

struct OneHandedLayout_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Example with button
            VStack(spacing: 20) {
                Text("This content is in the reachable area")
                    .font(.title3)
                    .multilineTextAlignment(.center)

                Button("Tap Me") {
                    print("Button tapped")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .oneHandedLayout()
            .previewDisplayName("One-Handed Layout")

            // Comparison without modifier
            VStack(spacing: 20) {
                Text("This content might be hard to reach")
                    .font(.title3)
                    .multilineTextAlignment(.center)

                Button("Tap Me") {
                    print("Button tapped")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding()
            .previewDisplayName("Without Modifier (Compare)")

            // Dark mode
            VStack(spacing: 20) {
                Text("One-handed layout in dark mode")
                    .font(.title3)
                    .multilineTextAlignment(.center)

                Button("Tap Me") {
                    print("Button tapped")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .oneHandedLayout()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
