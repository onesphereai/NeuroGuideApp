//
//  TrainingDataManager.swift
//  NeuroGuide
//
//  Manages training videos and datasets for custom ML models
//

import Foundation
import Combine

/// Manages training video collection and dataset preparation
@MainActor
class TrainingDataManager: ObservableObject {
    // MARK: - Singleton

    static let shared = TrainingDataManager()

    // MARK: - Published Properties

    @Published private(set) var currentDataset: TrainingDataset?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var trainingProgress: Double = 0.0

    // MARK: - Private Properties

    private let secureStorage: SecureStorageService
    private let fileManager = FileManager.default

    // Storage keys
    private let datasetStorageKey = "training.dataset"
    private let videosDirectoryName = "TrainingVideos"

    // Configuration
    private let minimumVideosPerState = 5
    private let recommendedVideosPerState = 10
    private let maxVideoAge: TimeInterval = 90 * 24 * 60 * 60  // 90 days

    // MARK: - Initialization

    private init(secureStorage: SecureStorageService = SecureStorageManager.shared) {
        self.secureStorage = secureStorage
        createVideosDirectoryIfNeeded()
    }

    // MARK: - Dataset Management

    /// Load training dataset for a child
    func loadDataset(for childID: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        let key = "\(datasetStorageKey).\(childID.uuidString)"

        do {
            if let dataset = try await secureStorage.load(forKey: key, as: TrainingDataset.self) {
                currentDataset = dataset
                updateProgress()
                print("✅ Loaded training dataset: \(dataset.totalVideoCount) videos")

                // Clean up any orphaned references (files that don't exist)
                try? await cleanupOrphanedReferences()
            } else {
                // No dataset found - create new one
                let newDataset = TrainingDataset(childID: childID)
                currentDataset = newDataset
                trainingProgress = 0.0
                print("📝 Created new training dataset for child \(childID)")
            }
        } catch {
            // No dataset exists yet - create new one
            let newDataset = TrainingDataset(childID: childID)
            currentDataset = newDataset
            trainingProgress = 0.0
            print("📝 Created new training dataset for child \(childID)")
        }
    }

    /// Save current dataset
    func saveDataset() async throws {
        guard let dataset = currentDataset else {
            throw TrainingDataError.noDatasetLoaded
        }

        isLoading = true
        defer { isLoading = false }

        let key = "\(datasetStorageKey).\(dataset.childID.uuidString)"
        try await secureStorage.save(dataset, forKey: key)
        print("✅ Saved training dataset: \(dataset.totalVideoCount) videos")
    }

    /// Delete dataset for a child
    func deleteDataset(for childID: UUID) async throws {
        let key = "\(datasetStorageKey).\(childID.uuidString)"
        try await secureStorage.delete(forKey: key)

        // Delete all video files
        if let dataset = currentDataset, dataset.childID == childID {
            for video in dataset.videos {
                try? fileManager.removeItem(at: video.videoURL)
            }
            currentDataset = nil
            trainingProgress = 0.0
        }

        print("✅ Deleted training dataset for child \(childID)")
    }

    // MARK: - Video Management

    /// Add a new training video
    func addVideo(
        childID: UUID,
        arousalState: ArousalState,
        videoURL: URL,
        duration: TimeInterval
    ) async throws {
        // Ensure dataset is loaded
        if currentDataset == nil || currentDataset?.childID != childID {
            try await loadDataset(for: childID)
        }

        guard var dataset = currentDataset else {
            throw TrainingDataError.noDatasetLoaded
        }

        // Move video to permanent storage
        let permanentURL = try moveVideoToPermanentStorage(videoURL, childID: childID)

        // Create training video
        let trainingVideo = TrainingVideo(
            childID: childID,
            arousalState: arousalState,
            videoURL: permanentURL,
            duration: duration
        )

        // Add to dataset
        dataset.videos.append(trainingVideo)
        dataset.lastUpdated = Date()
        currentDataset = dataset

        // Save dataset
        try await saveDataset()

        updateProgress()
        print("✅ Added training video: \(arousalState.displayName) (\(duration)s)")
    }

    /// Delete a training video
    func deleteVideo(_ video: TrainingVideo) async throws {
        guard var dataset = currentDataset else {
            throw TrainingDataError.noDatasetLoaded
        }

        // Remove from dataset
        dataset.videos.removeAll { $0.id == video.id }
        dataset.lastUpdated = Date()
        currentDataset = dataset

        // Delete video file
        try? fileManager.removeItem(at: video.videoURL)

        // Save dataset
        try await saveDataset()

        updateProgress()
        print("✅ Deleted training video: \(video.arousalState.displayName)")
    }

