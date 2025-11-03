//
//  PoseDetectionService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 2 - ML Foundation (Pose Detection)
//

import Foundation
import Vision
import CoreImage
import Combine

/// Service for detecting human body pose using Vision framework
/// Uses Apple's built-in VNDetectHumanBodyPoseRequest
@MainActor
class PoseDetectionService: ObservableObject {
    // MARK: - Singleton

    static let shared = PoseDetectionService()

    // MARK: - Published Properties

    @Published private(set) var isProcessing = false
    @Published private(set) var lastDetectionTime: Date?

    // MARK: - Private Properties

    private let performanceMonitor: ModelPerformanceMonitorProtocol
    private var previousKeypoints: [BodyKeypoint]?

    // MARK: - Initialization

    init(performanceMonitor: ModelPerformanceMonitorProtocol = PerformanceMonitor.shared) {
        self.performanceMonitor = performanceMonitor
    }

    // MARK: - Pose Detection

    /// Detect pose in an image
    /// - Parameter image: Input image (CGImage)
    /// - Returns: Pose detection result with keypoints and confidence
    func detectPose(in image: CGImage) async throws -> PoseDetectionResult {
        isProcessing = true
        defer { isProcessing = false }

        let startTime = Date()

        // Create Vision request
        let request = VNDetectHumanBodyPoseRequest()
        request.revision = VNDetectHumanBodyPoseRequestRevision1

        // Perform detection
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        // Extract results
        guard let observation = request.results?.first else {
            throw PoseDetectionError.noPoseDetected
        }

        // Extract keypoints
        let keypoints = try extractKeypoints(from: observation)

        // Calculate confidence
        let confidence = observation.confidence

        // Record performance
        let latency = Date().timeIntervalSince(startTime)
        recordPerformance(latency: latency)

        lastDetectionTime = Date()

        return PoseDetectionResult(
            keypoints: keypoints,
            confidence: Double(confidence),
            timestamp: Date(),
            latency: latency
        )
    }

    /// Detect pose features for arousal analysis
    /// - Parameter image: Input image
    /// - Returns: Extracted pose features
    func extractPoseFeatures(from image: CGImage) async throws -> PoseFeatures {
        let result = try await detectPose(in: image)
        return extractFeatures(from: result.keypoints)
    }

    // MARK: - Keypoint Extraction

    private func extractKeypoints(from observation: VNHumanBodyPoseObservation) throws -> [BodyKeypoint] {
        var keypoints: [BodyKeypoint] = []

        // Define joints to extract
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose,
            .leftEye, .rightEye,
            .leftEar, .rightEar,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]

        // Extract each joint
        for jointName in jointNames {
            if let point = try? observation.recognizedPoint(jointName) {
                keypoints.append(BodyKeypoint(
                    name: jointName.rawValue.rawValue,
                    position: CGPoint(x: point.location.x, y: point.location.y),
                    confidence: Double(point.confidence)
                ))
            }
        }

