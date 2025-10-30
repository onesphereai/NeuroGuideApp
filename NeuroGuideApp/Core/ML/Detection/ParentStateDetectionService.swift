//
//  ParentStateDetectionService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System (Parent State ML Detection)
//

import Foundation
import Vision
import CoreImage
import Combine
import AVFAudio

/// Service for detecting parent emotional/regulatory state
/// Uses facial expression and body language analysis
@MainActor
class ParentStateDetectionService: ObservableObject {
    // MARK: - Singleton

    static let shared = ParentStateDetectionService()

    // MARK: - Published Properties

    @Published private(set) var isProcessing = false
    @Published private(set) var lastDetectionTime: Date?

    // MARK: - Private Properties

    private let performanceMonitor: ModelPerformanceMonitorProtocol
    private var previousFaceLandmarks: [CGPoint]?
    private var stateHistory: [ParentStateClassification] = []

    // MARK: - Initialization

    init(performanceMonitor: ModelPerformanceMonitorProtocol = PerformanceMonitor.shared) {
        self.performanceMonitor = performanceMonitor
    }

    // MARK: - Parent State Detection

    /// Detect parent state from image
    /// - Parameters:
    ///   - image: Input image from front camera
    ///   - audioBuffer: Optional audio buffer for vocal stress analysis
    /// - Returns: Parent state classification
    func detectParentState(
        in image: CGImage,
        audioBuffer: AVAudioPCMBuffer? = nil
    ) async throws -> ParentStateClassification {
        isProcessing = true
        defer { isProcessing = false }

        let startTime = Date()

        // Extract features
        let facialFeatures = try await extractFacialFeatures(from: image)
        let bodyFeatures = try await extractBodyFeatures(from: image)
        let vocalStress = extractVocalStress(from: audioBuffer)

        // Combine features
        let features = ParentStateFeatures(
            facialTension: facialFeatures.tension,
            vocalStress: vocalStress,
            bodyLanguage: bodyFeatures.tension,
            engagementLevel: bodyFeatures.engagementLevel
        )

        // Classify state
        let state = classifyState(from: features)
        let confidence = calculateConfidence(features: features, state: state)

        // Record performance
        let latency = Date().timeIntervalSince(startTime)
        recordPerformance(latency: latency)

        lastDetectionTime = Date()

        let classification = ParentStateClassification(
            state: state,
            confidence: confidence,
            features: features,
            timestamp: Date()
        )

        // Add to history for smoothing
        stateHistory.append(classification)
        if stateHistory.count > 10 {
            stateHistory.removeFirst()
        }

        return classification
    }

    // MARK: - Feature Extraction

    /// Extract facial features using Vision framework
    private func extractFacialFeatures(from image: CGImage) async throws -> (tension: Double, engagement: Double) {
        let request = VNDetectFaceLandmarksRequest()

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            // No face detected - parent may not be in frame
            return (tension: 0.3, engagement: 0.0)
        }

        // Extract facial landmarks
        let landmarks = observation.landmarks
        var tension = 0.5 // Default moderate tension

        // Analyze brow position (furrowed = stressed)
        if let landmarksValue = landmarks,
           let leftBrow = landmarksValue.leftEyebrow,
           let rightBrow = landmarksValue.rightEyebrow {
            let browTension = calculateBrowTension(
                left: leftBrow.normalizedPoints,
                right: rightBrow.normalizedPoints
            )
            tension = browTension
        }

        // Analyze mouth (tight lips = stressed)
        if let landmarksValue = landmarks,
           let outerLips = landmarksValue.outerLips {
            let mouthTension = calculateMouthTension(points: outerLips.normalizedPoints)
            tension = (tension + mouthTension) / 2.0
        }

        // Engagement based on face detection confidence
        let engagement = Double(observation.confidence)

