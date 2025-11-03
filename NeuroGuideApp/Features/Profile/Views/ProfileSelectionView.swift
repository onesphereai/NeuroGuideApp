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
                Color(.systemGroupedBackground)
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
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
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
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.3))

            Text("No Profiles Yet")
                .font(.title.bold())

            Text("Create a profile to get started with personalized support for your child.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                viewModel.showingCreateProfile = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First Profile")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
    }

    // MARK: - Profile Grid

    private var profileGrid: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Who are we supporting today?")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("\(viewModel.profiles.count) \(viewModel.profiles.count == 1 ? "profile" : "profiles")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.horizontal)

                // Profile cards grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
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
                .padding(.horizontal)

                Spacer(minLength: 20)
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

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Profile photo or placeholder
                ZStack {
                    Circle()
                        .fill(Color(hex: profile.profileColor) ?? .blue)
                        .frame(width: 80, height: 80)

                    if let photoData = profile.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Text(profile.name.prefix(1).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // Options button
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showingOptions = true
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .padding(4)
                        }
                        Spacer()
                    }
                }

                // Profile info
                VStack(spacing: 4) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(profile.age) years old")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Diagnosis badge if present
                    if let diagnosis = profile.diagnosisInfo?.primaryDiagnosis,
                       diagnosis != .preferNotToSpecify {
                        Text(diagnosis.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: profile.profileColor)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                            .cornerRadius(8)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
