//
//  EmergencyAccessButton.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import SwiftUI

/// Emergency quick access button for immediate support
/// Prominent button for crisis situations requiring immediate guidance
struct EmergencyAccessButton: View {

    // MARK: - Properties

    let action: () -> Void

    // MARK: - State

    @State private var isPressed: Bool = false

    // MARK: - Body

    var body: some View {
        Button(action: {
            AccessibilityHelper.shared.buttonTap()
            action()
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Need Help Now?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Quick access to calming strategies")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 70)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Need Help Now? Emergency Access")
        .accessibilityHint("Double tap for quick access to calming strategies and support resources")
        .accessibilityIdentifier("home_emergency_access_button")
    }
}

// MARK: - Press Events ViewModifier

/// Custom view modifier to handle press and release events
struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
    }
}

extension View {
    /// Add press and release event handlers to a view
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Preview Provider

struct EmergencyAccessButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmergencyAccessButton(action: {
                print("Emergency access tapped")
            })
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Default")

            EmergencyAccessButton(action: {})
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Dark Mode")

            EmergencyAccessButton(action: {})
                .environment(\.sizeCategory, .accessibilityLarge)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Large Text")

            VStack(spacing: 20) {
                Text("Home Screen")
                    .font(.title)
                EmergencyAccessButton(action: {})
                Spacer()
            }
            .padding()
            .previewDisplayName("In Context")
        }
    }
}