    /// Clear all training videos for a child
    func clearAllVideos(for childID: UUID) async throws {
        guard var dataset = currentDataset else {
            throw TrainingDataError.noDatasetLoaded
        }

        guard dataset.childID == childID else {
            throw TrainingDataError.wrongProfile
        }

        let videoCount = dataset.videos.count
        print("🗑️ Clearing \(videoCount) training videos...")

        // Delete all video files
        for video in dataset.videos {
            try? fileManager.removeItem(at: video.videoURL)
        }

        // Clear dataset
        dataset.videos = []
        dataset.lastUpdated = Date()
        currentDataset = dataset

        // Save empty dataset
        try await saveDataset()

        updateProgress()
        print("✅ Cleared all \(videoCount) training videos")
    }

    /// Get videos for a specific arousal state
    func getVideos(for state: ArousalState) -> [TrainingVideo] {
        guard let dataset = currentDataset else { return [] }
        return dataset.videos.filter { $0.arousalState == state }
    }

    /// Get video count for each arousal state
    func getVideoCounts() -> [ArousalState: Int] {
        guard let dataset = currentDataset else {
            return Dictionary(uniqueKeysWithValues: ArousalState.allCases.map { ($0, 0) })
        }
        return dataset.videoCounts()
    }

    // MARK: - Training Readiness

    /// Check if dataset is ready for training
    var isReadyToTrain: Bool {
        return currentDataset?.isReadyToTrain ?? false
    }

    /// Get missing video counts per state
    func getMissingVideoCounts() -> [ArousalState: Int] {
        let counts = getVideoCounts()
        return Dictionary(uniqueKeysWithValues: ArousalState.allCases.map { state in
            let current = counts[state] ?? 0
            let needed = max(minimumVideosPerState - current, 0)
            return (state, needed)
        })
    }

    /// Get next arousal state that needs videos
    var nextStateToRecord: ArousalState? {
        let counts = getVideoCounts()
        // Find state with least videos
        return ArousalState.allCases
            .min(by: { (counts[$0] ?? 0) < (counts[$1] ?? 0) })
    }

    /// Get training readiness message
    var trainingReadinessMessage: String {
        guard let dataset = currentDataset else {
            return "No training data collected yet."
        }

        if dataset.isReadyToTrain {
            return "Ready to train! You have enough videos for all arousal states."
        } else {
            let missing = getMissingVideoCounts()
            let totalMissing = missing.values.reduce(0, +)
            return "Collect \(totalMissing) more video\(totalMissing == 1 ? "" : "s") to start training."
        }
    }

    // MARK: - Storage Management

    private func createVideosDirectoryIfNeeded() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosURL = documentsURL.appendingPathComponent(videosDirectoryName)

