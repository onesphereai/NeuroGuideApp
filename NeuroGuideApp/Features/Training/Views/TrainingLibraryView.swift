//
//  TrainingLibraryView.swift
//  NeuroGuide
//
//  View for reviewing collected training videos and managing training data
//

import SwiftUI

struct TrainingLibraryView: View {
    @StateObject private var trainingDataManager = TrainingDataManager.shared
    @StateObject private var profileManager = ChildProfileManager.shared
    @EnvironmentObject var navigationState: NavigationState
    @State private var showingRecorder = false
    @State private var showingModelTraining = false
    @State private var selectedState: ArousalState?
    @State private var showingDeleteConfirmation = false
    @State private var videoToDelete: TrainingVideo?
    @State private var showingClearAllConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    if let stats = trainingDataManager.getStatistics() {
                        statsCard(stats)
                    }

                    // Training Progress
                    trainingProgressSection

                    // Videos by Arousal State
                    videosByStateSection

                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Training Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        navigationState.currentScreen = .home
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingRecorder = true }) {
                        Label("Record", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingRecorder) {
                TrainingVideoRecorderView()
            }
            .sheet(isPresented: $showingModelTraining) {
                ModelTrainingView()
            }
            .confirmationDialog(
                "Delete Video?",
                isPresented: $showingDeleteConfirmation,
                presenting: videoToDelete
            ) { video in
                Button("Delete", role: .destructive) {
                    Task {
                        try? await trainingDataManager.deleteVideo(video)
                    }
                }
            } message: { video in
                Text("Are you sure you want to delete this \(video.arousalState.displayName) video?")
            }
            .confirmationDialog(
                "Clear All Training Data?",
                isPresented: $showingClearAllConfirmation
            ) {
                Button("Clear All", role: .destructive) {
                    Task {
                        if let profile = profileManager.currentProfile {
                            try? await trainingDataManager.clearAllVideos(for: profile.id)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(trainingDataManager.currentDataset?.totalVideoCount ?? 0) training videos. This action cannot be undone.")
            }
        }
        .task {
            if let profile = profileManager.currentProfile {
                try? await trainingDataManager.loadDataset(for: profile.id)
            }
        }
    }

    // MARK: - Stats Card

    private func statsCard(_ stats: TrainingStatistics) -> some View {
        VStack(spacing: 16) {
            // Total Stats
            HStack(spacing: 40) {
                TrainingStatItem(
                    icon: "video.fill",
                    title: "Videos",
                    value: "\(stats.totalVideos)"
                )

                TrainingStatItem(
                    icon: "clock.fill",
                    title: "Duration",
                    value: stats.formattedDuration
                )

                TrainingStatItem(
                    icon: "externaldrive.fill",
                    title: "Storage",
                    value: stats.formattedStorageUsed
                )
            }

            Divider()

            // Training Status
            HStack {
                Image(systemName: trainingDataManager.isReadyToTrain ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(trainingDataManager.isReadyToTrain ? .green : .orange)

                Text(trainingDataManager.trainingReadinessMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // MARK: - Training Progress Section

    private var trainingProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collection Progress")
                .font(.headline)

            ProgressView(value: trainingDataManager.trainingProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: trainingDataManager.isReadyToTrain ? .green : .blue))

            Text("\(Int(trainingDataManager.trainingProgress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Videos by State Section

    private var videosByStateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Videos by Arousal State")
                .font(.headline)

            ForEach(ArousalState.allCases, id: \.self) { state in
                stateRow(for: state)
            }
        }
    }

    private func stateRow(for state: ArousalState) -> some View {
        VStack(spacing: 12) {
            // State Header
            HStack {
                Text(state.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.displayName)
                        .font(.headline)

                    Text(state.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Count badge
                Text("\(trainingDataManager.getVideos(for: state).count)/10")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        trainingDataManager.getVideos(for: state).count >= 10 ?
                            Color.green.opacity(0.2) :
                            Color.blue.opacity(0.2)
                    )
                    .foregroundColor(
                        trainingDataManager.getVideos(for: state).count >= 10 ?
                            .green :
                            .blue
                    )
                    .cornerRadius(8)
            }

            // Videos list
            let videos = trainingDataManager.getVideos(for: state)
            if !videos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(videos) { video in
                            VideoThumbnail(video: video) {
                                videoToDelete = video
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                }
            } else {
                Text("No videos yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Record More button
            Button(action: { showingRecorder = true }) {
                HStack {
                    Image(systemName: "video.badge.plus")
                    Text("Record More Videos")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Train Model button (if ready)
            if trainingDataManager.isReadyToTrain {
                Button(action: { showingModelTraining = true }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Train Custom Model")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }

            // Clear All button
            Button(role: .destructive, action: {
                showingClearAllConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear All Training Data")
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Training Stat Item

struct TrainingStatItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Video Thumbnail

struct VideoThumbnail: View {
    let video: TrainingVideo
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail (placeholder for now)
            Rectangle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .overlay(
                    VStack {
                        Image(systemName: "video.fill")
                            .font(.title)
                            .foregroundColor(.blue)

                        Text("\(Int(video.duration))s")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                )

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            .padding(4)
        }
    }
}

// MARK: - Preview

#Preview {
    TrainingLibraryView()
        .environmentObject(NavigationState.shared)
}