        return keypoints
    }

    // MARK: - Feature Extraction

    private func extractFeatures(from keypoints: [BodyKeypoint]) -> PoseFeatures {
        // Calculate movement features
        let movementIntensity = calculateMovementIntensity(keypoints: keypoints)
        let bodyTension = calculateBodyTension(keypoints: keypoints)
        let postureOpenness = calculatePostureOpenness(keypoints: keypoints)

        return PoseFeatures(
            movementIntensity: movementIntensity,
            bodyTension: bodyTension,
            postureOpenness: postureOpenness,
            keypointConfidence: averageConfidence(keypoints: keypoints)
        )
    }

    private func calculateMovementIntensity(keypoints: [BodyKeypoint]) -> Double {
        defer { previousKeypoints = keypoints }

        guard let previous = previousKeypoints else {
            return 0.3 // First frame, assume low movement
        }

        // Calculate displacement vectors for all keypoints
        var displacements: [(name: String, dx: Double, dy: Double)] = []

        for current in keypoints {
            if let prev = previous.first(where: { $0.name == current.name }) {
                let dx = current.position.x - prev.position.x
                let dy = current.position.y - prev.position.y
                displacements.append((current.name, dx, dy))
            }
        }

        guard !displacements.isEmpty else { return 0.3 }

        // Step 1: Calculate average displacement (camera motion estimate)
        let avgDx = displacements.reduce(0.0) { $0 + $1.dx } / Double(displacements.count)
        let avgDy = displacements.reduce(0.0) { $0 + $1.dy } / Double(displacements.count)

        // Step 2: Subtract camera motion to get child-relative movement
        // Calculate variance from average (how much keypoints deviate from uniform motion)
        var relativeTotalDisplacement = 0.0

        for displacement in displacements {
            // Remove camera motion component
            let relativeDx = displacement.dx - avgDx
            let relativeDy = displacement.dy - avgDy
            let relativeDistance = sqrt(relativeDx * relativeDx + relativeDy * relativeDy)
            relativeTotalDisplacement += relativeDistance
        }

        let avgRelativeDisplacement = relativeTotalDisplacement / Double(displacements.count)

        // Step 3: Normalize to 0-1
        // If avgRelativeDisplacement is small → uniform motion (camera) → low intensity
        // If avgRelativeDisplacement is large → non-uniform motion (child) → high intensity
        let normalized = min(avgRelativeDisplacement / 0.10, 1.0) // Adjusted threshold for relative motion

        // Debug logging for camera motion detection
        let cameraMotion = sqrt(avgDx * avgDx + avgDy * avgDy)
        if cameraMotion > 0.02 { // Log significant camera motion
            print("📹 Camera motion detected: \(String(format: "%.3f", cameraMotion)) | Child motion: \(String(format: "%.3f", normalized))")
        }

        return normalized
    }

    private func calculateBodyTension(keypoints: [BodyKeypoint]) -> Double {
        // Calculate joint angles - smaller angles indicate tension
        // Find elbow and knee angles

        // Try to find left arm angle (shoulder-elbow-wrist)
        let leftArmTension = calculateArmTension(
            shoulder: keypoints.first(where: { $0.name.contains("left_shoulder") }),
            elbow: keypoints.first(where: { $0.name.contains("left_elbow") }),
            wrist: keypoints.first(where: { $0.name.contains("left_wrist") })
        )

        // Try to find right arm angle
        let rightArmTension = calculateArmTension(
            shoulder: keypoints.first(where: { $0.name.contains("right_shoulder") }),
            elbow: keypoints.first(where: { $0.name.contains("right_elbow") }),
            wrist: keypoints.first(where: { $0.name.contains("right_wrist") })
        )

        // Average the tensions (use available data)
        var tensions: [Double] = []
        if let left = leftArmTension { tensions.append(left) }
        if let right = rightArmTension { tensions.append(right) }

        if !tensions.isEmpty {
            return tensions.reduce(0.0, +) / Double(tensions.count)
        }

        // Fallback: use keypoint confidence as proxy for stability
        return averageConfidence(keypoints: keypoints)
    }

    private func calculateArmTension(shoulder: BodyKeypoint?, elbow: BodyKeypoint?, wrist: BodyKeypoint?) -> Double? {
        guard let shoulder = shoulder,
              let elbow = elbow,
              let wrist = wrist else {
            return nil
        }

        let angle = calculateAngle(
            point1: shoulder.position,
            vertex: elbow.position,
            point2: wrist.position
        )

        // Smaller angles (< 90°) indicate tension (arms tight/bent)
        // Larger angles (> 150°) indicate relaxation (arms extended)
        // Normalize: angle of 180° (straight) = 0 tension, angle of 45° (very bent) = 1 tension
        let normalized = 1.0 - ((angle - 45.0) / 135.0)  // Maps 45°→1.0, 180°→0.0
        return max(0.0, min(1.0, normalized))
    }

    private func calculateAngle(point1: CGPoint, vertex: CGPoint, point2: CGPoint) -> Double {
        // Calculate angle at vertex using vectors
        let v1 = CGPoint(x: point1.x - vertex.x, y: point1.y - vertex.y)
        let v2 = CGPoint(x: point2.x - vertex.x, y: point2.y - vertex.y)

        let dot = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)

        if mag1 == 0 || mag2 == 0 { return 90.0 }

        let cosAngle = dot / (mag1 * mag2)
        let angle = acos(max(-1.0, min(1.0, cosAngle))) * 180.0 / .pi

        return angle
    }

    private func calculatePostureOpenness(keypoints: [BodyKeypoint]) -> Double {
        // Calculate how "open" vs "closed" the posture is
        // Open = arms spread, standing tall (lower arousal)
        // Closed = hunched, arms tight (higher arousal)

        guard let leftShoulder = keypoints.first(where: { $0.name.contains("left_shoulder") }),
              let rightShoulder = keypoints.first(where: { $0.name.contains("right_shoulder") }) else {
            return 0.5
        }

        // Distance between shoulders (normalized)
        let shoulderDistance = distance(leftShoulder.position, rightShoulder.position)
        return min(shoulderDistance * 2, 1.0) // Normalize to 0-1
    }

    private func averageConfidence(keypoints: [BodyKeypoint]) -> Double {
        guard !keypoints.isEmpty else { return 0.0 }
        let sum = keypoints.reduce(0.0) { $0 + $1.confidence }
        return sum / Double(keypoints.count)
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }

    // MARK: - Performance Tracking

    private func recordPerformance(latency: TimeInterval) {
        let metrics = ModelPerformanceMetrics(
            modelType: .poseDetection,
            inferenceLatency: latency,
            memoryUsage: 0, // Vision framework manages memory
            batteryImpact: 0.05, // Minimal battery impact
            timestamp: Date()
        )

        performanceMonitor.recordInference(metrics)
    }
}

// MARK: - Supporting Types

/// Result of pose detection
struct PoseDetectionResult {
    let keypoints: [BodyKeypoint]
    let confidence: Double
    let timestamp: Date
    let latency: TimeInterval

    var meetsLatencyTarget: Bool {
        return latency < MLModelType.poseDetection.latencyTarget
    }
}

/// A single body keypoint
struct BodyKeypoint: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let position: CGPoint
    let confidence: Double

    static func == (lhs: BodyKeypoint, rhs: BodyKeypoint) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Extracted pose features for arousal analysis
struct PoseFeatures {
    let movementIntensity: Double      // 0-1, higher = more movement
    let bodyTension: Double             // 0-1, higher = more tense
    let postureOpenness: Double         // 0-1, higher = more open/relaxed
    let keypointConfidence: Double      // 0-1, average confidence

    /// Estimate arousal contribution from pose
    /// Returns value 0-1 where higher = higher arousal
    var arousalContribution: Double {
        // Weighted combination of features
        let weights: (movement: Double, tension: Double, openness: Double) = (0.4, 0.4, 0.2)

        let arousal = (movementIntensity * weights.movement) +
                      (bodyTension * weights.tension) +
                      ((1.0 - postureOpenness) * weights.openness) // Inverted - closed = higher arousal

        return min(max(arousal, 0.0), 1.0)
    }
}

/// Pose detection errors
enum PoseDetectionError: LocalizedError {
    case noPoseDetected
    case invalidImage
    case processingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noPoseDetected:
            return "No human pose detected in image"
        case .invalidImage:
            return "Invalid image format"
        case .processingFailed(let error):
            return "Pose detection failed: \(error.localizedDescription)"
        }
    }
}
