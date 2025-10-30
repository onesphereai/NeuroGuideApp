//
//  FacialExpressionService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 2 - ML Foundation (Facial Expression)
//

import Foundation
import Vision
import CoreImage
import Combine

/// Service for detecting facial expressions using Vision framework
/// Uses Apple's built-in VNDetectFaceLandmarksRequest and expression analysis
@MainActor
class FacialExpressionService: ObservableObject {
    // MARK: - Singleton

    static let shared = FacialExpressionService()

    // MARK: - Published Properties

    @Published private(set) var isProcessing = false
    @Published private(set) var lastDetectionTime: Date?

    // MARK: - Private Properties

    private let performanceMonitor: ModelPerformanceMonitorProtocol

    // MARK: - Initialization

    init(performanceMonitor: ModelPerformanceMonitorProtocol = PerformanceMonitor.shared) {
        self.performanceMonitor = performanceMonitor
    }

    // MARK: - Facial Expression Detection

    /// Detect facial expression in an image
    /// - Parameter image: Input image (CGImage)
    /// - Returns: Facial expression result
    func detectExpression(in image: CGImage) async throws -> FacialExpressionResult {
        isProcessing = true
        defer { isProcessing = false }

        let startTime = Date()

        // Create Vision requests
        let faceRequest = VNDetectFaceRectanglesRequest()
        let landmarksRequest = VNDetectFaceLandmarksRequest()

        // Perform detection
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([faceRequest, landmarksRequest])

        // Extract face
        guard let faceObservation = faceRequest.results?.first else {
            throw FacialExpressionError.noFaceDetected
        }

        // Extract landmarks
        guard let landmarksObservation = landmarksRequest.results?.first else {
            throw FacialExpressionError.noLandmarksDetected
        }

        // Analyze expression
        let expression = analyzeExpression(
            face: faceObservation,
            landmarks: landmarksObservation
        )

        // Record performance
        let latency = Date().timeIntervalSince(startTime)
        recordPerformance(latency: latency)

        lastDetectionTime = Date()

        return FacialExpressionResult(
            expression: expression,
            confidence: Double(faceObservation.confidence),
            timestamp: Date(),
            latency: latency
        )
    }

    /// Extract facial features for arousal analysis
    /// - Parameter image: Input image
    /// - Returns: Extracted facial features
    func extractFacialFeatures(from image: CGImage) async throws -> FacialFeatures {
        let result = try await detectExpression(in: image)
        return extractFeatures(from: result.expression)
    }

    // MARK: - Expression Analysis

    private func analyzeExpression(
        face: VNFaceObservation,
        landmarks: VNFaceObservation
    ) -> ExpressionAnalysis {
        // Extract landmark features
        let mouthOpenness = analyzeMouth(landmarks: landmarks)
        let eyeOpenness = analyzeEyes(landmarks: landmarks)
        let browPosition = analyzeBrows(landmarks: landmarks)

        // Map to arousal-relevant features
        // Note: This is a simplified heuristic
        // In production, use trained model on neurodivergent data

        return ExpressionAnalysis(
            mouthOpenness: mouthOpenness,
            eyeOpenness: eyeOpenness,
            browPosition: browPosition,
            faceConfidence: Double(face.confidence)
        )
    }

    private func analyzeMouth(landmarks: VNFaceObservation) -> Double {
        guard let outerLips = landmarks.landmarks?.outerLips else {
            return 0.5
        }

        // Calculate mouth openness from lip landmarks
        // Simple heuristic: vertical distance between top and bottom lip
        let points = outerLips.normalizedPoints
        if points.count >= 6 {
            let topPoint = points[3]  // Top of mouth
            let bottomPoint = points[9]  // Bottom of mouth
            let openness = abs(topPoint.y - bottomPoint.y)
            return min(openness * 5, 1.0)  // Normalize to 0-1
        }

        return 0.5
    }

    private func analyzeEyes(landmarks: VNFaceObservation) -> Double {
        guard let leftEye = landmarks.landmarks?.leftEye,
              let rightEye = landmarks.landmarks?.rightEye else {
            return 0.5
        }

        // Calculate eye openness
        let leftOpenness = calculateEyeOpenness(points: leftEye.normalizedPoints)
        let rightOpenness = calculateEyeOpenness(points: rightEye.normalizedPoints)

        return (leftOpenness + rightOpenness) / 2.0
    }

