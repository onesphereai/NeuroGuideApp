//
//  BaselineCalibrationViewModel.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 3 - Child Profile & Personalization (Baseline Calibration)
//

import Foundation
import AVFoundation
import Combine

/// View model for baseline calibration wizard
@MainActor
class BaselineCalibrationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var calibrationState: CalibrationState = .intro
    @Published var isRecording = false
    @Published var recordingProgress: Double = 0.0
    @Published var currentMovementEnergy: Double = 0.0
    @Published var currentPitch: Double = 0.0
    @Published var currentVolume: Double = 0.0
    @Published var detectedMovements: [String] = []
    @Published var completedCalibration: BaselineCalibration?
    @Published var errorMessage: String?
    @Published var parentNotes: String = ""

    // MARK: - Private Properties

    private let calibrationService: BaselineCalibrationService
    private let profileService: ChildProfileService
    private var cancellables = Set<AnyCancellable>()

    private var childProfile: ChildProfile?

    // MARK: - Initialization

    nonisolated init(
        calibrationService: BaselineCalibrationService = BaselineCalibrationService(),
        profileService: ChildProfileService = ChildProfileManager.shared
    ) {
        self.calibrationService = calibrationService
        self.profileService = profileService
    }

    func setup() {
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe calibration service state
        calibrationService.$isRecording
            .assign(to: &$isRecording)

        calibrationService.$recordingProgress
            .assign(to: &$recordingProgress)

        calibrationService.$currentMovementEnergy
            .assign(to: &$currentMovementEnergy)

        calibrationService.$currentPitch
            .assign(to: &$currentPitch)

        calibrationService.$currentVolume
            .assign(to: &$currentVolume)

        calibrationService.$detectedMovements
            .assign(to: &$detectedMovements)
    }

    func loadProfile() async {
        do {
            childProfile = try await profileService.getProfile()
        } catch {
            print("⚠️ No profile loaded: \(error)")
        }
    }

    // MARK: - State Management

    func startIntro() {
        calibrationState = .intro
    }

    func startInstructions() {
        calibrationState = .instructions
    }

    func startRecording() async {
        calibrationState = .recording
        errorMessage = nil

        do {
            let baseline = try await calibrationService.startCalibration()
            completedCalibration = baseline
            calibrationState = .review
        } catch {
            errorMessage = error.localizedDescription
            calibrationState = .error
            print("❌ Calibration failed: \(error)")
        }
    }

    func cancelRecording() {
        calibrationService.stopCalibration()
        calibrationState = .instructions
    }

    func retryCalibration() {
        errorMessage = nil
        completedCalibration = nil
        calibrationState = .instructions
    }

    func confirmAndSave() async {
        guard var calibration = completedCalibration else {
            errorMessage = "No calibration data to save"
            return
        }

        // Add parent notes if provided
        if !parentNotes.isEmpty {
            let existingNotes = calibration.notes ?? ""
            calibration = BaselineCalibration(
                calibratedAt: calibration.calibratedAt,
                movementBaseline: calibration.movementBaseline,
                vocalBaseline: calibration.vocalBaseline,
                expressionBaseline: calibration.expressionBaseline,
                notes: existingNotes + "\n\nParent notes: " + parentNotes
            )
        }

        do {
            // Update profile with new baseline
            guard var profile = childProfile else {
                throw ProfileError.profileNotFound
            }

            profile.baselineCalibration = calibration
            profile.updateTimestamp()

            try await profileService.updateProfile(profile: profile)

            calibrationState = .completed
            print("✅ Baseline calibration saved to profile")
        } catch {
            errorMessage = "Failed to save calibration: \(error.localizedDescription)"
            calibrationState = .error
        }
    }

    func skipCalibration() {
        calibrationState = .skipped
    }

    // MARK: - Camera Access

    func getCameraSession() -> AVCaptureSession? {
        return calibrationService.getCameraSession()
    }

    // MARK: - Helper Methods

    var childName: String {
        return childProfile?.name ?? "your child"
    }

    var formattedMovementEnergy: String {
        return String(format: "%.1f%%", currentMovementEnergy * 100)
    }

    var formattedPitch: String {
        return String(format: "%.0f Hz", currentPitch)
    }

    var formattedVolume: String {
        return String(format: "%.0f dB", currentVolume)
    }

    var progressPercentage: String {
        return String(format: "%.0f%%", recordingProgress * 100)
    }
}

// MARK: - Calibration State

enum CalibrationState {
    case intro          // Welcome and explanation
    case instructions   // Detailed instructions before recording
    case recording      // Active recording in progress
    case review         // Review recorded baseline
    case completed      // Successfully saved
    case skipped        // User chose to skip
    case error          // Error occurred
}
