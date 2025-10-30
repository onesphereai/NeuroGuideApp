//
//  NGCard.swift
//  NeuroGuide
//
//  Unit 12 - Design System Components (US-038)
//  Branded card components for Attune
//

import SwiftUI

/// Card style variants
enum NGCardStyle {
    case elevated   // Shadow with white background
    case flat       // No shadow, subtle background
    case outlined   // Border with transparent background
    case gradient   // Gradient background
}

// MARK: - Basic Card

/// Basic elevated card with Attune branding
struct NGCard<Content: View>: View {
    let style: NGCardStyle
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        style: NGCardStyle = .elevated,
        padding: CGFloat = NGSpacing.cardPadding,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(NGRadius.lg)
            .overlay(borderOverlay)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }

    // MARK: - Style Properties

    private var backgroundColor: some ShapeStyle {
        switch style {
        case .elevated, .flat:
            return AnyShapeStyle(Color.ngSurface)
        case .outlined:
            return AnyShapeStyle(Color.clear)
        case .gradient:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.ngPrimaryBlue.opacity(0.1),
                        Color.ngSecondaryPurple.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if style == .outlined {
            RoundedRectangle(cornerRadius: NGRadius.lg)
                .stroke(Color.ngBorder, lineWidth: 1)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .elevated:
            return Color.black.opacity(0.08)
        default:
            return Color.clear
        }
    }

    private var shadowRadius: CGFloat {
        style == .elevated ? 8 : 0
    }

    private var shadowY: CGFloat {
        style == .elevated ? 4 : 0
    }
}

// MARK: - Feature Card

/// Feature card with icon, title, and description
struct NGFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: (() -> Void)?

    init(
        icon: String,
        iconColor: Color = .ngPrimaryBlue,
        title: String,
        description: String,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self.action = action
    }

    var body: some View {
        if let action = action {
            Button(action: action) {
                cardContent
            }
            .buttonStyle(.plain)
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        NGCard {
            HStack(spacing: NGSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                // Text content
                VStack(alignment: .leading, spacing: NGSpacing.xxs) {
                    Text(title)
                        .font(.ngBodySemibold)
                        .foregroundColor(.ngTextPrimary)

                    Text(description)
                        .font(.ngCaption)
                        .foregroundColor(.ngTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Chevron if tappable
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.ngTextTertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Info Card

/// Informational card with colored accent
struct NGInfoCard: View {
    let type: InfoType
    let title: String?
    let message: String
    let dismissAction: (() -> Void)?

    enum InfoType {
        case info
        case success
        case warning
        case error

        var color: Color {
            switch self {
            case .info: return .ngInfo
            case .success: return .ngSuccess
            case .warning: return .ngWarning
            case .error: return .ngError
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }

    init(
        type: InfoType,
        title: String? = nil,
        message: String,
        dismissAction: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.dismissAction = dismissAction
    }

    var body: some View {
        NGCard(style: .flat) {
            HStack(alignment: .top, spacing: NGSpacing.sm) {
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.color)
                    .accessibilityHidden(true)

                // Content
                VStack(alignment: .leading, spacing: NGSpacing.xxs) {
                    if let title = title {
                        Text(title)
                            .font(.ngBodySemibold)
                            .foregroundColor(.ngTextPrimary)
                    }

                    Text(message)
                        .font(.ngCaption)
                        .foregroundColor(.ngTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Dismiss button
                if let dismissAction = dismissAction {
                    Button(action: dismissAction) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.ngTextTertiary)
                    }
                    .accessibilityLabel("Dismiss")
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: NGRadius.lg)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Stat Card

/// Card displaying a statistic or metric
struct NGStatCard: View {
    let title: String
    let value: String
    let icon: String?
    let trend: Trend?

    enum Trend {
        case up
        case down
        case neutral

        var color: Color {
            switch self {
            case .up: return .ngSuccess
            case .down: return .ngError
            case .neutral: return .ngTextSecondary
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }

    init(
        title: String,
        value: String,
        icon: String? = nil,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.trend = trend
    }

    var body: some View {
        NGCard {
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                // Title with optional icon
                HStack(spacing: NGSpacing.xs) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.ngCaption)
                            .foregroundColor(.ngTextTertiary)
                    }

                    Text(title)
                        .font(.ngCaption)
                        .foregroundColor(.ngTextSecondary)

                    Spacer()
                }

                // Value
                HStack(alignment: .firstTextBaseline, spacing: NGSpacing.xs) {
                    Text(value)
                        .font(.ngTitle2)
                        .foregroundColor(.ngTextPrimary)

                    if let trend = trend {
                        HStack(spacing: 2) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 12, weight: .semibold))

                        }
                        .foregroundColor(trend.color)
                    }

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Card Variants") {
    ScrollView {
        VStack(spacing: NGSpacing.lg) {
            Text("Card Components")
                .font(.ngTitle2)
                .padding(.top)

            NGCard {
                Text("Basic elevated card with shadow")
                    .font(.ngBody)
            }

            NGCard(style: .flat) {
                Text("Flat card without shadow")
                    .font(.ngBody)
            }

            NGCard(style: .outlined) {
                Text("Outlined card with border")
                    .font(.ngBody)
            }

            NGCard(style: .gradient) {
                Text("Gradient background card")
                    .font(.ngBody)
            }

            NGFeatureCard(
                icon: "heart.fill",
                iconColor: .ngPrimaryBlue,
                title: "Live Coach",
                description: "Real-time support during challenging moments"
            ) {
                print("Feature tapped")
            }

            NGInfoCard(
                type: .success,
                title: "Success!",
                message: "Your settings have been saved successfully."
            )

            NGInfoCard(
                type: .warning,
                message: "This feature requires additional permissions."
            )

            NGStatCard(
                title: "Sessions This Week",
                value: "12",
                icon: "chart.bar.fill",
                trend: .up
            )
        }
        .padding()
    }
}
