//
//  PoseAnalyzer.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach: Pose Detection and Movement Analysis
//

import Foundation
import Vision
import CoreGraphics
import AVFoundation

/// Analyzes body pose and movement patterns using Apple's Vision framework
class PoseAnalyzer {

    // MARK: - Properties

    private var poseRequest: VNDetectHumanBodyPoseRequest
    private var poseHistory: [PoseData] = []
    private let maxHistorySize = 30  // Keep 1 second of history at 30fps

    // MARK: - Initialization

    init() {
        poseRequest = VNDetectHumanBodyPoseRequest()
        poseRequest.revision = VNDetectHumanBodyPoseRequestRevision1
    }

    // MARK: - Pose Detection

    /// Analyze pose from a single frame
    func analyzePose(from pixelBuffer: CVPixelBuffer) async throws -> PoseData {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        try handler.perform([poseRequest])

        guard let observation = poseRequest.results?.first else {
            throw PoseAnalyzerError.noPoseDetected
        }

        // Extract all recognized body points
        let recognizedPoints = try observation.recognizedPoints(.all)

        // Convert to our data structure
        var landmarks: [BodyLandmark] = []
        for (jointName, point) in recognizedPoints {
            // Only use confident detections
            if point.confidence > 0.5 {
                landmarks.append(BodyLandmark(
                    joint: jointName,
                    position: CGPoint(x: point.location.x, y: point.location.y),
                    confidence: point.confidence
                ))
            }
        }

        let poseData = PoseData(
            landmarks: landmarks,
            confidence: calculateOverallConfidence(landmarks),
            timestamp: Date()
        )

        // Add to history
        poseHistory.append(poseData)
        if poseHistory.count > maxHistorySize {
            poseHistory.removeFirst()
        }

        return poseData
    }

    // MARK: - Movement Energy Calculation

    /// Calculate overall movement energy level from pose history
    func calculateMovementEnergy() -> MovementEnergy {
        guard poseHistory.count >= 2 else { return .low }

        // Calculate total displacement across all joints over recent frames
        var totalDisplacement: CGFloat = 0
        let recentPoses = Array(poseHistory.suffix(10))  // Last ~0.3 seconds

        for i in 1..<recentPoses.count {
            let current = recentPoses[i]
            let previous = recentPoses[i-1]

            for landmark in current.landmarks {
                if let prevLandmark = previous.landmarks.first(where: { $0.joint == landmark.joint }) {
                    let displacement = distance(landmark.position, prevLandmark.position)
                    totalDisplacement += displacement
                }
            }
        }

        let avgDisplacement = totalDisplacement / CGFloat(recentPoses.count - 1)

        // Classify energy level based on average displacement
        switch avgDisplacement {
        case 0..<0.02:
            return .low  // Stillness or minimal movement
        case 0.02..<0.1:
            return .moderate  // Normal movement
        default:
            return .high  // High energy (jumping, running, flapping)
        }
    }

    // MARK: - Behavior Detection

    /// Detect hand-flapping behavior
    func detectHandFlapping() -> Bool {
        guard poseHistory.count >= 10 else { return false }

        // Get wrist positions over time
        let leftWristPositions = poseHistory.compactMap { pose in
            pose.landmark(for: .leftWrist)?.position
        }
        let rightWristPositions = poseHistory.compactMap { pose in
            pose.landmark(for: .rightWrist)?.position
        }

        guard leftWristPositions.count >= 10, rightWristPositions.count >= 10 else {
            return false
        }

        // Calculate vertical oscillation for both wrists
        let leftOscillation = calculateOscillation(leftWristPositions, axis: .vertical)
        let rightOscillation = calculateOscillation(rightWristPositions, axis: .vertical)

        // Hand flapping characteristics:
        // - Rapid up-down movement (2-5 Hz frequency)
        // - High amplitude (>10% of frame height)
        // - Often bilateral (both hands)

        let leftFlapping = (2.0...5.0).contains(leftOscillation.frequency) && leftOscillation.amplitude > 0.1
        let rightFlapping = (2.0...5.0).contains(rightOscillation.frequency) && rightOscillation.amplitude > 0.1

        // Check if hands are near shoulder height (typical for flapping)
        let nearShoulders = checkWristsNearShoulders()

        return (leftFlapping || rightFlapping) && nearShoulders
    }

    /// Detect covering ears behavior
    func detectCoveringEars() -> Bool {
        guard let latestPose = poseHistory.last else { return false }

        // Check if hands are near ears
        guard let leftWrist = latestPose.landmark(for: .leftWrist),
              let rightWrist = latestPose.landmark(for: .rightWrist),
              let leftEar = latestPose.landmark(for: .leftEar),
              let rightEar = latestPose.landmark(for: .rightEar) else {
            return false
        }

        let leftDistance = distance(leftWrist.position, leftEar.position)
        let rightDistance = distance(rightWrist.position, rightEar.position)

        // Within 15% of frame = covering ears
        return leftDistance < 0.15 || rightDistance < 0.15
    }

    /// Detect rocking behavior
    func detectRocking() -> Bool {
        guard poseHistory.count >= 15 else { return false }

        // Track torso movement (use neck or root joint)
        let torsoPositions = poseHistory.compactMap { pose in
            pose.landmark(for: .neck)?.position ?? pose.landmark(for: .root)?.position
        }

        guard torsoPositions.count >= 15 else { return false }

        // Check for rhythmic back-and-forth or side-to-side movement
        let horizontalOscillation = calculateOscillation(torsoPositions, axis: .horizontal)

        // Rocking characteristics:
        // - Slower frequency than flapping (0.5-2 Hz)
        // - Consistent amplitude

        let isRocking = (0.5...2.0).contains(horizontalOscillation.frequency) && horizontalOscillation.amplitude > 0.05

        return isRocking
    }

