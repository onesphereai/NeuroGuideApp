//
//  OnboardingProgressView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.2 - Onboarding & Tutorial
//  Unit 12 - Branded Onboarding Flow (US-037)
//

import SwiftUI

/// Branded progress indicator showing dots for each onboarding page
struct OnboardingProgressView: View {

    // MARK: - Properties

    let currentPage: Int
    let totalPages: Int

    // MARK: - Body

    var body: some View {
        HStack(spacing: NGSpacing.xs) {
            ForEach(0..<totalPages, id: \.self) { index in
                progressDot(for: index)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("Page \(currentPage + 1) of \(totalPages)")
    }

    // MARK: - Subviews

    /// Individual progress dot with Attune branding
    @ViewBuilder
    private func progressDot(for index: Int) -> some View {
        if index == currentPage {
            // Active dot - larger with brand gradient
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.ngPrimaryBlue, Color.ngSecondaryPurple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 24, height: 8)
                .shadow(color: Color.ngPrimaryBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
        } else {
            // Inactive dot
            Circle()
                .fill(Color.ngTextTertiary.opacity(0.3))
                .frame(width: 8, height: 8)
                .animation(.easeInOut(duration: 0.3), value: currentPage)
        }
    }
}

// MARK: - Previews

#Preview("Progress - Page 1 of 5") {
    OnboardingProgressView(currentPage: 0, totalPages: 5)
        .padding()
}

#Preview("Progress - Page 3 of 5") {
    OnboardingProgressView(currentPage: 2, totalPages: 5)
        .padding()
}

#Preview("Progress - Page 5 of 5") {
    OnboardingProgressView(currentPage: 4, totalPages: 5)
        .padding()
}
