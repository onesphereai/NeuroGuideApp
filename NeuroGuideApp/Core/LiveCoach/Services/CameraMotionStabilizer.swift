//
//  CameraMotionStabilizer.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-11-01.
//  Unit 5 - Live Coach (Camera Motion Stabilization)
//

import Foundation
import Vision
import CoreImage
import Accelerate

/// Service for detecting and filtering out camera movement from pose detection
/// This prevents false positives when the device/camera moves instead of the child
@MainActor
class CameraMotionStabilizer {
    // MARK: - Singleton

    static let shared = CameraMotionStabilizer()

    // MARK: - Properties

    private var previousFrame: CGImage?
    private var previousTransform: CGAffineTransform?
    private var motionHistory: [CGAffineTransform] = []
    private let historySize: Int = 5

    // Motion thresholds
    private let translationThreshold: Double = 10.0  // pixels
    private let rotationThreshold: Double = 0.05     // radians (~3 degrees)
    private let scaleThreshold: Double = 0.05        // 5% scale change

    // MARK: - Initialization

    private init() {}

    // MARK: - Stabilization

    /// Detect if camera is moving between frames
    /// - Parameters:
    ///   - currentFrame: Current video frame
    ///   - previousFrame: Previous video frame (optional)
    /// - Returns: Camera motion information
    func detectCameraMotion(
        currentFrame: CGImage,
        previousFrame: CGImage?
    ) async throws -> CameraMotion {
        guard let previous = previousFrame else {
            // First frame - no motion detected
            self.previousFrame = currentFrame
            return CameraMotion(
                isMoving: false,
                transform: .identity,
                translationMagnitude: 0.0,
                rotationMagnitude: 0.0
            )
        }

        // Calculate optical flow between frames
        let transform = try await calculateOpticalFlowTransform(
            from: previous,
            to: currentFrame
        )

        // Store in history
        motionHistory.append(transform)
        if motionHistory.count > historySize {
            motionHistory.removeFirst()
        }

        // Calculate motion metrics
        let translation = CGPoint(
            x: transform.tx,
            y: transform.ty
        )
        let translationMagnitude = sqrt(translation.x * translation.x + translation.y * translation.y)

        // Estimate rotation from transform matrix
        let rotationMagnitude = abs(atan2(transform.b, transform.a))

        // Determine if camera is moving
        let isMoving = translationMagnitude > translationThreshold ||
                      rotationMagnitude > rotationThreshold

        // Update state
        self.previousFrame = currentFrame
        self.previousTransform = transform

        return CameraMotion(
            isMoving: isMoving,
            transform: transform,
            translationMagnitude: translationMagnitude,
            rotationMagnitude: rotationMagnitude
        )
    }

    /// Calculate optical flow transform between two frames
    private func calculateOpticalFlowTransform(
        from previousFrame: CGImage,
        to currentFrame: CGImage
    ) async throws -> CGAffineTransform {
        // Use Vision framework for optical flow analysis
        let request = VNTranslationalImageRegistrationRequest(
            targetedCGImage: currentFrame
        )

        let handler = VNImageRequestHandler(
            cgImage: previousFrame,
            options: [:]
        )

        try handler.perform([request])

        guard let observation = request.results?.first else {
            throw StabilizationError.registrationFailed
        }

        // Extract alignment transform
        return observation.alignmentTransform
    }

    /// Filter pose keypoints to compensate for camera motion
    /// - Parameters:
    ///   - keypoints: Raw keypoints from pose detection
    ///   - cameraMotion: Detected camera motion
    /// - Returns: Stabilized keypoints
    func stabilizeKeypoints(
        _ keypoints: [BodyKeypoint],
        cameraMotion: CameraMotion
    ) -> [BodyKeypoint] {
        // If camera isn't moving significantly, return original keypoints
        guard cameraMotion.isMoving else {
            return keypoints
        }

        // Apply inverse transform to compensate for camera motion
        let inverseTransform = cameraMotion.transform.inverted()

        return keypoints.map { keypoint in
            let stabilizedPosition = keypoint.position.applying(inverseTransform)
            return BodyKeypoint(
                name: keypoint.name,
                position: stabilizedPosition,
                confidence: keypoint.confidence
            )
        }
    }

