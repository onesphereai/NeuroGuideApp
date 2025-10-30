//
//  CredibilityBadge.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import SwiftUI

/// Badge showing the credibility level of a content source
struct CredibilityBadge: View {
    let level: CredibilityLevel
    let compact: Bool

    init(level: CredibilityLevel, compact: Bool = false) {
        self.level = level
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.system(size: compact ? 12 : 14))

            if !compact {
                Text(level.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 3 : 5)
        .background(badgeColor.opacity(0.15))
        .cornerRadius(compact ? 8 : 12)
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 8 : 12)
                .stroke(badgeColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var badgeColor: Color {
        switch level {
        case .peerReviewed:
            return .blue
        case .expertRecommended:
            return .green
        case .communityValidated:
            return .purple
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Full badges
        CredibilityBadge(level: .peerReviewed)
        CredibilityBadge(level: .expertRecommended)
        CredibilityBadge(level: .communityValidated)

        Divider()

        // Compact badges
        HStack(spacing: 8) {
            CredibilityBadge(level: .peerReviewed, compact: true)
            CredibilityBadge(level: .expertRecommended, compact: true)
            CredibilityBadge(level: .communityValidated, compact: true)
        }
    }
    .padding()
}
