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
            ScrollView {
                VStack(spacing: 24) {
                    // Greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.greetingMessage)
                                .font(.system(size: 28, weight: .bold))
                                .accessibilityAddTraits(.isHeader)

                            Text("How can we support you today?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(viewModel.greetingMessage). How can we support you today?")
                    .accessibilityIdentifier("home_greeting_text")

                    // Profile Summary (if applicable)
                    if viewModel.shouldShowProfileSummary, let profile = viewModel.currentProfile {
                        ProfileSummaryView(profile: profile)
                            .padding(.horizontal, 20)
                            .onTapGesture {
                                AccessibilityHelper.shared.buttonTap()
                                coordinator.showProfileDetail(profile: profile)
                            }
                    }

                    // Feature Cards
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
                    .padding(.top, 8)

                    // Bottom padding for safe area
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.top, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.navigateToSettings()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
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
