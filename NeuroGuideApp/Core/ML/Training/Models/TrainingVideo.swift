//
//  TrainingVideo.swift
//  NeuroGuide
//
//  Custom ML Training Infrastructure
//  Training video data model for per-child arousal state training
//

import Foundation

/// Represents a single training video with labeled arousal state
struct TrainingVideo: Identifiable, Codable {
    let id: UUID
    let childID: UUID
    let arousalState: ArousalState
    let videoURL: URL
    let duration: TimeInterval
    let recordedAt: Date
    var isProcessed: Bool
    var featureExtractionStatus: FeatureExtractionStatus

    init(
        id: UUID = UUID(),
        childID: UUID,
        arousalState: ArousalState,
        videoURL: URL,
        duration: TimeInterval,
        recordedAt: Date = Date(),
        isProcessed: Bool = false,
        featureExtractionStatus: FeatureExtractionStatus = .pending
    ) {
        self.id = id
        self.childID = childID
        self.arousalState = arousalState
        self.videoURL = videoURL
        self.duration = duration
        self.recordedAt = recordedAt
        self.isProcessed = isProcessed
        self.featureExtractionStatus = featureExtractionStatus
    }
}

/// Arousal state labels for training
enum ArousalState: String, Codable, CaseIterable {
    case calm = "calm"           // Maps to: green
    case playful = "playful"     // Maps to: green/yellow
    case upset = "upset"         // Maps to: yellow/orange
    case angry = "angry"         // Maps to: orange/red
    case meltdown = "meltdown"   // Maps to: red

    var displayName: String {
        switch self {
        case .calm:
            return "Calm & Regulated"
        case .playful:
            return "Playful & Energetic"
        case .upset:
            return "Upset & Distressed"
        case .angry:
            return "Angry & Escalating"
        case .meltdown:
            return "Meltdown & Crisis"
        }
    }

    var description: String {
        switch self {
        case .calm:
            return "Child is calm, regulated, content. Green zone behavior."
        case .playful:
            return "Child is playful, active, happy. Elevated energy but positive."
        case .upset:
            return "Child is upset, frustrated, distressed. Early warning signs."
        case .angry:
            return "Child is angry, agitated, escalating. High arousal, needs support."
        case .meltdown:
            return "Child is in meltdown, crisis mode. Safety priority."
        }
    }

    var emoji: String {
        switch self {
        case .calm:
            return "😌"
        case .playful:
            return "😊"
        case .upset:
            return "😟"
        case .angry:
            return "😠"
        case .meltdown:
            return "😭"
        }
    }

    /// Map training state to arousal band for threshold tuning
    var primaryArousalBand: ArousalBand {
        switch self {
        case .calm:
            return .green
        case .playful:
            return .yellow
        case .upset:
            return .yellow
        case .angry:
            return .orange
        case .meltdown:
            return .red
        }
    }

    /// Expected arousal score range (0-1) for this state
    var expectedArousalRange: ClosedRange<Double> {
        switch self {
        case .calm:
            return 0.25...0.45
        case .playful:
            return 0.45...0.60
        case .upset:
            return 0.55...0.70
        case .angry:
            return 0.70...0.85
        case .meltdown:
            return 0.85...1.0
        }
    }
}

/// Feature extraction status for training video
enum FeatureExtractionStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing..."
        case .completed:
            return "Ready"
        case .failed:
            return "Failed"
        }
    }
}

/// Training dataset for a specific child
struct TrainingDataset: Codable {
    let childID: UUID
    var videos: [TrainingVideo]
    var lastUpdated: Date
    var version: Int

    init(childID: UUID, videos: [TrainingVideo] = [], version: Int = 1) {
        self.childID = childID
        self.videos = videos
        self.lastUpdated = Date()
        self.version = version
    }

    /// Check if dataset has minimum videos per state for training
    func meetsMinimumRequirements(minimumPerState: Int = 5) -> Bool {
        let counts = videoCounts()
        return ArousalState.allCases.allSatisfy { state in
            (counts[state] ?? 0) >= minimumPerState
        }
    }

    /// Get count of videos per arousal state
    func videoCounts() -> [ArousalState: Int] {
        var counts: [ArousalState: Int] = [:]
        for video in videos {
            counts[video.arousalState, default: 0] += 1
        }
        return counts
    }

    /// Get training progress (0-1) based on recommended video count
    func trainingProgress(recommendedPerState: Int = 10) -> Double {
        let counts = videoCounts()
        let totalCurrent = counts.values.reduce(0, +)
        let totalRecommended = ArousalState.allCases.count * recommendedPerState
        return min(Double(totalCurrent) / Double(totalRecommended), 1.0)
    }

    /// Check if ready to train (has minimum videos)
    var isReadyToTrain: Bool {
        return meetsMinimumRequirements(minimumPerState: 5)
    }

    /// Total number of training videos
    var totalVideoCount: Int {
        return videos.count
    }

    /// Total duration of all training videos
    var totalDuration: TimeInterval {
        return videos.reduce(0) { $0 + $1.duration }
    }
}

/// Custom ML model metadata
struct CustomArousalModel: Codable, Identifiable {
    let id: UUID
    let childID: UUID
    let modelURL: URL
    let trainedAt: Date
    let version: Int
    let accuracy: Double?
    let trainingVideoCount: Int
    let modelSize: Int64  // bytes

    init(
        id: UUID = UUID(),
        childID: UUID,
        modelURL: URL,
        trainedAt: Date = Date(),
        version: Int,
        accuracy: Double? = nil,
        trainingVideoCount: Int,
        modelSize: Int64
    ) {
        self.id = id
        self.childID = childID
        self.modelURL = modelURL
        self.trainedAt = trainedAt
        self.version = version
        self.accuracy = accuracy
        self.trainingVideoCount = trainingVideoCount
        self.modelSize = modelSize
    }

    var formattedAccuracy: String {
        guard let accuracy = accuracy else { return "N/A" }
        return String(format: "%.1f%%", accuracy * 100)
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: modelSize)
    }

    var daysAgo: Int {
        return Calendar.current.dateComponents([.day], from: trainedAt, to: Date()).day ?? 0
    }
}
