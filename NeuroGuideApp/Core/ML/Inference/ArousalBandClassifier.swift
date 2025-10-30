//
//  ArousalBandClassifier.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 2 - ML Foundation (Arousal Band Classification)
//

import Foundation
import AVFoundation
import Combine

/// Classifies child's current arousal band based on multimodal signals
/// Combines pose, facial expression, and vocal affect into arousal band prediction
@MainActor
class ArousalBandClassifier: ObservableObject {
    // MARK: - Singleton

    static let shared = ArousalBandClassifier()

    // MARK: - Published Properties

    @Published private(set) var currentArousalBand: ArousalBand?
    @Published private(set) var currentConfidence: Double = 0.0
    @Published private(set) var lastClassificationTime: Date?

    // MARK: - Private Properties

    private let poseService: PoseDetectionService
    private let facialService: FacialExpressionService
    private let vocalService: VocalAffectService

    // History for temporal smoothing
    private var arousalHistory: [ArousalReading] = []
    private let historyWindow: Int = 5  // Keep last 5 readings

    // MARK: - Initialization

    init(
        poseService: PoseDetectionService = .shared,
        facialService: FacialExpressionService = .shared,
        vocalService: VocalAffectService = .shared
    ) {
        self.poseService = poseService
        self.facialService = facialService
        self.vocalService = vocalService
    }

    // MARK: - Classification

    /// Classify arousal band from multimodal input
    /// - Parameters:
    ///   - image: Video frame for pose and facial analysis
    ///   - audioBuffer: Audio buffer for vocal analysis (optional)
    /// - Returns: Arousal band classification with confidence
    func classifyArousalBand(
        image: CGImage,
        audioBuffer: AVAudioPCMBuffer? = nil
    ) async throws -> ArousalBandClassification {
        // Extract features from each modality concurrently
        async let poseFeatures = extractPoseFeatures(image: image)
        async let facialFeatures = extractFacialFeatures(image: image)
        async let vocalFeatures = extractVocalFeatures(audioBuffer: audioBuffer)

        // Wait for all features
        let (pose, facial, vocal) = await (poseFeatures, facialFeatures, vocalFeatures)

        // Fuse multimodal signals
        let (band, confidence) = fuseSignals(
            pose: pose,
            facial: facial,
            vocal: vocal
        )

        // Apply temporal smoothing
        let smoothedResult = applyTemporalSmoothing(band: band, confidence: confidence)

        // Update published properties
        currentArousalBand = smoothedResult.band
        currentConfidence = smoothedResult.confidence
        lastClassificationTime = Date()

        return ArousalBandClassification(
            arousalBand: smoothedResult.band,
            confidence: smoothedResult.confidence,
            contributions: ModalityContributions(
                pose: pose?.arousalContribution ?? 0.0,
                facial: facial?.arousalContribution ?? 0.0,
                vocal: vocal?.arousalContribution ?? 0.0
            ),
            timestamp: Date()
        )
    }

    /// Classify from individual features (for testing)
    func classifyFromFeatures(
        pose: PoseFeatures?,
        facial: FacialFeatures?,
        vocal: VocalFeatures?
    ) -> ArousalBandClassification {
        let (band, confidence) = fuseSignals(pose: pose, facial: facial, vocal: vocal)

        return ArousalBandClassification(
            arousalBand: band,
            confidence: confidence,
            contributions: ModalityContributions(
                pose: pose?.arousalContribution ?? 0.0,
                facial: facial?.arousalContribution ?? 0.0,
                vocal: vocal?.arousalContribution ?? 0.0
            ),
            timestamp: Date()
        )
    }

    // MARK: - Feature Extraction

