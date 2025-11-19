//
//  BaselineCalibrationService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 3 - Child Profile & Personalization (Baseline Calibration)
//

import Foundation
import AVFoundation
import CoreImage
import Combine

/// Service for capturing and analyzing baseline calibration data
/// Records child's typical arousal patterns during calm moments
@MainActor
class BaselineCalibrationService: ObservableObject {

    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var recordingProgress: Double = 0.0
    @Published var currentMovementEnergy: Double = 0.0
    @Published var currentPitch: Double = 0.0
    @Published var currentVolume: Double = 0.0
    @Published var detectedMovements: [String] = []

    // MARK: - Private Properties

    private let poseService: PoseDetectionService
    private let facialService: FacialExpressionService
    private let vocalService: VocalAffectService
    private let cameraService: CameraCaptureService
    private let audioService: AudioCaptureService

    private var calibrationTask: Task<BaselineCalibration, Error>?
    private var frameProcessor: Task<Void, Never>?

    // Accumulated data during recording
    private var movementSamples: [Double] = []
    private var pitchSamples: [Double] = []
    private var volumeSamples: [Double] = []
    private var expressionSamples: [ExpressionSample] = []
    private var observedBehaviors: Set<String> = []

    private let recordingDuration: TimeInterval
    private var recordingStartTime: Date?

    // MARK: - Initialization

    nonisolated init(
        recordingDuration: TimeInterval = 10.0,
        poseService: PoseDetectionService = .shared,
        facialService: FacialExpressionService = .shared,
        vocalService: VocalAffectService = .shared,
        cameraService: CameraCaptureService = .shared,
        audioService: AudioCaptureService = .shared
    ) {
        self.recordingDuration = recordingDuration
        self.poseService = poseService
        self.facialService = facialService
        self.vocalService = vocalService
        self.cameraService = cameraService
        self.audioService = audioService
    }

    // MARK: - Calibration Recording

    /// Start baseline calibration recording
    /// - Returns: Completed baseline calibration data after recording duration
    func startCalibration() async throws -> BaselineCalibration {
        guard !isRecording else {
            throw CalibrationError.alreadyRecording
        }

        print("🎯 Starting baseline calibration recording...")

        // Reset accumulated data
        movementSamples.removeAll()
        pitchSamples.removeAll()
        volumeSamples.removeAll()
        expressionSamples.removeAll()
        observedBehaviors.removeAll()

        isRecording = true
        recordingStartTime = Date()
        recordingProgress = 0.0

        // Ensure cleanup happens even if error occurs
        defer {
            isRecording = false
            stopCapture()
        }

        // Start camera and audio capture
        try await startCapture()

        // Create calibration task
        calibrationTask = Task {
            return try await performCalibration()
        }

        // Wait for completion
        let result = try await calibrationTask!.value

        print("✅ Baseline calibration complete")
        return result
    }

    /// Stop calibration early
    func stopCalibration() {
        calibrationTask?.cancel()
        frameProcessor?.cancel()
        stopCapture()
        isRecording = false
        recordingProgress = 0.0
    }

    // MARK: - Capture Management

    private func startCapture() async throws {
        // Start camera
        try cameraService.startCapture { [weak self] frame in
            Task { @MainActor in
                await self?.processFrame(frame)
            }
        }

        // Start audio
        try audioService.startCapture { _ in
            // Audio buffers handled via getLatestBuffer()
        }
    }

    private func stopCapture() {
        cameraService.stopCapture()
        audioService.stopCapture()
    }

    // MARK: - Frame Processing

    private func processFrame(_ cgImage: CGImage) async {
        guard isRecording else { return }

        // Extract pose features
        if let poseFeatures = try? await poseService.extractPoseFeatures(from: cgImage) {
            movementSamples.append(poseFeatures.movementIntensity)
            currentMovementEnergy = poseFeatures.movementIntensity

            // Detect potential stim behaviors based on movement patterns
            detectBehaviors(from: poseFeatures)
        }

        // Extract facial features
        if let facialFeatures = try? await facialService.extractFacialFeatures(from: cgImage) {
            expressionSamples.append(ExpressionSample(
                intensity: facialFeatures.expressionIntensity,
                mouthOpenness: facialFeatures.mouthOpenness,
                eyeWideness: facialFeatures.eyeWideness
            ))
        }

        // Get audio features
        if let audioBuffer = audioService.getLatestBuffer(),
           let vocalFeatures = try? await vocalService.extractVocalFeatures(from: audioBuffer) {
            pitchSamples.append(vocalFeatures.pitch)
            volumeSamples.append(vocalFeatures.volume)
            currentPitch = vocalFeatures.pitch
            currentVolume = vocalFeatures.volume
        }
    }

    private func detectBehaviors(from pose: PoseFeatures) {
        // Heuristic detection of common movements
        // In production, would use more sophisticated pattern recognition

        if pose.movementIntensity > 0.7 {
            observedBehaviors.insert("High movement energy")
        }

        if pose.bodyTension > 0.7 {
            observedBehaviors.insert("Tense posture")
        } else if pose.bodyTension < 0.3 {
            observedBehaviors.insert("Relaxed posture")
        }

        if pose.postureOpenness > 0.7 {
            observedBehaviors.insert("Open posture")
        }

        // Update detected movements list for UI
        detectedMovements = Array(observedBehaviors)
    }

