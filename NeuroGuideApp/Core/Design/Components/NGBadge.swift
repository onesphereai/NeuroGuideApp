//
//  NGBadge.swift
//  NeuroGuide
//
//  Unit 12 - Design System Components (US-038)
//  Branded badge and tag components for Attune
//

import SwiftUI

// MARK: - Badge Style

enum NGBadgeStyle {
    case primary
    case secondary
    case success
    case warning
    case error
    case info
    case neutral

    var backgroundColor: Color {
        switch self {
        case .primary: return .ngPrimaryBlue.opacity(0.15)
        case .secondary: return .ngSecondaryPurple.opacity(0.15)
        case .success: return .ngSuccess.opacity(0.15)
        case .warning: return .ngWarning.opacity(0.15)
        case .error: return .ngError.opacity(0.15)
        case .info: return .ngInfo.opacity(0.15)
        case .neutral: return Color.ngTextTertiary.opacity(0.15)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary: return .ngPrimaryBlue
        case .secondary: return .ngSecondaryPurple
        case .success: return .ngSuccess
        case .warning: return .ngWarning
        case .error: return .ngError
        case .info: return .ngInfo
        case .neutral: return .ngTextSecondary
        }
    }
}

// MARK: - Badge

/// Small badge for status indicators
struct NGBadge: View {
    let text: String
    let style: NGBadgeStyle
    let icon: String?

    init(
        _ text: String,
        style: NGBadgeStyle = .primary,
        icon: String? = nil
    ) {
        self.text = text
        self.style = style
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(style.foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(style.backgroundColor)
        .cornerRadius(NGRadius.xs)
    }
}

// MARK: - Tag

/// Larger tag for categories and filters
struct NGTag: View {
    let text: String
    let style: NGBadgeStyle
    let icon: String?
    let isDismissible: Bool
    let onDismiss: (() -> Void)?

    init(
        _ text: String,
        style: NGBadgeStyle = .primary,
        icon: String? = nil,
        isDismissible: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        self.text = text
        self.style = style
        self.icon = icon
        self.isDismissible = isDismissible
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: NGSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.ngCaption)
            }

            Text(text)
                .font(.ngCalloutSemibold)

            if isDismissible, let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(text)")
            }
        }
        .foregroundColor(style.foregroundColor)
        .padding(.horizontal, NGSpacing.sm)
        .padding(.vertical, NGSpacing.xs)
        .background(style.backgroundColor)
        .cornerRadius(NGRadius.sm)
    }
}

// MARK: - Count Badge

/// Numerical badge (like notification count)
struct NGCountBadge: View {
    let count: Int
    let maxDisplay: Int
    let style: NGBadgeStyle

    init(
        count: Int,
        maxDisplay: Int = 99,
        style: NGBadgeStyle = .error
    ) {
        self.count = count
        self.maxDisplay = maxDisplay
        self.style = style
    }

    var body: some View {
        Text(displayText)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, count > 9 ? 6 : 0)
            .frame(minWidth: 20, minHeight: 20)
            .background(style.foregroundColor)
            .clipShape(Circle())
    }

    private var displayText: String {
        if count > maxDisplay {
            return "\(maxDisplay)+"
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Status Indicator

/// Colored dot for status indication
struct NGStatusIndicator: View {
    let isActive: Bool
    let activeColor: Color
    let inactiveColor: Color

    init(
        isActive: Bool,
        activeColor: Color = .ngSuccess,
        inactiveColor: Color = .ngTextTertiary
    ) {
        self.isActive = isActive
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }

    var body: some View {
        Circle()
            .fill(isActive ? activeColor : inactiveColor)
            .frame(width: 8, height: 8)
            .accessibilityLabel(isActive ? "Active" : "Inactive")
    }
}

// MARK: - Section Header

/// Branded section header with optional action
struct NGSectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?

    init(
        _ title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: NGSpacing.xxs) {
                Text(title)
                    .font(.ngTitle3)
                    .foregroundColor(.ngTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.ngCaption)
                        .foregroundColor(.ngTextSecondary)
                }
            }

            Spacer()

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.ngCalloutSemibold)
                        .foregroundColor(.ngPrimaryBlue)
                }
            }
        }
        .padding(.vertical, NGSpacing.xs)
    }
}

// MARK: - Divider

/// Branded divider with optional label
struct NGDivider: View {
    let label: String?
    let color: Color

    init(label: String? = nil, color: Color = .ngDivider) {
        self.label = label
        self.color = color
    }

    var body: some View {
        if let label = label {
            HStack(spacing: NGSpacing.md) {
                Rectangle()
                    .fill(color)
                    .frame(height: 1)

                Text(label)
                    .font(.ngCaption)
                    .foregroundColor(.ngTextTertiary)

                Rectangle()
                    .fill(color)
                    .frame(height: 1)
            }
        } else {
            Rectangle()
                .fill(color)
                .frame(height: 1)
        }
    }
}

// MARK: - Previews

#Preview("Badge & Tag Components") {
    ScrollView {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            Text("Badges & Tags")
                .font(.ngTitle2)
                .padding(.top)

            // Badges
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                Text("Badges")
                    .font(.ngBodySemibold)

                HStack(spacing: NGSpacing.sm) {
                    NGBadge("New", style: .primary, icon: "star.fill")
                    NGBadge("Active", style: .success, icon: "checkmark")
                    NGBadge("Warning", style: .warning, icon: "exclamationmark.triangle")
                    NGBadge("Error", style: .error, icon: "xmark")
                }
            }

            // Tags
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                Text("Tags")
                    .font(.ngBodySemibold)

                HStack(spacing: NGSpacing.sm) {
                    NGTag("Sensory", style: .primary, icon: "brain")
                    NGTag("Communication", style: .secondary, icon: "bubble.left")
                    NGTag("Removable", style: .info, isDismissible: true) {
                        print("Tag removed")
                    }
                }
            }

            // Count badges
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                Text("Count Badges")
                    .font(.ngBodySemibold)

                HStack(spacing: NGSpacing.md) {
                    HStack(spacing: NGSpacing.xs) {
                        Text("Notifications")
                        NGCountBadge(count: 5)
                    }

                    HStack(spacing: NGSpacing.xs) {
                        Text("Messages")
                        NGCountBadge(count: 142)
                    }
                }
            }

            // Status indicators
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                Text("Status Indicators")
                    .font(.ngBodySemibold)

                HStack(spacing: NGSpacing.md) {
                    HStack(spacing: NGSpacing.xs) {
                        NGStatusIndicator(isActive: true)
                        Text("Online")
                            .font(.ngBody)
                    }

                    HStack(spacing: NGSpacing.xs) {
                        NGStatusIndicator(isActive: false)
                        Text("Offline")
                            .font(.ngBody)
                    }
                }
            }

            // Section headers
            NGDivider()

            NGSectionHeader(
                "Recent Activity",
                subtitle: "Last 7 days",
                actionTitle: "View All"
            ) {
                print("View all tapped")
            }

            NGDivider(label: "OR")

            NGSectionHeader("Settings")
        }
        .padding()
    }
}
