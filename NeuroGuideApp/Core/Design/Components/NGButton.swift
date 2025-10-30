//
//  NGButton.swift
//  NeuroGuide
//
//  Unit 12 - Design System Components (US-038)
//  Branded button components for Attune
//

import SwiftUI

/// Button style variants for Attune design system
enum NGButtonStyle {
    case primary      // Blue-purple gradient, white text
    case secondary    // White background, blue text, border
    case tertiary     // Transparent background, blue text
    case destructive  // Red gradient for destructive actions
    case success      // Green for positive actions
}

/// Button size variants
enum NGButtonSize {
    case small   // 44pt height (minimum touch target)
    case medium  // 56pt height (default)
    case large   // 64pt height

    var height: CGFloat {
        switch self {
        case .small: return 44
        case .medium: return 56
        case .large: return 64
        }
    }

    var font: Font {
        switch self {
        case .small: return .ngCallout
        case .medium: return .ngBodySemibold
        case .large: return .ngTitle3
        }
    }
}

// MARK: - Primary Button

/// Primary gradient button with Attune branding
struct NGPrimaryButton: View {
    let title: String
    let icon: String?
    let size: NGButtonSize
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        icon: String? = nil,
        size: NGButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: NGSpacing.xs) {
                Text(title)
                    .font(size.font)

                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.ngPrimaryBlue,
                        Color.ngSecondaryPurple
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(NGRadius.lg)
            .shadow(
                color: Color.ngPrimaryBlue.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Secondary Button

/// Secondary button with border and transparent background
struct NGSecondaryButton: View {
    let title: String
    let icon: String?
    let size: NGButtonSize
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        icon: String? = nil,
        size: NGButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: NGSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }

                Text(title)
                    .font(size.font)
            }
            .foregroundColor(.ngPrimaryBlue)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(Color.ngSurface)
            .cornerRadius(NGRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: NGRadius.lg)
                    .stroke(Color.ngPrimaryBlue, lineWidth: 2)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tertiary Button

/// Tertiary text-only button
struct NGTertiaryButton: View {
    let title: String
    let icon: String?
    let size: NGButtonSize
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        icon: String? = nil,
        size: NGButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: NGSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }

                Text(title)
                    .font(size.font)
            }
            .foregroundColor(.ngPrimaryBlue)
            .frame(height: size.height)
            .padding(.horizontal, NGSpacing.md)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Destructive Button

/// Destructive button for dangerous actions
struct NGDestructiveButton: View {
    let title: String
    let icon: String?
    let size: NGButtonSize
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        icon: String? = nil,
        size: NGButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: NGSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }

                Text(title)
                    .font(size.font)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(Color.ngError)
            .cornerRadius(NGRadius.lg)
            .shadow(
                color: Color.ngError.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Success Button

/// Success button for positive actions
struct NGSuccessButton: View {
    let title: String
    let icon: String?
    let size: NGButtonSize
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        icon: String? = nil,
        size: NGButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: NGSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }

                Text(title)
                    .font(size.font)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(Color.ngSuccess)
            .cornerRadius(NGRadius.lg)
            .shadow(
                color: Color.ngSuccess.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Button

/// Circular icon-only button
struct NGIconButton: View {
    let icon: String
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(
        icon: String,
        size: CGFloat = 44,
        backgroundColor: Color = .ngPrimaryBlue,
        foregroundColor: Color = .white,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(
                    color: backgroundColor.opacity(0.3),
                    radius: 4,
                    x: 0,
                    y: 2
                )
                .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Button Styles") {
    ScrollView {
        VStack(spacing: NGSpacing.lg) {
            Text("Button Variants")
                .font(.ngTitle2)

            NGPrimaryButton("Primary Button", icon: "arrow.right") {
                print("Primary tapped")
            }

            NGSecondaryButton("Secondary Button", icon: "star") {
                print("Secondary tapped")
            }

            NGTertiaryButton("Tertiary Button", icon: "info.circle") {
                print("Tertiary tapped")
            }

            NGDestructiveButton("Delete", icon: "trash") {
                print("Delete tapped")
            }

            NGSuccessButton("Save", icon: "checkmark") {
                print("Save tapped")
            }

            HStack(spacing: NGSpacing.md) {
                NGIconButton(icon: "heart.fill") {
                    print("Heart tapped")
                }

                NGIconButton(icon: "star.fill", backgroundColor: .ngAccentOrange) {
                    print("Star tapped")
                }

                NGIconButton(icon: "bell.fill", backgroundColor: .ngSecondaryPurple) {
                    print("Bell tapped")
                }
            }
        }
        .padding()
    }
}
