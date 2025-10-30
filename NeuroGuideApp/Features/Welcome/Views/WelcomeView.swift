//
//  WelcomeView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import SwiftUI

/// Welcome screen shown on first app launch
/// Neurodiversity-affirming introduction to NeuroGuide
struct WelcomeView: View {

    // MARK: - Environment

    @EnvironmentObject var coordinator: AppCoordinator

    // MARK: - State

    @StateObject private var viewModel: WelcomeViewModel

    // MARK: - Initialization

    init() {
        // Initialize view model (will receive coordinator via onAppear)
        _viewModel = StateObject(wrappedValue: WelcomeViewModel())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top spacer for one-handed use (top 1/3)
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.2)

                // Content area (bottom 2/3)
                VStack(spacing: 32) {
                    // Icon
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    // Welcome text
                    VStack(spacing: 16) {
                        Text("Welcome to attune")
                            .font(.system(size: 34, weight: .bold))
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("welcome_title_text")

                        Text("Supporting parents on their journey")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("welcome_subtitle_text")
                    }
                    .padding(.horizontal, 40)

                    // Description
                    Text("Compassionate, neurodiversity-affirming guidance for those challenging moments")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("welcome_description_text")

                    Spacer()
                        .frame(height: 40)

                    // Get Started button
                    Button(action: {
                        viewModel.completeWelcome()
                    }) {
                        HStack {
                            Text("Get Started")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!viewModel.isGetStartedEnabled)
                    .opacity(viewModel.isGetStartedEnabled ? 1.0 : 0.6)
                    .padding(.horizontal, 32)
                    .accessibilityLabel("Get Started")
                    .accessibilityHint("Tap to complete welcome and go to home screen")
                    .accessibilityIdentifier("welcome_get_started_button")

                    // Learn more link (for future)
                    Button(action: {
                        // Future: Show more information about NeuroGuide
                        AccessibilityHelper.shared.buttonTap()
                        coordinator.presentModal(.info(
                            title: "About attune",
                            content: "attune is a neurodiversity-affirming app designed to support parents of neurodivergent children with real-time coaching, emotional awareness, and evidence-based guidance."
                        ))
                    }) {
                        Text("Learn More")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                    .accessibilityLabel("Learn More about attune")
                    .accessibilityHint("Double tap to learn more about the app")
                    .accessibilityIdentifier("welcome_learn_more_button")
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Inject coordinator into view model
            viewModel.coordinator = coordinator

            // Announce screen to VoiceOver
            AccessibilityHelper.announce("Welcome to attune")
        }
    }
}

// MARK: - Preview Provider

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default preview
            WelcomeView()
                .environmentObject(AppCoordinator())
                .previewDisplayName("Default")

            // Dark mode preview
            WelcomeView()
                .environmentObject(AppCoordinator())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")

            // Large text preview
            WelcomeView()
                .environmentObject(AppCoordinator())
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Large Text")

            // Small screen (iPhone SE)
            WelcomeView()
                .environmentObject(AppCoordinator())
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("iPhone SE")
        }
    }
}