        return (tension: tension, engagement: engagement)
    }

    /// Extract body language features
    private func extractBodyFeatures(from image: CGImage) async throws -> (tension: Double, engagementLevel: Double) {
        let request = VNDetectHumanBodyPoseRequest()

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            // No body detected
            return (tension: 0.3, engagementLevel: 0.0)
        }

        // Extract keypoints
        let keypoints = try extractKeypoints(from: observation)

        // Calculate body tension from posture
        let tension = calculateBodyTension(keypoints: keypoints)

        // Estimate engagement (forward lean, proximity)
        let engagement = calculateEngagement(keypoints: keypoints)

        return (tension: tension, engagementLevel: engagement)
    }

    /// Extract vocal stress (placeholder - needs audio analysis)
    private func extractVocalStress(from audioBuffer: AVAudioPCMBuffer?) -> Double {
        // TODO: Implement audio analysis
        // For now, return neutral value
        return 0.5
    }

    // MARK: - Facial Analysis

    private func calculateBrowTension(left: [CGPoint], right: [CGPoint]) -> Double {
        // Higher/furrowed brows indicate stress
        // Calculate vertical position of brow points
        let leftAvgY = left.reduce(0.0) { $0 + $1.y } / Double(left.count)
        let rightAvgY = right.reduce(0.0) { $0 + $1.y } / Double(right.count)
        let avgBrowY = (leftAvgY + rightAvgY) / 2.0

        // Normalize: lower Y (higher on face) = more tension
        // Y coords are 0-1 where 0 is top of image
        let tension = 1.0 - avgBrowY * 2.0 // Normalize to 0-1 range
        return max(0.0, min(1.0, tension))
    }

    private func calculateMouthTension(points: [CGPoint]) -> Double {
        // Calculate mouth opening
        // Tight/closed mouth = stress, open/relaxed = calm
        guard points.count >= 4 else { return 0.5 }

        // Get vertical distance between top and bottom of mouth
        let topPoint = points.min(by: { $0.y < $1.y })!
        let bottomPoint = points.max(by: { $0.y < $1.y })!
        let opening = bottomPoint.y - topPoint.y

        // Smaller opening = more tension
        let tension = 1.0 - (opening * 10.0) // Scale up for visibility
        return max(0.0, min(1.0, tension))
    }

    // MARK: - Body Analysis

    private func extractKeypoints(from observation: VNHumanBodyPoseObservation) throws -> [BodyKeypoint] {
        var keypoints: [BodyKeypoint] = []

        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist
        ]

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

    private func calculateBodyTension(keypoints: [BodyKeypoint]) -> Double {
        // Tense posture = shoulders raised, arms tight
        // Similar to child pose detection

        guard let leftShoulder = keypoints.first(where: { $0.name.contains("left_shoulder") }),
              let rightShoulder = keypoints.first(where: { $0.name.contains("right_shoulder") }) else {
            return 0.5
        }

        // Calculate shoulder height (raised shoulders = tension)
        let shoulderHeight = (leftShoulder.position.y + rightShoulder.position.y) / 2.0

        // Lower Y value (higher on screen) = more tension
        let tension = 1.0 - shoulderHeight
        return max(0.0, min(1.0, tension))
    }

    private func calculateEngagement(keypoints: [BodyKeypoint]) -> Double {
        // Forward lean and proximity to camera indicate engagement
        // Check head/body position relative to frame

        guard let nose = keypoints.first(where: { $0.name.contains("nose") }) else {
            return 0.3
        }

        // Centered face = higher engagement
        let centerDistance = abs(nose.position.x - 0.5)
        let engagement = 1.0 - (centerDistance * 2.0)

        return max(0.0, min(1.0, engagement))
    }

    // MARK: - State Classification

    /// Classify parent state from features
    private func classifyState(from features: ParentStateFeatures) -> ParentState {
        let stressLevel = features.stressLevel
        let engagement = features.engagementLevel

        // Decision tree for state classification
        if engagement > 0.7 {
            // Parent is engaged
            if stressLevel < 0.3 {
                return .coRegulating // Calm and engaged
            } else if stressLevel < 0.6 {
                return .stressed // Engaged but stressed
            } else {
                return .dysregulated // Engaged but very stressed
            }
        } else {
            // Parent not actively engaged
            if stressLevel < 0.4 {
                return .calm
            } else if stressLevel < 0.7 {
                return .stressed
            } else {
                return .dysregulated
            }
        }
    }

    /// Calculate confidence in classification
    private func calculateConfidence(features: ParentStateFeatures, state: ParentState) -> Double {
        // Confidence based on feature consistency
        let stressLevel = features.stressLevel
        let engagement = features.engagementLevel

        var confidence = 0.5

        // Higher confidence when features are consistent with state
        switch state {
        case .calm:
            confidence = 1.0 - stressLevel
        case .stressed:
            confidence = stressLevel
        case .coRegulating:
            confidence = engagement
        case .dysregulated:
            confidence = stressLevel
        }

        return max(0.5, min(1.0, confidence))
    }

    /// Simulate parent state reading for testing
    func simulateReading() -> ParentStateClassification {
        let states: [ParentState] = [.calm, .stressed, .coRegulating, .dysregulated]
        let state = states.randomElement() ?? .calm

        let features = ParentStateFeatures(
            facialTension: Double.random(in: 0.3...0.7),
            vocalStress: Double.random(in: 0.3...0.7),
            bodyLanguage: Double.random(in: 0.3...0.7),
            engagementLevel: Double.random(in: 0.4...0.9)
        )

        return ParentStateClassification(
            state: state,
            confidence: Double.random(in: 0.6...0.9),
            features: features
        )
    }

    /// Clear detection history
    func clearHistory() {
        stateHistory.removeAll()
        previousFaceLandmarks = nil
    }

    // MARK: - Performance Tracking

    private func recordPerformance(latency: TimeInterval) {
        let metrics = ModelPerformanceMetrics(
            modelType: .poseDetection, // Reuse pose detection category
            inferenceLatency: latency,
            memoryUsage: 0,
            batteryImpact: 0.03, // Lighter than child detection
            timestamp: Date()
        )

        performanceMonitor.recordInference(metrics)
    }
}
