//
//  OnboardingPageView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.2 - Onboarding & Tutorial
//  Unit 12 - Branded Onboarding Flow (US-037)
//

import SwiftUI

/// View displaying a single onboarding page with Attune branding
struct OnboardingPageView: View {

    // MARK: - Properties

    let page: OnboardingPage

    // MARK: - Body

    var body: some View {
        ZStack {
            // Branded gradient background
            brandedBackground(for: page.featureType)
                .ignoresSafeArea()

            VStack(spacing: NGSpacing.xl) {
                Spacer()

                // Special handling for welcome page - show Attune logo
                if page.featureType == .welcome {
                    welcomeLogoView
                } else {
                    // Feature icon for other pages
                    featureIconView
                }

                // Title
                Text(page.title)
                    .font(.ngTitle1)
                    .foregroundColor(.ngTextPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, NGSpacing.screenPadding)

                // Description
                Text(page.description)
                    .font(.ngBody)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.ngTextSecondary)
                    .lineSpacing(6)
                    .padding(.horizontal, NGSpacing.xl)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(NGSpacing.screenPadding)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Subviews

    /// Attune logo for welcome page
    private var welcomeLogoView: some View {
        VStack(spacing: NGSpacing.lg) {
            Image("attune-logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240)
                .accessibilityHidden(true) // Logo is decorative

            // Tagline
            Text("Neurodiversity-affirming support")
                .font(.ngCallout)
                .foregroundColor(.ngTextSecondary)
                .accessibilityHidden(true) // Will be read as part of description
        }
    }

    /// Feature icon for non-welcome pages
    private var featureIconView: some View {
        ZStack {
            // Icon background circle with brand color
            Circle()
                .fill(iconBackgroundColor(for: page.featureType))
                .frame(width: 120, height: 120)
                .shadow(color: Color.ngPrimaryBlue.opacity(0.2), radius: 16, x: 0, y: 8)

            // Icon
            Image(systemName: page.iconName)
                .font(.system(size: 56, weight: .medium))
                .foregroundColor(.white)
                .accessibilityHidden(true) // Icon is decorative
        }
    }

    // MARK: - Helper Methods

    /// Returns gradient background for each feature type
    private func brandedBackground(for featureType: OnboardingPage.FeatureType) -> some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors(for: featureType)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Gradient colors for each feature type
    private func gradientColors(for featureType: OnboardingPage.FeatureType) -> [Color] {
        switch featureType {
        case .welcome:
            return [Color.ngPrimaryBlue.opacity(0.15), Color.ngSecondaryPurple.opacity(0.15)]
        case .liveCoach:
            return [Color.ngPrimaryBlue.opacity(0.1), Color.ngInfo.opacity(0.1)]
        case .emotionInterface:
            return [Color.ngSecondaryPurple.opacity(0.1), Color.ngPrimaryBlue.opacity(0.1)]
        case .askNeuroGuide:
            return [Color.ngAccentOrange.opacity(0.1), Color.ngPrimaryBlue.opacity(0.1)]
        case .childProfile:
            return [Color.ngSuccess.opacity(0.1), Color.ngPrimaryBlue.opacity(0.1)]
        }
    }

    /// Icon background color for each feature type
    private func iconBackgroundColor(for featureType: OnboardingPage.FeatureType) -> Color {
        switch featureType {
        case .welcome:
            return .ngPrimaryBlue
        case .liveCoach:
            return .ngPrimaryBlue
        case .emotionInterface:
            return .ngSecondaryPurple
        case .askNeuroGuide:
            return .ngAccentOrange
        case .childProfile:
            return .ngSuccess
        }
    }
}

// MARK: - Previews

#Preview("Welcome Page") {
    OnboardingPageView(page: .welcome)
}

#Preview("Live Coach Page") {
    OnboardingPageView(page: .liveCoach)
}

#Preview("Emotion Interface Page") {
    OnboardingPageView(page: .emotionInterface)
}
