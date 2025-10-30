//
//  FacialAnalyzer.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach: Parent Stress Detection via Facial Analysis
//
//  IMPORTANT: This is ONLY for parent stress detection, NOT child emotion.
//  Autistic facial expressions often differ from neurotypical norms.
//  Never use facial analysis for child emotion inference.
//

import Foundation
import Vision
import CoreGraphics

/// Analyzes parent facial expression for stress detection
/// WARNING: Only use for parent (neurotypical adult), NOT for child
class FacialAnalyzer {

    // MARK: - Properties

    private var faceRequest: VNDetectFaceLandmarksRequest
    private var tensionHistory: [TensionLevel] = []
    private let maxHistorySize = 10

    // MARK: - Initialization

    init() {
        faceRequest = VNDetectFaceLandmarksRequest()
    }

    // MARK: - Parent Stress Analysis

    /// Analyze parent stress from facial expression (PARENT ONLY, NOT CHILD)
    func analyzeParentStress(from pixelBuffer: CVPixelBuffer, vocalStress: VocalStress? = nil) async throws -> ParentStressAnalysis {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        try handler.perform([faceRequest])

        guard let observation = faceRequest.results?.first,
              let landmarks = observation.landmarks else {
            throw FacialAnalyzerError.noFaceDetected
        }

        // Analyze facial tension indicators
        let facialTension = analyzeFacialTension(landmarks: landmarks)

        // Add to history for smoothing
        tensionHistory.append(facialTension)
        if tensionHistory.count > maxHistorySize {
            tensionHistory.removeFirst()
        }

        // Use vocal stress if available
        let vocal = vocalStress ?? .calm

        // Synthesize overall stress level
        let overallStress = synthesizeStressLevel(facial: facialTension, vocal: vocal)

        return ParentStressAnalysis(
            facialTension: facialTension,
            vocalStress: vocal,
            overallStressLevel: overallStress,
            confidence: calculateConfidence(landmarks: landmarks),
            timestamp: Date()
        )
    }

    // MARK: - Facial Tension Analysis

    /// Analyze facial tension from landmarks
    private func analyzeFacialTension(landmarks: VNFaceLandmarks2D) -> TensionLevel {
        var tensionScore: Float = 0.0

        // 1. Analyze brow tension (corrugator muscle - furrowed brow)
        if let leftEyebrow = landmarks.leftEyebrow,
           let rightEyebrow = landmarks.rightEyebrow {
            let browTension = analyzeBrowTension(left: leftEyebrow, right: rightEyebrow)
            tensionScore += browTension * 0.3
        }

        // 2. Analyze jaw tension (masseter muscle)
        if let jawline = landmarks.faceContour {
            let jawTension = analyzeJawTension(jawline: jawline)
            tensionScore += jawTension * 0.3
        }

        // 3. Analyze lip tension (compressed lips)
        if let outerLips = landmarks.outerLips,
           let innerLips = landmarks.innerLips {
            let lipTension = analyzeLipTension(outer: outerLips, inner: innerLips)
            tensionScore += lipTension * 0.2
        }

        // 4. Analyze eye tension (narrowed eyes)
        if let leftEye = landmarks.leftEye,
           let rightEye = landmarks.rightEye {
            let eyeTension = analyzeEyeTension(left: leftEye, right: rightEye)
            tensionScore += eyeTension * 0.2
        }

        // Classify tension level
        switch tensionScore {
        case 0..<0.3:
            return .relaxed
        case 0.3..<0.7:
            return .moderate
        default:
            return .high
        }
    }

    // MARK: - Specific Feature Analysis

    /// Analyze eyebrow tension (furrowed brow indicates stress)
    private func analyzeBrowTension(left: VNFaceLandmarkRegion2D, right: VNFaceLandmarkRegion2D) -> Float {
        let leftPoints = left.normalizedPoints
        let rightPoints = right.normalizedPoints

        guard leftPoints.count > 2, rightPoints.count > 2 else { return 0 }

        // Get inner points of eyebrows
        let leftInner = leftPoints[leftPoints.count - 1]
        let rightInner = rightPoints[0]

        // Calculate angle of eyebrows
        // Negative angle = furrowed (stressed)
        // Positive angle = raised (surprised/calm)
        let angle = atan2(Double(rightInner.y - leftInner.y), Double(rightInner.x - leftInner.x)) * 180 / .pi

        // Also check vertical position (lowered brows = tension)
        let avgBrowY = (leftInner.y + rightInner.y) / 2

        var tension: Float = 0

        // Lowered or furrowed brows
        if angle < -5.0 || avgBrowY < 0.4 {
            tension = 0.8
        } else if angle < 0 || avgBrowY < 0.45 {
            tension = 0.5
        }

        return tension
    }