    /// Detect jumping behavior
    func detectJumping() -> Bool {
        guard poseHistory.count >= 5 else { return false }

        // Track vertical position of feet or root
        let recentPoses = Array(poseHistory.suffix(5))
        let verticalPositions = recentPoses.compactMap { pose in
            pose.landmark(for: .root)?.position.y
        }

        guard verticalPositions.count >= 5 else { return false }

        // Look for rapid vertical displacement
        var maxDisplacement: CGFloat = 0
        for i in 1..<verticalPositions.count {
            let displacement = abs(verticalPositions[i] - verticalPositions[i-1])
            maxDisplacement = max(maxDisplacement, displacement)
        }

        // Jumping has significant vertical displacement (>10% of frame)
        return maxDisplacement > 0.1
    }

    /// Detect pacing behavior
    func detectPacing() -> Bool {
        guard poseHistory.count >= 30 else { return false }

        // Track horizontal movement of root/hips
        let positions = poseHistory.compactMap { pose in
            pose.landmark(for: .root)?.position.x
        }

        guard positions.count >= 30 else { return false }

        // Calculate horizontal displacement over time
        var totalDisplacement: CGFloat = 0
        for i in 1..<positions.count {
            totalDisplacement += abs(positions[i] - positions[i-1])
        }

        // Pacing shows consistent horizontal movement
        let avgDisplacement = totalDisplacement / CGFloat(positions.count - 1)

        return avgDisplacement > 0.03  // Consistent horizontal movement
    }

    /// Detect stillness/freezing
    func detectStillness() -> Bool {
        guard poseHistory.count >= 10 else { return false }

        // Calculate movement across all joints
        let recentPoses = Array(poseHistory.suffix(10))
        var totalMovement: CGFloat = 0

        for i in 1..<recentPoses.count {
            let current = recentPoses[i]
            let previous = recentPoses[i-1]

            for landmark in current.landmarks {
                if let prevLandmark = previous.landmarks.first(where: { $0.joint == landmark.joint }) {
                    totalMovement += distance(landmark.position, prevLandmark.position)
                }
            }
        }

        // Very little movement indicates stillness
        return totalMovement < 0.05
    }

    /// Detect all current behaviors
    func detectAllBehaviors() -> [ChildBehavior] {
        var behaviors: [ChildBehavior] = []

        if detectHandFlapping() {
            behaviors.append(.handFlapping)
        }

        if detectCoveringEars() {
            behaviors.append(.coveringEars)
        }

        if detectRocking() {
            behaviors.append(.rocking)
        }

        if detectJumping() {
            behaviors.append(.jumping)
        }

        if detectPacing() {
            behaviors.append(.pacing)
        }

        if detectStillness() && behaviors.isEmpty {
            behaviors.append(.stillness)
        }

        return behaviors.isEmpty ? [.unknown] : behaviors
    }

    // MARK: - Helper Functions

    private func calculateOverallConfidence(_ landmarks: [BodyLandmark]) -> Float {
        guard !landmarks.isEmpty else { return 0 }
        let sum = landmarks.reduce(0.0) { $0 + $1.confidence }
        return sum / Float(landmarks.count)
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx*dx + dy*dy)
    }

    private enum Axis {
        case horizontal, vertical
    }

    private struct Oscillation {
        let frequency: Float  // Hz
        let amplitude: CGFloat  // Normalized (0-1)
    }

    private func calculateOscillation(_ positions: [CGPoint], axis: Axis) -> Oscillation {
        guard positions.count > 5 else {
            return Oscillation(frequency: 0, amplitude: 0)
        }

        // Extract relevant coordinate
        let values: [CGFloat] = positions.map { axis == .vertical ? $0.y : $0.x }

        // Calculate amplitude (max - min)
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0
        let amplitude = maxVal - minVal

        // Estimate frequency using zero-crossing rate
        var zeroCrossings = 0
        let mean = values.reduce(0, +) / CGFloat(values.count)

        for i in 1..<values.count {
            if (values[i] - mean) * (values[i-1] - mean) < 0 {
                zeroCrossings += 1
            }
        }

        // Frequency = zero crossings / (2 * time)
        // Assuming 30fps, time = positions.count / 30
        let timespan = Float(positions.count) / 30.0
        let frequency = Float(zeroCrossings) / (2.0 * timespan)

        return Oscillation(frequency: frequency, amplitude: amplitude)
    }

    private func checkWristsNearShoulders() -> Bool {
        guard let latestPose = poseHistory.last else { return false }

        guard let leftWrist = latestPose.landmark(for: .leftWrist),
              let leftShoulder = latestPose.landmark(for: .leftShoulder),
              let rightWrist = latestPose.landmark(for: .rightWrist),
              let rightShoulder = latestPose.landmark(for: .rightShoulder) else {
            return false
        }

        // Check if wrists are within reasonable distance of shoulders
        let leftDistance = distance(leftWrist.position, leftShoulder.position)
        let rightDistance = distance(rightWrist.position, rightShoulder.position)

        // Within 30% of frame = near shoulders
        return leftDistance < 0.3 || rightDistance < 0.3
    }

    /// Clear pose history (useful when starting new session)
    func clearHistory() {
        poseHistory.removeAll()
    }
}

// MARK: - Errors

enum PoseAnalyzerError: Error {
    case noPoseDetected
    case insufficientData
    case processingError
}
