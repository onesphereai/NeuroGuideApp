//
//  ProfileDetailView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Enhancement)
//

import SwiftUI

/// Detailed view of child profile
/// Shows all profile information with edit capability
struct ProfileDetailView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @StateObject private var viewModel: ProfileDetailViewModel
    @State private var showingEditSheet = false

    // MARK: - Initialization

    init(profile: ChildProfile) {
        _viewModel = StateObject(wrappedValue: ProfileDetailViewModel(profile: profile))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with photo
                    profileHeader

                    // Basic Info Section
                    infoSection

                    // Sensory Preferences Section
                    sensorySection

                    // Communication Section
                    communicationSection

                    // Triggers Section
                    triggersSection

                    // Strategies Section
                    strategiesSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Text("Edit")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Edit profile")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ProfileCreationWizardView(existingProfile: viewModel.profile)
        }
        .onChange(of: showingEditSheet) { isPresented in
            if !isPresented {
                // Reload profile after edit sheet dismisses
                Task {
                    await viewModel.reloadProfile()
                }
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Photo
            if let photoData = viewModel.profile.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                    )
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                    )
            }

            Text(viewModel.profile.name)
                .font(.title)
                .fontWeight(.bold)

            Text("\(viewModel.profile.age) years old")
                .font(.title3)
                .foregroundColor(.secondary)

            if let pronouns = viewModel.profile.pronouns, !pronouns.isEmpty {
                Text(pronouns)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        ProfileSectionCard(title: "Basic Information", icon: "person.fill") {
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(label: "Name", value: viewModel.profile.name)
                DetailRow(label: "Age", value: "\(viewModel.profile.age) years old")
                if let pronouns = viewModel.profile.pronouns, !pronouns.isEmpty {
                    DetailRow(label: "Pronouns", value: pronouns)
                }
                DetailRow(label: "Created", value: formatDate(viewModel.profile.createdAt))
                DetailRow(label: "Updated", value: formatDate(viewModel.profile.updatedAt))
            }
        }
    }

    // MARK: - Sensory Section

    private var sensorySection: some View {
        ProfileSectionCard(title: "Sensory Preferences", icon: "waveform") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(SenseType.allCases, id: \.self) { sense in
                    HStack {
                        Image(systemName: sense.icon)
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Text(sense.displayName)
                            .font(.body)
                            .frame(width: 100, alignment: .leading)

                        Spacer()

                        let profile = viewModel.profile.sensoryPreferences.get(for: sense)
                        Text(profile.rawValue)
                            .font(.body)
                            .foregroundColor(colorForProfile(profile))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorForProfile(profile).opacity(0.1))
                            )
                    }
                }

                if !viewModel.profile.sensoryPreferences.specificTriggers.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Specific Triggers")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        ForEach(viewModel.profile.sensoryPreferences.specificTriggers, id: \.self) { trigger in
                            Text("• \(trigger)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Communication Section

    private var communicationSection: some View {
        ProfileSectionCard(title: "Communication", icon: "bubble.left.and.bubble.right.fill") {
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(
                    label: "Mode",
                    value: viewModel.profile.communicationMode.rawValue.capitalized
                )

                if let notes = viewModel.profile.communicationNotes, !notes.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }

                let alexSettings = viewModel.profile.alexithymiaSettings
                if alexSettings.hasDifficultyNamingFeelings || alexSettings.preferBodyCues {
                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alexithymia Support")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if alexSettings.hasDifficultyNamingFeelings {
                            Text("• Difficulty naming feelings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if alexSettings.preferBodyCues {
                            Text("• Prefers body cues")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Triggers Section

    private var triggersSection: some View {
        ProfileSectionCard(title: "Known Triggers", icon: "exclamationmark.triangle.fill") {
            if viewModel.profile.triggers.isEmpty {
                Text("No triggers added yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.profile.triggers) { trigger in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: trigger.category.icon)
                                .foregroundColor(.orange)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(trigger.description)
                                    .font(.body)

                                Text(trigger.category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Strategies Section

    private var strategiesSection: some View {
        ProfileSectionCard(title: "Soothing Strategies", icon: "heart.fill") {
            if viewModel.profile.soothingStrategies.isEmpty {
                Text("No strategies added yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.profile.soothingStrategies) { strategy in
                        strategyRow(strategy)
                    }
                }
            }
        }
    }

    private func strategyRow(_ strategy: Strategy) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(strategy.description)
                    .font(.body)

                if strategy.effectivenessRating > 0 {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            let starValue = Double(star)
                            Image(systemName: starValue <= strategy.effectivenessRating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(starValue <= strategy.effectivenessRating ? .yellow : .gray)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }

    // MARK: - Baseline Section

    private var baselineSection: some View {
        ProfileSectionCard(title: "Baseline Calibration", icon: "chart.xyaxis.line") {
            if let baseline = viewModel.profile.baselineCalibration {
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Calibrated", value: formatDate(baseline.calibratedAt))

                    if baseline.isStale() {
                        Text("Baseline may need recalibration (older than 30 days)")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    } else {
                        Text("Baseline data is being used to provide personalized support")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func colorForProfile(_ profile: SensoryProfile) -> Color {
        switch profile {
        case .seeking:
            return .blue
        case .neutral:
            return .gray
        case .avoiding:
            return .orange
        }
    }
}

// MARK: - Supporting Views

struct ProfileSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview Provider

struct ProfileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileDetailView(profile: ChildProfile(
            name: "Sam",
            age: 5,
            pronouns: "they/them",
            photoData: nil
        ))
    }
}
