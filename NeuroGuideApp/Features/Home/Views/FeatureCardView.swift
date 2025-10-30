//
//  FeatureCardView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import SwiftUI

/// Reusable feature card component for home screen
/// Displays feature icon, title, and description with accessibility support
struct FeatureCardView: View {

    // MARK: - Properties

    let feature: FeatureCard
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: {
            AccessibilityHelper.shared.buttonTap()
            action()
        }) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: feature.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(iconColor)
                    .frame(height: 50)
                    .accessibilityHidden(true)

                // Title
                Text(feature.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Description
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                // Availability badge
                if !feature.isAvailable {
                    Text("Coming Soon")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .frame(width: 150, height: 150)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.title) feature")
        .accessibilityHint(accessibilityHint)
        .accessibilityIdentifier("feature_card_\(feature.id)")
    }

    // MARK: - Helper Properties

    private var iconColor: Color {
        feature.isAvailable ? Color.blue : Color.gray
    }

    private var backgroundColor: Color {
        Color(UIColor.systemBackground)
    }

    private var borderColor: Color {
        Color.gray.opacity(0.2)
    }

    private var accessibilityHint: String {
        if feature.isAvailable {
            return "Double tap to open \(feature.title)"
        } else {
            return "\(feature.title) is coming soon. Double tap for more information."
        }
    }
}

// MARK: - Preview Provider

struct FeatureCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Available feature
            FeatureCardView(
                feature: FeatureCard(
                    id: "test",
                    title: "Live Coach",
                    description: "Real-time support",
                    iconName: "figure.walk",
                    color: "Primary",
                    isAvailable: true
                ),
                action: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Available Feature")

            // Coming soon feature
            FeatureCardView(
                feature: FeatureCard.liveCoach,
                action: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Coming Soon Feature")

            // Dark mode
            FeatureCardView(
                feature: FeatureCard.emotionCheck,
                action: {}
            )
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Dark Mode")

            // All features in grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(FeatureCard.allFeatures) { feature in
                    FeatureCardView(feature: feature, action: {})
                }
            }
            .padding()
            .previewDisplayName("All Features Grid")
        }
    }
}
