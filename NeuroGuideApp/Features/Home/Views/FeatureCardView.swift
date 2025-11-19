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

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button(action: {
            AccessibilityHelper.shared.buttonTap()
            action()
        }) {
            VStack(spacing: 16) {
                // Icon with light purple/blue circle background
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 64, height: 64)

                    Image(systemName: feature.iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                .accessibilityHidden(true)

                // Title
                Text(feature.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.ngCardTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Description
                Text(feature.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.ngCardTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                // Availability Badge
                if !feature.isAvailable {
                    Text("Coming Soon")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.6))
                        )
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.title) feature")
        .accessibilityHint(accessibilityHint)
        .accessibilityIdentifier("feature_card_\(feature.id)")
    }

    // MARK: - Helper Properties

    private var iconBackgroundColor: Color {
        if feature.isAvailable {
            // Light purple/blue background for active features
            return .ngIconBackgroundLight
        } else {
            return Color.gray.opacity(0.2)
        }
    }

    private var iconColor: Color {
        if feature.isAvailable {
            // Darker purple/blue for icon
            return .ngIconForeground
        } else {
            return Color.gray.opacity(0.6)
        }
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
