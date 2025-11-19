//
//  NeuroGuideApp.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import SwiftUI

/// Main app entry point
/// Manages app lifecycle and dependency injection
@main
struct NeuroGuideApp: App {

    // MARK: - State Objects

    /// Root coordinator managing navigation and app state
    @StateObject private var appCoordinator = AppCoordinator()

    /// App lock manager for biometric authentication
    @StateObject private var appLockManager = AppLockManager.shared

    /// Theme manager for light/dark mode
    @StateObject private var themeManager = ThemeManager.shared

    // MARK: - Initialization

    init() {
        // Configure app-wide settings
        configureAppearance()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appCoordinator)
                .environmentObject(appCoordinator.navigationState)
                .environmentObject(appCoordinator.launchStateManager)
                .environmentObject(appLockManager)
                .environmentObject(themeManager)
                .applyTheme(themeManager)
                .onAppear {
                    appCoordinator.start()
                    Task {
                        await appLockManager.checkLockOnLaunch()
                    }
                }
        }
    }

    // MARK: - Private Methods

    /// Configure app-wide appearance settings
    private func configureAppearance() {
        // Future: Configure navigation bar appearance, colors, etc.
        // For Bolt 1.1, we keep it simple
    }
}

// MARK: - Root View

/// Root view that determines which screen to show based on navigation state
struct RootView: View {

    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var appLockManager: AppLockManager

    var body: some View {
        ZStack {
            // Main screen based on current navigation state
            Group {
                switch navigationState.currentScreen {
                case .welcome:
                    WelcomeView()
                case .profileSelection:
                    ProfileSelectionView()
                case .home:
                    HomeView()
                case .settings:
                    SettingsView()
                case .liveCoach:
                    LiveCoachView()
                case .askQuestion:
                    AskNeuroGuideView()
                case .sessionHistory:
                    SessionHistoryListView()
                case .trainingLibrary:
                    TrainingLibraryView()
                case .emotionCheck, .profile:
                    // These screens will be implemented in future Bolts
                    // For now, show placeholder
                    PlaceholderView(screenName: "\(navigationState.currentScreen)")
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: navigationState.currentScreen)
            .blur(radius: appLockManager.showLockScreen ? 20 : 0)

            // App Lock Overlay
            if appLockManager.showLockScreen {
                AppLockView(lockManager: appLockManager)
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .sheet(item: $navigationState.presentedModal) { modal in
            ModalView(modal: modal)
        }
        .animation(.easeInOut(duration: 0.3), value: appLockManager.showLockScreen)
    }
}

// MARK: - Placeholder View

/// Placeholder view for screens not yet implemented
struct PlaceholderView: View {
    let screenName: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.circle")
                .font(.system(size: 72))
                .foregroundColor(.secondary)

            Text("Coming Soon")
                .font(.title)
                .fontWeight(.bold)

            Text(screenName)
                .font(.body)
                .foregroundColor(.secondary)

            Text("This feature will be available in a future update.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(screenName) coming soon. This feature will be available in a future update.")
    }
}

// MARK: - Modal View

/// Generic modal view for presenting info, alerts, and confirmations
struct ModalView: View {
    let modal: Modal

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        // Handle special modals separately
        if case .onboarding = modal {
            OnboardingView(viewModel: OnboardingViewModel(coordinator: coordinator))
        } else if case .emergencyResources = modal {
            EmergencyResourcesView()
        } else if case .profileCreation = modal {
            ProfileCreationWizardView()
        } else if case .profileDetail(let profile) = modal {
            ProfileDetailView(profile: profile)
        } else {
            // Standard modal presentation for alerts, confirmations, and info
            NavigationView {
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: iconName)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 40)

                    // Title
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    // Content
                    Text(content)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 32)

                    Spacer()

                    // Actions
                    VStack(spacing: 12) {
                        if case .confirmation(_, _, let action) = modal {
                            Button(action: {
                                action()
                                dismiss()
                            }) {
                                Text("Confirm")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .accessibilityLabel("Confirm")
                            .accessibilityIdentifier("modal_confirm_button")
                        }

                        Button(action: {
                            AccessibilityHelper.shared.buttonTap()
                            dismiss()
                        }) {
                            Text(dismissButtonTitle)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .accessibilityLabel(dismissButtonTitle)
                        .accessibilityIdentifier("modal_dismiss_button")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            AccessibilityHelper.shared.buttonTap()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .accessibilityLabel("Close")
                        .accessibilityIdentifier("modal_close_button")
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var title: String {
        switch modal {
        case .alert(let title, _), .confirmation(let title, _, _), .info(let title, _):
            return title
        case .onboarding, .emergencyResources, .profileCreation, .profileDetail:
            return "" // Not used for special modals
        }
    }

    private var content: String {
        switch modal {
        case .alert(_, let message), .confirmation(_, let message, _):
            return message
        case .info(_, let content):
            return content
        case .onboarding, .emergencyResources, .profileCreation, .profileDetail:
            return "" // Not used for special modals
        }
    }

    private var iconName: String {
        switch modal {
        case .alert:
            return "exclamationmark.triangle"
        case .confirmation:
            return "questionmark.circle"
        case .info:
            return "info.circle"
        case .onboarding, .emergencyResources, .profileCreation, .profileDetail:
            return "" // Not used for special modals
        }
    }

    private var dismissButtonTitle: String {
        switch modal {
        case .confirmation:
            return "Cancel"
        case .onboarding, .emergencyResources, .profileCreation, .profileDetail:
            return "" // Not used for special modals
        default:
            return "OK"
        }
    }
}