    private func calculateEyeOpenness(points: [CGPoint]) -> Double {
        guard points.count >= 4 else { return 0.5 }

        // Vertical distance between top and bottom of eye
        let topPoint = points[1]
        let bottomPoint = points[3]
        let openness = abs(topPoint.y - bottomPoint.y)

        return min(openness * 10, 1.0)  // Normalize to 0-1
    }

    private func analyzeBrows(landmarks: VNFaceObservation) -> Double {
        guard let leftBrow = landmarks.landmarks?.leftEyebrow,
              let rightBrow = landmarks.landmarks?.rightEyebrow else {
            return 0.5
        }

        // Calculate brow position (raised vs lowered)
        let leftBrowPoints = leftBrow.normalizedPoints
        let rightBrowPoints = rightBrow.normalizedPoints

        if !leftBrowPoints.isEmpty && !rightBrowPoints.isEmpty {
            // Average Y position of brows (higher Y = raised brows in normalized coords)
            let leftY = leftBrowPoints.reduce(0.0) { $0 + $1.y } / Double(leftBrowPoints.count)
            let rightY = rightBrowPoints.reduce(0.0) { $0 + $1.y } / Double(rightBrowPoints.count)

            // Normalize to 0-1 range
            return (leftY + rightY) / 2.0
        }

        return 0.5
    }

    // MARK: - Feature Extraction

    private func extractFeatures(from expression: ExpressionAnalysis) -> FacialFeatures {
        return FacialFeatures(
            expressionIntensity: expression.overallIntensity,
            mouthOpenness: expression.mouthOpenness,
            eyeWideness: expression.eyeOpenness,
            browRaised: expression.browPosition > 0.6,
            confidence: expression.faceConfidence
        )
    }

    // MARK: - Performance Tracking

    private func recordPerformance(latency: TimeInterval) {
        let metrics = ModelPerformanceMetrics(
            modelType: .facialExpression,
            inferenceLatency: latency,
            memoryUsage: 0, // Vision framework manages memory
            batteryImpact: 0.08, // Minimal battery impact
            timestamp: Date()
        )

        performanceMonitor.recordInference(metrics)
    }
}

// MARK: - Supporting Types

/// Result of facial expression detection
struct FacialExpressionResult {
    let expression: ExpressionAnalysis
    let confidence: Double
    let timestamp: Date
    let latency: TimeInterval

    var meetsLatencyTarget: Bool {
        return latency < MLModelType.facialExpression.latencyTarget
    }
}

/// Analysis of facial expression
struct ExpressionAnalysis {
    let mouthOpenness: Double       // 0-1
    let eyeOpenness: Double          // 0-1
    let browPosition: Double         // 0-1 (0=lowered, 1=raised)
    let faceConfidence: Double       // 0-1

    /// Overall expression intensity (for arousal)
    var overallIntensity: Double {
        // Combine features for overall intensity
        // High intensity features: wide eyes, open mouth, raised brows
        let weights: (mouth: Double, eyes: Double, brow: Double) = (0.4, 0.3, 0.3)

        let intensity = (mouthOpenness * weights.mouth) +
                        (eyeOpenness * weights.eyes) +
                        (browPosition * weights.brow)

        return min(max(intensity, 0.0), 1.0)
    }
}

/// Extracted facial features for arousal analysis
struct FacialFeatures {
    let expressionIntensity: Double  // 0-1, higher = more intense
    let mouthOpenness: Double         // 0-1, higher = more open
    let eyeWideness: Double           // 0-1, higher = wider eyes
    let browRaised: Bool              // Whether brows are raised
    let confidence: Double            // 0-1, detection confidence

    /// Estimate arousal contribution from facial expression
    /// Returns value 0-1 where higher = higher arousal
    var arousalContribution: Double {
        // High arousal indicators:
        // - High expression intensity
        // - Wide eyes
        // - Raised brows
        // - Open mouth

        var arousal = expressionIntensity * 0.5

        if eyeWideness > 0.6 {
            arousal += 0.2
        }

        if browRaised {
            arousal += 0.2
        }

        if mouthOpenness > 0.5 {
            arousal += 0.1
        }

        return min(arousal, 1.0)
    }
}

/// Facial expression detection errors
enum FacialExpressionError: LocalizedError {
    case noFaceDetected
    case noLandmarksDetected
    case invalidImage
    case processingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noFaceDetected:
            return "No face detected in image"
        case .noLandmarksDetected:
            return "No facial landmarks detected"
        case .invalidImage:
            return "Invalid image format"
        case .processingFailed(let error):
            return "Facial expression detection failed: \(error.localizedDescription)"
        }
    }
}