    private func extractPoseFeatures(image: CGImage) async -> PoseFeatures? {
        do {
            return try await poseService.extractPoseFeatures(from: image)
        } catch {
            print("⚠️ Pose detection failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func extractFacialFeatures(image: CGImage) async -> FacialFeatures? {
        do {
            return try await facialService.extractFacialFeatures(from: image)
        } catch {
            print("⚠️ Facial expression detection failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func extractVocalFeatures(audioBuffer: AVAudioPCMBuffer?) async -> VocalFeatures? {
        guard let buffer = audioBuffer else { return nil }

        do {
            return try await vocalService.extractVocalFeatures(from: buffer)
        } catch {
            print("⚠️ Vocal affect analysis failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Signal Fusion

    private func fuseSignals(
        pose: PoseFeatures?,
        facial: FacialFeatures?,
        vocal: VocalFeatures?
    ) -> (band: ArousalBand, confidence: Double) {
        // Weighted fusion of multimodal signals
        // Weights determined by modality availability and confidence

        var totalArousal: Double = 0.0
        var totalWeight: Double = 0.0

        // Pose contribution
        if let pose = pose {
            let weight = 0.35 * pose.keypointConfidence
            totalArousal += pose.arousalContribution * weight
            totalWeight += weight
        }

        // Facial contribution
        if let facial = facial {
            let weight = 0.40 * facial.confidence
            totalArousal += facial.arousalContribution * weight
            totalWeight += weight
        }

        // Vocal contribution
        if let vocal = vocal {
            let weight = 0.25  // Vocal is less reliable without trained model
            totalArousal += vocal.arousalContribution * weight
            totalWeight += weight
        }

        // Normalize
        let normalizedArousal = totalWeight > 0 ? totalArousal / totalWeight : 0.5

        // Map arousal score to arousal band
        let band = mapToArousalBand(arousalScore: normalizedArousal)

        // Confidence based on number of modalities and agreement
        let confidence = calculateConfidence(
            arousalScore: normalizedArousal,
            totalWeight: totalWeight,
            modalityCount: [pose, facial, vocal].compactMap { $0 }.count
        )

        return (band, confidence)
    }

    private func mapToArousalBand(arousalScore: Double) -> ArousalBand {
        // Map 0-1 arousal score to arousal bands
        // Thresholds tuned for neurodivergent children

        if arousalScore < 0.2 {
            return .shutdown  // Under-aroused, withdrawn
        } else if arousalScore < 0.45 {
            return .green  // Regulated, calm
        } else if arousalScore < 0.65 {
            return .yellow  // Elevated, early warning
        } else if arousalScore < 0.85 {
            return .orange  // High arousal, needs support
        } else {
            return .red  // Crisis, safety priority
        }
    }

    private func calculateConfidence(
        arousalScore: Double,
        totalWeight: Double,
        modalityCount: Int
    ) -> Double {
        // Base confidence on:
        // 1. Number of available modalities (more is better)
        // 2. Total weight (higher weight = more confident signals)
        // 3. Distance from decision boundaries (further = more confident)

        let modalityFactor = Double(modalityCount) / 3.0  // Max 3 modalities
        let weightFactor = min(totalWeight, 1.0)

        // Distance from nearest boundary
        let boundaries = [0.2, 0.45, 0.65, 0.85]
        let minDistance = boundaries.map { abs(arousalScore - $0) }.min() ?? 0.5
        let boundaryFactor = min(minDistance * 2, 1.0)  // Normalize to 0-1

        // Weighted average
        let confidence = (modalityFactor * 0.4) +
                        (weightFactor * 0.3) +
                        (boundaryFactor * 0.3)

        return min(max(confidence, 0.1), 1.0)  // Clamp to 0.1-1.0
    }

    // MARK: - Temporal Smoothing

    private func applyTemporalSmoothing(
        band: ArousalBand,
        confidence: Double
    ) -> (band: ArousalBand, confidence: Double) {
        // Add to history
        let reading = ArousalReading(
            band: band,
            confidence: confidence,
            timestamp: Date()
        )
        arousalHistory.append(reading)

        // Keep only recent history
        if arousalHistory.count > historyWindow {
            arousalHistory.removeFirst()
        }

        // Smooth over history (weighted by recency and confidence)
        guard arousalHistory.count >= 3 else {
            return (band, confidence)  // Not enough history yet
        }

        // Count occurrences of each band in recent history
        var bandCounts: [ArousalBand: Double] = [:]
        for (index, reading) in arousalHistory.enumerated() {
            let recencyWeight = Double(index + 1) / Double(arousalHistory.count)
            let weight = reading.confidence * recencyWeight
            bandCounts[reading.band, default: 0.0] += weight
        }

        // Find most common band
        guard let smoothedBand = bandCounts.max(by: { $0.value < $1.value })?.key else {
            return (band, confidence)
        }

        // Adjusted confidence based on agreement
        let agreement = bandCounts[smoothedBand]! / bandCounts.values.reduce(0, +)
        let smoothedConfidence = confidence * agreement

        return (smoothedBand, smoothedConfidence)
    }

    // MARK: - History Management

    func clearHistory() {
        arousalHistory.removeAll()
        currentArousalBand = nil
        currentConfidence = 0.0
    }

    func getRecentHistory(count: Int = 10) -> [ArousalReading] {
        return Array(arousalHistory.suffix(count))
    }
}

// MARK: - Supporting Types

/// Classification result with arousal band and confidence
struct ArousalBandClassification {
    let arousalBand: ArousalBand
    let confidence: Double
    let contributions: ModalityContributions
    let timestamp: Date

    var isHighConfidence: Bool {
        return confidence >= 0.7
    }

    var needsMoreData: Bool {
        return confidence < 0.5
    }
}

/// Contribution of each modality to the classification
struct ModalityContributions {
    let pose: Double       // 0-1
    let facial: Double     // 0-1
    let vocal: Double      // 0-1

    var dominantModality: String {
        if pose > facial && pose > vocal {
            return "Pose"
        } else if facial > vocal {
            return "Facial"
        } else {
            return "Vocal"
        }
    }
}

/// A single arousal reading with timestamp
struct ArousalReading: Identifiable {
    let id = UUID()
    let band: ArousalBand
    let confidence: Double
    let timestamp: Date
}

// MARK: - Mock Classifier (for testing without camera)

extension ArousalBandClassifier {
    /// Create mock classification for testing
    static func mockClassification(band: ArousalBand = .green) -> ArousalBandClassification {
        return ArousalBandClassification(
            arousalBand: band,
            confidence: 0.85,
            contributions: ModalityContributions(
                pose: 0.5,
                facial: 0.6,
                vocal: 0.4
            ),
            timestamp: Date()
        )
    }

    /// Simulate random arousal band changes (for demo)
    func simulateReading() -> ArousalBandClassification {
        let bands: [ArousalBand] = [.green, .yellow, .orange]
        let randomBand = bands.randomElement() ?? .green

        let classification = ArousalBandClassification(
            arousalBand: randomBand,
            confidence: Double.random(in: 0.7...0.95),
            contributions: ModalityContributions(
                pose: Double.random(in: 0.4...0.7),
                facial: Double.random(in: 0.4...0.7),
                vocal: Double.random(in: 0.3...0.6)
            ),
            timestamp: Date()
        )

        currentArousalBand = randomBand
        currentConfidence = classification.confidence

        return classification
    }
}