        if !fileManager.fileExists(atPath: videosURL.path) {
            try? fileManager.createDirectory(at: videosURL, withIntermediateDirectories: true)
            print("📁 Created training videos directory")
        }
    }

    private func moveVideoToPermanentStorage(_ tempURL: URL, childID: UUID) throws -> URL {
        // Validate that the video file exists and has content
        guard fileManager.fileExists(atPath: tempURL.path) else {
            print("❌ Temp video file does not exist: \(tempURL.path)")
            throw TrainingDataError.videoFileNotFound
        }

        // Check file size - video should be > 0 bytes
        guard let attributes = try? fileManager.attributesOfItem(atPath: tempURL.path),
              let fileSize = attributes[.size] as? Int64,
              fileSize > 0 else {
            print("❌ Video file is empty (0 bytes): \(tempURL.path)")
            print("   This usually means AVAssetWriter hasn't finished writing yet")
            throw TrainingDataError.videoFileEmpty
        }

        print("✅ Video file validated: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosURL = documentsURL.appendingPathComponent(videosDirectoryName)

        // Create child-specific subdirectory
        let childVideosURL = videosURL.appendingPathComponent(childID.uuidString)
        if !fileManager.fileExists(atPath: childVideosURL.path) {
            try fileManager.createDirectory(at: childVideosURL, withIntermediateDirectories: true)
        }

        // Generate unique filename
        let filename = "\(UUID().uuidString).mp4"
        let permanentURL = childVideosURL.appendingPathComponent(filename)

        // Move file
        try fileManager.moveItem(at: tempURL, to: permanentURL)

        print("📦 Moved video to permanent storage: \(permanentURL.lastPathComponent)")
        return permanentURL
    }

    /// Clean up old training videos
    func cleanupOldVideos() async throws {
        guard let dataset = currentDataset else { return }

        let cutoffDate = Date().addingTimeInterval(-maxVideoAge)
        let oldVideos = dataset.videos.filter { $0.recordedAt < cutoffDate }

        for video in oldVideos {
            try await deleteVideo(video)
        }

        if !oldVideos.isEmpty {
            print("✅ Cleaned up \(oldVideos.count) old training videos")
        }
    }

    /// Clean up orphaned video references (videos that don't exist on disk)
    func cleanupOrphanedReferences() async throws {
        guard var dataset = currentDataset else { return }

        print("🔍 Checking for orphaned video references...")

        // Find videos where file doesn't exist
        let orphanedVideos = dataset.videos.filter { video in
            !fileManager.fileExists(atPath: video.videoURL.path)
        }

        if orphanedVideos.isEmpty {
            print("✅ No orphaned references found")
            return
        }

        print("🗑️ Found \(orphanedVideos.count) orphaned video references")

        // Remove orphaned videos from dataset
        dataset.videos.removeAll { video in
            !fileManager.fileExists(atPath: video.videoURL.path)
        }
        dataset.lastUpdated = Date()
        currentDataset = dataset

        // Save cleaned dataset
        try await saveDataset()

        updateProgress()
        print("✅ Cleaned up \(orphanedVideos.count) orphaned references")

        // Print what was removed
        for video in orphanedVideos {
            print("   Removed: \(video.arousalState.displayName) - \(video.videoURL.lastPathComponent)")
        }
    }

    /// Get total storage used by training videos
    func getStorageUsed() -> Int64 {
        guard let dataset = currentDataset else { return 0 }

        var totalSize: Int64 = 0
        for video in dataset.videos {
            if let attributes = try? fileManager.attributesOfItem(atPath: video.videoURL.path),
               let size = attributes[.size] as? Int64 {
                totalSize += size
                print("📦 Video size: \(video.videoURL.lastPathComponent) = \(size) bytes")
            } else {
                print("⚠️ Could not get size for: \(video.videoURL.path)")
                print("   File exists: \(fileManager.fileExists(atPath: video.videoURL.path))")
            }
        }
        print("📊 Total storage: \(totalSize) bytes (\(dataset.videos.count) videos)")
        return totalSize
    }

    var formattedStorageUsed: String {
        let bytes = getStorageUsed()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Progress Tracking

    private func updateProgress() {
        guard let dataset = currentDataset else {
            trainingProgress = 0.0
            return
        }
        trainingProgress = dataset.trainingProgress(recommendedPerState: recommendedVideosPerState)
    }

    /// Get progress percentage string
    var progressPercentage: String {
        return String(format: "%.0f%%", trainingProgress * 100)
    }

    // MARK: - Statistics

    /// Get statistics for current dataset
    func getStatistics() -> TrainingStatistics? {
        guard let dataset = currentDataset else { return nil }

        return TrainingStatistics(
            totalVideos: dataset.totalVideoCount,
            totalDuration: dataset.totalDuration,
            videoCounts: dataset.videoCounts(),
            storageUsed: getStorageUsed(),
            isReadyToTrain: dataset.isReadyToTrain,
            lastUpdated: dataset.lastUpdated
        )
    }
}

// MARK: - Supporting Types

struct TrainingStatistics {
    let totalVideos: Int
    let totalDuration: TimeInterval
    let videoCounts: [ArousalState: Int]
    let storageUsed: Int64
    let isReadyToTrain: Bool
    let lastUpdated: Date

    var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return "\(minutes)m \(seconds)s"
    }

    var formattedStorageUsed: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: storageUsed)
    }

    var averageDuration: TimeInterval {
        return totalVideos > 0 ? totalDuration / Double(totalVideos) : 0
    }
}

// MARK: - Errors

enum TrainingDataError: LocalizedError {
    case noDatasetLoaded
    case videoNotFound
    case videoFileNotFound
    case videoFileEmpty
    case storageError(Error)
    case insufficientVideos
    case wrongProfile

    var errorDescription: String? {
        switch self {
        case .noDatasetLoaded:
            return "No training dataset loaded"
        case .videoNotFound:
            return "Training video not found"
        case .videoFileNotFound:
            return "Video file not found at temporary location. Recording may have failed."
        case .videoFileEmpty:
            return "Video file is empty (0 bytes). The video writer may not have finished writing. Please try recording again."
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        case .insufficientVideos:
            return "Not enough training videos collected"
        case .wrongProfile:
            return "Cannot clear videos for a different profile"
        }
    }
}