    /// Analyze jaw tension (tight jaw indicates stress)
    private func analyzeJawTension(jawline: VNFaceLandmarkRegion2D) -> Float {
        let points = jawline.normalizedPoints

        guard points.count > 10 else { return 0 }

        // Get jaw corner points (left and right)
        let leftJaw = points[2]   // Approximate left jaw point
        let rightJaw = points[points.count - 3]  // Approximate right jaw point
        let chinPoint = points[points.count / 2]  // Chin

        // Calculate jaw width vs height ratio
        let jawWidth = abs(rightJaw.x - leftJaw.x)
        let jawHeight = abs(chinPoint.y - leftJaw.y)

        // Tense jaw tends to be wider and flatter
        let ratio = Float(jawWidth / max(jawHeight, 0.01))

        var tension: Float = 0

        // Higher ratio = more tension
        if ratio > 2.5 {
            tension = 0.8
        } else if ratio > 2.0 {
            tension = 0.5
        } else if ratio > 1.5 {
            tension = 0.3
        }

        return tension
    }

    /// Analyze lip tension (compressed lips indicate stress)
    private func analyzeLipTension(outer: VNFaceLandmarkRegion2D, inner: VNFaceLandmarkRegion2D) -> Float {
        let outerPoints = outer.normalizedPoints
        let innerPoints = inner.normalizedPoints

        guard outerPoints.count > 6, innerPoints.count > 6 else { return 0 }

        // Get top and bottom lip points
        let topOuter = outerPoints[3]  // Top center
        let bottomOuter = outerPoints[9]  // Bottom center
        let topInner = innerPoints[3]
        let bottomInner = innerPoints[9]

        // Calculate lip separation
        let outerHeight = abs(bottomOuter.y - topOuter.y)
        let innerHeight = abs(bottomInner.y - topInner.y)

        // Compressed lips have very small separation
        let avgHeight = (outerHeight + innerHeight) / 2

        var tension: Float = 0

        if avgHeight < 0.02 {  // Very compressed
            tension = 0.9
        } else if avgHeight < 0.04 {  // Moderately compressed
            tension = 0.6
        } else if avgHeight < 0.06 {  // Slightly compressed
            tension = 0.3
        }

        return tension
    }

    /// Analyze eye tension (narrowed eyes can indicate stress)
    private func analyzeEyeTension(left: VNFaceLandmarkRegion2D, right: VNFaceLandmarkRegion2D) -> Float {
        let leftPoints = left.normalizedPoints
        let rightPoints = right.normalizedPoints

        guard leftPoints.count > 4, rightPoints.count > 4 else { return 0 }

        // Calculate eye openness (vertical distance)
        let leftTop = leftPoints[1]
        let leftBottom = leftPoints[5]
        let rightTop = rightPoints[1]
        let rightBottom = rightPoints[5]

        let leftOpenness = abs(leftBottom.y - leftTop.y)
        let rightOpenness = abs(rightBottom.y - rightTop.y)

        let avgOpenness = (leftOpenness + rightOpenness) / 2

        var tension: Float = 0

        // Very narrow eyes
        if avgOpenness < 0.02 {
            tension = 0.7
        } else if avgOpenness < 0.04 {
            tension = 0.4
        }

        return tension
    }

    // MARK: - Synthesis

    /// Combine facial and vocal stress into overall stress level
    private func synthesizeStressLevel(facial: TensionLevel, vocal: VocalStress) -> StressLevel {
        var score = 0

        // Facial contribution: 0-2 points
        switch facial {
        case .relaxed: score += 0
        case .moderate: score += 1
        case .high: score += 2
        }

        // Vocal contribution: 0-2 points
        switch vocal {
        case .calm, .flat: score += 0
        case .elevated: score += 1
        case .strained: score += 2
        }

        // Classify overall stress
        switch score {
        case 0...1: return .calm
        case 2...3: return .building
        default: return .high
        }
    }

    /// Calculate confidence based on landmark quality
    private func calculateConfidence(landmarks: VNFaceLandmarks2D) -> Float {
        // Check if we have all important features
        var featureCount = 0
        var totalFeatures = 0

        if landmarks.leftEyebrow != nil {
            featureCount += 1
        }
        totalFeatures += 1

        if landmarks.rightEyebrow != nil {
            featureCount += 1
        }
        totalFeatures += 1

        if landmarks.faceContour != nil {
            featureCount += 1
        }
        totalFeatures += 1

        if landmarks.outerLips != nil {
            featureCount += 1
        }
        totalFeatures += 1

        if landmarks.leftEye != nil {
            featureCount += 1
        }
        totalFeatures += 1

        if landmarks.rightEye != nil {
            featureCount += 1
        }
        totalFeatures += 1

        return Float(featureCount) / Float(totalFeatures)
    }

    /// Get smoothed tension level from history
    func getSmoothedTension() -> TensionLevel {
        guard !tensionHistory.isEmpty else { return .moderate }

        // Count occurrences
        var relaxedCount = 0
        var moderateCount = 0
        var highCount = 0

        for tension in tensionHistory {
            switch tension {
            case .relaxed: relaxedCount += 1
            case .moderate: moderateCount += 1
            case .high: highCount += 1
            }
        }

        // Return most common
        let maxCount = max(relaxedCount, moderateCount, highCount)

        if maxCount == highCount {
            return .high
        } else if maxCount == moderateCount {
            return .moderate
        } else {
            return .relaxed
        }
    }

    /// Clear tension history
    func clearHistory() {
        tensionHistory.removeAll()
    }
}

// MARK: - Errors

enum FacialAnalyzerError: Error {
    case noFaceDetected
    case landmarkExtractionFailed
    case insufficientLandmarks
}
