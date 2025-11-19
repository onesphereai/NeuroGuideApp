//
//  HomeView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import SwiftUI

/// Main home screen of the app
/// Displays feature cards, profile summary, and emergency access
struct HomeView: View {

    // MARK: - Environment

    @EnvironmentObject var coordinator: AppCoordinator

    // MARK: - State

    @StateObject private var viewModel: HomeViewModel

    // MARK: - Initialization

    init() {
        // Initialize view model (will receive coordinator via onAppear)
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // New purple gradient background matching design
                LinearGradient(
                    colors: [
                        Color.ngBackgroundGradientTop,
                        Color.ngBackgroundGradientBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Greeting Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.greetingMessage)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .accessibilityAddTraits(.isHeader)

                            Text("Tap a profile to begin support")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(viewModel.greetingMessage). Tap a profile to begin support.")
                        .accessibilityIdentifier("home_greeting_text")

                        // Profile Avatars Section
                        HStack(spacing: 24) {
                            ForEach(viewModel.allProfiles.prefix(3)) { profile in
                                VStack(spacing: 8) {
                                    Button(action: {
                                        AccessibilityHelper.shared.buttonTap()
                                        Task {
                                            await viewModel.selectProfile(profile)
                                        }
                                    }) {
                                        ZStack {
                                            // Selection indicator ring
                                            if viewModel.currentProfile?.id == profile.id {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 3)
                                                    .frame(width: 88, height: 88)
                                            }

                                            Circle()
                                                .fill(.white)
                                                .frame(width: 80, height: 80)
                                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                                            // Profile emoji/initial
                                            Text(profileEmoji(for: profile))
                                                .font(.system(size: 40))
                                        }
                                    }

                                    Text(profile.name)
                                        .font(.system(size: 15, weight: viewModel.currentProfile?.id == profile.id ? .bold : .semibold))
                                        .foregroundColor(.white)
                                }
                                .accessibilityLabel("\(profile.name)'s profile")
                                .accessibilityHint(viewModel.currentProfile?.id == profile.id ? "Currently selected" : "Double tap to select this profile")
                                .accessibilityAddTraits(viewModel.currentProfile?.id == profile.id ? [.isSelected] : [])
                            }

                            // Add profile button if less than 3 profiles
                            if viewModel.allProfiles.count < 3 {
                                VStack(spacing: 8) {
                                    Button(action: {
                                        AccessibilityHelper.shared.buttonTap()
                                        viewModel.createNewProfile()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(.white.opacity(0.3))
                                                .frame(width: 80, height: 80)

                                            Image(systemName: "plus")
                                                .font(.system(size: 30, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    Text("Add")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .accessibilityLabel("Add new profile")
                                .accessibilityHint("Double tap to create a new profile")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)

                        // Feature Cards Grid
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(viewModel.features) { feature in
                                FeatureCardView(feature: feature) {
                                    viewModel.handleFeatureTap(feature)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Emergency Access Button
                        EmergencyAccessButton {
                            viewModel.handleEmergencyAccess()
                        }
                        .padding(.horizontal, 20)

                        // Bottom padding for safe area
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.navigateToSettings()
                    }) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 36, height: 36)

                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Double tap to open settings")
                    .accessibilityIdentifier("home_settings_button")
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Inject coordinator into view model
            viewModel.coordinator = coordinator

            // Load profile
            Task {
                await viewModel.loadProfile()
            }

            // Announce screen to VoiceOver
            AccessibilityHelper.announce("\(viewModel.greetingMessage). Home screen.")
        }
    }

    // MARK: - Helper Methods

    private func profileEmoji(for profile: ChildProfile) -> String {
        // Use the profile's selected emoji if available, otherwise fall back to default emoji
        if let emoji = profile.profileEmoji, !emoji.isEmpty {
            return emoji
        }

        // Fallback: Generate a default emoji based on profile ID for consistency
        let defaultEmojis = ["👧🏽", "👦🏼", "👧🏻", "👦🏽", "🧒🏾", "👶🏼"]
        let index = abs(profile.id.hashValue) % defaultEmojis.count
        return defaultEmojis[index]
    }
}

// MARK: - Preview Provider

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default preview
            HomeView()
                .environmentObject(AppCoordinator())
                .previewDisplayName("Default")

            // Dark mode preview
            HomeView()
                .environmentObject(AppCoordinator())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")

            // Large text preview
            HomeView()
                .environmentObject(AppCoordinator())
                .environment(\.sizeCategory, .accessibilityLarge)
                .previewDisplayName("Large Text")

            // Small screen (iPhone SE)
            HomeView()
                .environmentObject(AppCoordinator())
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("iPhone SE")

            // iPad
            HomeView()
                .environmentObject(AppCoordinator())
                .previewDevice("iPad Pro (11-inch) (4th generation)")
                .previewDisplayName("iPad")
        }
    }
}
