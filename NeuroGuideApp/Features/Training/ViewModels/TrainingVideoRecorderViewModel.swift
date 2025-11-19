//
//  TrainingVideoRecorderViewModel.swift
//  NeuroGuide
//
//  ViewModel for recording labeled training videos
//

import Foundation
import AVFoundation
import Combine

/// ViewModel for training video recording interface
@MainActor
class TrainingVideoRecorderViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var recordingState: RecordingState = .idle
    @Published var selectedArousalState: ArousalState = .calm
    @Published var countdown: Int = 0
    @Published var recordingProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var videoCounts: [ArousalState: Int] = [:]
    @Published var trainingProgress: Double = 0.0
    @Published var isReadyToTrain: Bool = false

    // MARK: - Private Properties

    private let trainingDataManager: TrainingDataManager
    private let recordingManager: SessionRecordingManager
    private let cameraService: CameraCaptureService
    private let profileManager: ChildProfileManager

    private var currentProfile: ChildProfile?
    private var recordingTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var videoOutputURL: URL?

    private let recordingDuration: TimeInterval = 10.0  // 10 seconds per video
    private let countdownDuration: Int = 3  // 3 second countdown

    // MARK: - Initialization

    init(
        trainingDataManager: TrainingDataManager = .shared,
        recordingManager: SessionRecordingManager = .shared,
        cameraService: CameraCaptureService = .shared,
        profileManager: ChildProfileManager = .shared
    ) {
        self.trainingDataManager = trainingDataManager
        self.recordingManager = recordingManager
        self.cameraService = cameraService
        self.profileManager = profileManager
    }

    // MARK: - Setup

    func setup() async {
        // Load current profile
        currentProfile = profileManager.currentProfile

        guard let profile = currentProfile else {
            errorMessage = "No child profile selected"
            return
        }

        // Load training dataset
        do {
            try await trainingDataManager.loadDataset(for: profile.id)
            updateStatistics()
        } catch {
            print("⚠️ Failed to load training dataset: \(error)")
        }

        // Start camera preview
        do {
            // First setup the camera hardware (back camera to record the child)
            try await cameraService.setup(position: .back)
            // Then start capture
            cameraService.startCapture { _ in
                // Preview only - no processing needed
            }
            print("✅ Camera started for training video recording")
        } catch {
            errorMessage = "Failed to start camera: \(error.localizedDescription)"
        }
    }

    func cleanup() {
        recordingTask?.cancel()
        countdownTask?.cancel()
        cameraService.stopCapture()
        Task { @MainActor in
            await recordingManager.stopRecording()
        }
    }

    // MARK: - Recording Control

    /// Start recording with countdown
    func startRecording() {
        guard currentProfile != nil else {
            errorMessage = "No child profile selected"
            return
        }

        guard recordingState == .idle else {
            return
        }

        errorMessage = nil
        recordingState = .countdown

        // Start countdown
        countdownTask = Task { @MainActor in
            await performCountdown()
        }
    }

    /// Cancel recording
    func cancelRecording() {
        recordingTask?.cancel()
        countdownTask?.cancel()
        Task { @MainActor in
            await recordingManager.stopRecording()
        }
        recordingState = .idle
        countdown = 0
        recordingProgress = 0.0
    }

    /// Save the recorded video with selected arousal state label
    func saveVideo() async {
        guard let profile = currentProfile,
              let videoURL = videoOutputURL else {
            errorMessage = "No video to save"
            return
        }

        recordingState = .saving

        do {
            try await trainingDataManager.addVideo(
                childID: profile.id,
                arousalState: selectedArousalState,
                videoURL: videoURL,
                duration: recordingDuration
            )

            print("✅ Saved training video: \(selectedArousalState.displayName)")

            // Update statistics
            updateStatistics()

            // Reset state
            recordingState = .idle
            recordingProgress = 0.0
            videoOutputURL = nil

            // Auto-select next state that needs videos
            if let nextState = trainingDataManager.nextStateToRecord {
                selectedArousalState = nextState
            }

        } catch {
            errorMessage = "Failed to save video: \(error.localizedDescription)"
            recordingState = .idle
        }
    }

    /// Discard the recorded video
    func discardVideo() {
        if let url = videoOutputURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingState = .idle
        recordingProgress = 0.0
        videoOutputURL = nil
    }

    // MARK: - Private Methods

    private func performCountdown() async {
        for i in (1...countdownDuration).reversed() {
            countdown = i
            try? await Task.sleep(for: .seconds(1))

            if Task.isCancelled {
                await MainActor.run {
                    recordingState = .idle
                    countdown = 0
                }
                return
            }
        }

        await startActualRecording()
    }

    private func startActualRecording() async {
        recordingState = .recording
        countdown = 0
        recordingProgress = 0.0

        // Get camera session
        let captureSession = cameraService.getCaptureSession()

        // Ensure any previous recording is stopped
        await recordingManager.stopRecording()

        // Start recording
        do {
            let (childURL, _) = try await recordingManager.startRecording(
                childSession: captureSession,
                parentSession: captureSession  // Use same session for single camera
            )

            videoOutputURL = childURL
            print("🎥 Recording started to: \(childURL.lastPathComponent)")

            // Record for 10 seconds with progress updates
            let startTime = Date()
            recordingTask = Task {
                // Just update progress - SessionRecordingManager will auto-stop at 10s
                while Date().timeIntervalSince(startTime) < recordingDuration {
                    let elapsed = Date().timeIntervalSince(startTime)

                    await MainActor.run {
                        recordingProgress = elapsed / recordingDuration
                    }

                    try? await Task.sleep(for: .milliseconds(100))

                    if Task.isCancelled {
                        // Manual cancel - stop recording
                        await recordingManager.stopRecording()
                        await MainActor.run {
                            recordingState = .idle
                        }
                        return
                    }
                }

                // Recording time complete - wait a moment for SessionRecordingManager to finish
                print("⏹️ Recording duration reached, waiting for session to finish...")
                try? await Task.sleep(for: .milliseconds(500))  // Give it time to finalize

                // Recording should be complete now, transition to review
                await MainActor.run {
                    if let url = videoOutputURL {
                        print("✅ Recording complete, video at: \(url.path)")
                        recordingState = .review
                        recordingProgress = 1.0
                    } else {
                        print("❌ Recording completed but videoOutputURL is nil")
                        errorMessage = "Recording completed but video file was not created"
                        recordingState = .idle
                    }
                }
            }

        } catch {
            await MainActor.run {
                errorMessage = "Recording failed: \(error.localizedDescription)"
                recordingState = .idle
            }
        }
    }

    private func updateStatistics() {
        videoCounts = trainingDataManager.getVideoCounts()
        trainingProgress = trainingDataManager.trainingProgress
        isReadyToTrain = trainingDataManager.isReadyToTrain
    }

    // MARK: - Helper Methods

    /// Get count for specific arousal state
    func getVideoCount(for state: ArousalState) -> Int {
        return videoCounts[state] ?? 0
    }

    /// Get progress for specific arousal state (out of 10 recommended)
    func getStateProgress(for state: ArousalState) -> Double {
        let count = getVideoCount(for: state)
        return min(Double(count) / 10.0, 1.0)
    }

    /// Check if state needs more videos
    func needsMoreVideos(for state: ArousalState) -> Bool {
        return getVideoCount(for: state) < 10
    }

    /// Get next recommended arousal state to record
    var nextRecommendedState: ArousalState? {
        return trainingDataManager.nextStateToRecord
    }

    /// Get training readiness message
    var readinessMessage: String {
        return trainingDataManager.trainingReadinessMessage
    }

    /// Get camera session for preview
    func getCameraSession() -> AVCaptureSession? {
        return cameraService.getCaptureSession()
    }
}

// MARK: - Recording State

enum RecordingState {
    case idle           // Ready to record
    case countdown      // 3...2...1...
    case recording      // Currently recording
    case review         // Review recorded video
    case saving         // Saving video to dataset

    var displayText: String {
        switch self {
        case .idle:
            return "Ready to Record"
        case .countdown:
            return "Get Ready..."
        case .recording:
            return "Recording..."
        case .review:
            return "Review Video"
        case .saving:
            return "Saving..."
        }
    }

    var canStartRecording: Bool {
        return self == .idle
    }

    var canCancel: Bool {
        return self == .countdown || self == .recording
    }

    var isRecording: Bool {
        return self == .recording
    }
}