    /// Calculate stabilized movement energy
    /// Filters out camera movement from child movement measurement
    /// - Parameters:
    ///   - rawMovementEnergy: Raw movement energy (0.0-1.0)
    ///   - cameraMotion: Detected camera motion
    /// - Returns: Adjusted movement energy with camera motion filtered out
    func filterMovementEnergy(
        rawMovementEnergy: Double,
        cameraMotion: CameraMotion
    ) -> FilteredMovement {
        // If no camera motion, return raw energy
        guard cameraMotion.isMoving else {
            return FilteredMovement(
                stabilizedEnergy: rawMovementEnergy,
                cameraContribution: 0.0,
                childContribution: rawMovementEnergy
            )
        }

        // Estimate camera's contribution to perceived movement
        // Normalize camera motion to 0-1 scale
        let normalizedTranslation = min(cameraMotion.translationMagnitude / 50.0, 1.0)
        let normalizedRotation = min(cameraMotion.rotationMagnitude / rotationThreshold, 1.0)
        let cameraContribution = (normalizedTranslation * 0.7 + normalizedRotation * 0.3)

        // Subtract camera contribution from raw movement
        // But don't go negative - camera motion might actually reveal child movement
        let childContribution = max(rawMovementEnergy - cameraContribution, 0.0)

        // If camera motion is very high, reduce confidence in child movement estimate
        let stabilizationFactor = cameraContribution > 0.5 ? 0.5 : 1.0
        let stabilizedEnergy = childContribution * stabilizationFactor

        return FilteredMovement(
            stabilizedEnergy: stabilizedEnergy,
            cameraContribution: cameraContribution,
            childContribution: childContribution
        )
    }

    /// Check if camera motion is stable (low jitter)
    func isCameraStable() -> Bool {
        guard motionHistory.count >= 3 else {
            return false
        }

        // Calculate variance in recent motion
        let recentMotions = motionHistory.suffix(3)
        let translations = recentMotions.map { sqrt($0.tx * $0.tx + $0.ty * $0.ty) }

        let mean = translations.reduce(0, +) / Double(translations.count)
        let variance = translations.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(translations.count)

        // Low variance = stable
        return variance < 5.0
    }

    /// Reset stabilization state (call when starting new session)
    func reset() {
        previousFrame = nil
        previousTransform = nil
        motionHistory.removeAll()
        print("📹 Camera stabilization reset")
    }
}

// MARK: - Supporting Types

/// Information about detected camera motion
struct CameraMotion {
    var isMoving: Bool
    var transform: CGAffineTransform
    var translationMagnitude: Double  // pixels
    var rotationMagnitude: Double     // radians

    /// Human-readable description
    var description: String {
        if !isMoving {
            return "Camera stable"
        }

        var components: [String] = []

        if translationMagnitude > 10.0 {
            components.append("Translation: \(String(format: "%.1f", translationMagnitude))px")
        }

        if rotationMagnitude > 0.05 {
            let degrees = rotationMagnitude * 180.0 / .pi
            components.append("Rotation: \(String(format: "%.1f", degrees))°")
        }

        return components.isEmpty ? "Minor movement" : components.joined(separator: ", ")
    }
}

/// Filtered movement with camera motion removed
struct FilteredMovement {
    var stabilizedEnergy: Double      // Final movement energy (0.0-1.0)
    var cameraContribution: Double    // How much was camera motion (0.0-1.0)
    var childContribution: Double     // How much was child motion (0.0-1.0)

    /// Confidence in this measurement (lower when camera is moving a lot)
    var confidence: Double {
        return 1.0 - (cameraContribution * 0.5)
    }

    /// Human-readable explanation
    var explanation: String {
        if cameraContribution < 0.1 {
            return "Stable camera - full confidence in movement detection"
        } else if cameraContribution < 0.3 {
            return "Minor camera movement detected, compensated"
        } else if cameraContribution < 0.6 {
            return "Moderate camera movement - movement detection adjusted"
        } else {
            return "Significant camera movement - reduced confidence in measurement"
        }
    }
}

/// Errors that can occur during stabilization
enum StabilizationError: LocalizedError {
    case registrationFailed
    case invalidFrame

    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            return "Failed to register frames for motion detection"
        case .invalidFrame:
            return "Invalid frame provided for stabilization"
        }
    }
}
