//
//  ProfileSelectionView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-11-03.
//  Unit 3 - Multi-Profile Support
//
//  Profile selection screen for multi-child families
//

import SwiftUI
import Combine

struct ProfileSelectionView: View {
    @StateObject private var viewModel = ProfileSelectionViewModel()
    @EnvironmentObject var navigationState: NavigationState

    var body: some View {
        NavigationView {
            ZStack {
                // Consistent purple gradient background
                LinearGradient(
                    colors: [
                        Color.ngBackgroundGradientTop,
                        Color.ngBackgroundGradientBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if viewModel.profiles.isEmpty {
                    emptyState
                } else {
                    profileGrid
                }
            }
            .navigationTitle("Select Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingCreateProfile = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 36, height: 36)

                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Create new profile")
                }
            }
            .sheet(isPresented: $viewModel.showingCreateProfile, onDismiss: {
                viewModel.loadProfiles()
            }) {
                ProfileCreationWizardView()
                    .environmentObject(navigationState)
            }
            .alert("Delete Profile", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.confirmDelete()
                }
            } message: {
                Text("Are you sure you want to delete \(viewModel.profileToDelete?.name ?? "")'s profile? This action cannot be undone.")
            }
            .onAppear {
                viewModel.loadProfiles()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 32) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text("No Profiles Yet")
                    .font(.system(size: 28, weight: .bold))

                Text("Create a profile to get started with personalized support for your child.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                viewModel.showingCreateProfile = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Create First Profile")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - Profile Grid

    private var profileGrid: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Modern Header
                VStack(spacing: 12) {
                    Text("Who are we supporting today?")
                        .font(.system(size: 26, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("\(viewModel.profiles.count) \(viewModel.profiles.count == 1 ? "profile" : "profiles")")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding(.top, 8)
                .padding(.horizontal)

                // Modern Profile Cards Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ], spacing: 20) {
                    ForEach(viewModel.profiles) { profile in
                        ProfileCard(
                            profile: profile,
                            onSelect: {
                                viewModel.selectProfile(profile)
                            },
                            onDelete: {
                                viewModel.requestDelete(profile)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Profile Card

struct ProfileCard: View {
    let profile: ChildProfile
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var showingOptions = false
    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                // Profile photo with modern styling
                ZStack(alignment: .topTrailing) {
                    // Photo/Initial circle
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: profile.profileColor) ?? .blue,
                                        (Color(hex: profile.profileColor) ?? .blue).opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)

                        if let photoData = profile.photoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                        } else {
                            Text(profile.name.prefix(1).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    // Modern options button
                    Button {
                        showingOptions = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 28, height: 28)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                            Image(systemName: "ellipsis")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .offset(x: -4, y: 4)
                }

                // Profile info with modern typography
                VStack(spacing: 8) {
                    Text(profile.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(profile.age) years old")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    // Modern diagnosis badge
                    if let diagnosisInfo = profile.diagnosisInfo,
                       !diagnosisInfo.diagnoses.isEmpty,
                       let firstDiagnosis = diagnosisInfo.diagnoses.first,
                       firstDiagnosis != .preferNotToSpecify {
                        Text(firstDiagnosis.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: profile.profileColor) ?? .blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill((Color(hex: profile.profileColor) ?? .blue).opacity(0.15))
                            )
                            .lineLimit(1)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThickMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                (Color(hex: profile.profileColor) ?? .blue).opacity(0.3),
                                (Color(hex: profile.profileColor) ?? .blue).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .confirmationDialog("Profile Options", isPresented: $showingOptions) {
            Button("View/Edit Profile") {
                // Navigate to profile detail
            }
            Button("Delete Profile", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - View Model

@MainActor
class ProfileSelectionViewModel: ObservableObject {
    @Published var profiles: [ChildProfile] = []
    @Published var showingCreateProfile = false
    @Published var showingDeleteConfirmation = false
    @Published var profileToDelete: ChildProfile?

    private let profileService: ChildProfileService = ChildProfileManager.shared

    func loadProfiles() {
        Task {
            do {
                profiles = try await profileService.getAllProfiles()
                print("📋 Loaded \(profiles.count) profiles")
            } catch {
                print("❌ Failed to load profiles: \(error)")
            }
        }
    }

    func selectProfile(_ profile: ChildProfile) {
        Task {
            do {
                // Set as active profile
                try await profileService.setActiveProfile(profile)
                print("✅ Selected profile: \(profile.name)")

                // Navigate to home
                await MainActor.run {
                    NavigationState.shared.currentScreen = .home
                }
            } catch {
                print("❌ Failed to select profile: \(error)")
            }
        }
    }

    func requestDelete(_ profile: ChildProfile) {
        profileToDelete = profile
        showingDeleteConfirmation = true
    }

    func confirmDelete() {
        guard let profile = profileToDelete else { return }

        Task {
            do {
                try await profileService.deleteProfile(id: profile.id)
                await loadProfiles()
                print("✅ Deleted profile: \(profile.name)")
            } catch {
                print("❌ Failed to delete profile: \(error)")
            }
        }

        profileToDelete = nil
    }
}

// MARK: - Preview

struct ProfileSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSelectionView()
            .environmentObject(NavigationState.shared)
    }
}