    // MARK: - Calibration Analysis

    private func performCalibration() async throws -> BaselineCalibration {
        let startTime = Date()

        // Monitor progress
        while Date().timeIntervalSince(startTime) < recordingDuration {
            let elapsed = Date().timeIntervalSince(startTime)
            await MainActor.run {
                recordingProgress = elapsed / recordingDuration
            }

            try await Task.sleep(for: .milliseconds(100))

            if Task.isCancelled {
                throw CalibrationError.cancelled
            }
        }

        // Analyze collected data
        let movementBaseline = analyzeMovementBaseline()
        let vocalBaseline = analyzeVocalBaseline()
        let expressionBaseline = analyzeExpressionBaseline()

        return BaselineCalibration(
            calibratedAt: Date(),
            movementBaseline: movementBaseline,
            vocalBaseline: vocalBaseline,
            expressionBaseline: expressionBaseline,
            notes: "Calibration completed successfully. \(movementSamples.count) movement samples, \(pitchSamples.count) vocal samples."
        )
    }

    private func analyzeMovementBaseline() -> MovementBaseline {
        guard !movementSamples.isEmpty else {
            return MovementBaseline(
                averageMovementEnergy: 0.3,
                typicalPosture: "Unknown",
                commonStimBehaviors: []
            )
        }

        // Calculate average movement energy
        let avgMovement = movementSamples.reduce(0.0, +) / Double(movementSamples.count)

        // Determine typical posture based on samples
        let typicalPosture: String
        if avgMovement < 0.3 {
            typicalPosture = "Still/Seated"
        } else if avgMovement < 0.6 {
            typicalPosture = "Moderate activity"
        } else {
            typicalPosture = "High activity"
        }

        return MovementBaseline(
            averageMovementEnergy: avgMovement,
            typicalPosture: typicalPosture,
            commonStimBehaviors: Array(observedBehaviors)
        )
    }

    private func analyzeVocalBaseline() -> VocalBaseline {
        guard !pitchSamples.isEmpty && !volumeSamples.isEmpty else {
            return VocalBaseline(
                averagePitch: 250.0,  // Default typical child pitch
                averageVolume: 55.0,   // Default typical volume
                typicalCadence: "Unknown",
                echolaliaPresent: false,
                scriptingPresent: false
            )
        }

        // Calculate averages
        let avgPitch = pitchSamples.reduce(0.0, +) / Double(pitchSamples.count)
        let avgVolume = volumeSamples.reduce(0.0, +) / Double(volumeSamples.count)

        // Calculate variability
        let pitchVariance = calculateVariance(pitchSamples, mean: avgPitch)

        let cadence: String
        if pitchVariance < 50 {
            cadence = "Consistent/Flat"
        } else if pitchVariance < 200 {
            cadence = "Moderate variation"
        } else {
            cadence = "Highly variable"
        }

        return VocalBaseline(
            averagePitch: avgPitch,
            averageVolume: avgVolume,
            typicalCadence: cadence,
            echolaliaPresent: false,  // Would need language processing to detect
            scriptingPresent: false   // Would need language processing to detect
        )
    }

    private func analyzeExpressionBaseline() -> ExpressionBaseline? {
        guard !expressionSamples.isEmpty else {
            return nil
        }

        // Calculate average expression intensity
        let avgIntensity = expressionSamples.map { $0.intensity }.reduce(0.0, +) / Double(expressionSamples.count)

        let neutralExpression: String
        if avgIntensity < 0.3 {
            neutralExpression = "Minimal facial expression (flat affect)"
        } else if avgIntensity < 0.6 {
            neutralExpression = "Moderate facial expressiveness"
        } else {
            neutralExpression = "Highly expressive"
        }

        let flatAffectNormal = avgIntensity < 0.35

        return ExpressionBaseline(
            neutralExpression: neutralExpression,
            flatAffectNormal: flatAffectNormal
        )
    }

    // MARK: - Helper Methods

    private func calculateVariance(_ samples: [Double], mean: Double) -> Double {
        guard !samples.isEmpty else { return 0.0 }
        let squaredDiffs = samples.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0.0, +) / Double(samples.count)
    }

    /// Get camera session for preview
    func getCameraSession() -> AVCaptureSession? {
        return cameraService.getCaptureSession()
    }
}

// MARK: - Supporting Types

private struct ExpressionSample {
    let intensity: Double
    let mouthOpenness: Double
    let eyeWideness: Double
}

// MARK: - Errors

enum CalibrationError: LocalizedError {
    case alreadyRecording
    case cancelled
    case insufficientData
    case cameraNotAvailable
    case microphoneNotAvailable

    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Calibration is already in progress"
        case .cancelled:
            return "Calibration was cancelled"
        case .insufficientData:
            return "Not enough data collected for calibration"
        case .cameraNotAvailable:
            return "Camera is not available"
        case .microphoneNotAvailable:
            return "Microphone is not available"
        }
    }
}
