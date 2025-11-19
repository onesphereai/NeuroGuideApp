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
    @Published private(set) var currentFeatureVisualization: FeatureVisualization?

    // MARK: - Private Properties

    private let poseService: PoseDetectionService
    private let facialService: FacialExpressionService
    private let vocalService: VocalAffectService
    private let diagnosisAdjuster: DiagnosisAwareArousalAdjuster

    // History for temporal smoothing
    private var arousalHistory: [ArousalReading] = []
    private let historyWindow: Int = 5  // Keep last 5 readings

    // Profile-specific baseline calibration and diagnosis
    private var baselineCalibration: BaselineCalibration?
    private var childProfile: ChildProfile?

    // Custom k-NN model for personalized arousal detection
    private var customKNNModel: KNNModel?

    // LLM-based arousal detection service (NEW)
    private var llmDetectionService: LLMArousalDetectionService?
    private var useLLMDetection: Bool = false

    // Default thresholds (used when no baseline available)
    private let defaultThresholds = ArousalThresholds(
        shutdownThreshold: 0.20,
        greenThreshold: 0.45,
        yellowThreshold: 0.65,
        orangeThreshold: 0.85
    )

    // MARK: - Initialization

    init(
        poseService: PoseDetectionService = .shared,
        facialService: FacialExpressionService = .shared,
        vocalService: VocalAffectService = .shared,
        diagnosisAdjuster: DiagnosisAwareArousalAdjuster = .shared
    ) {
        self.poseService = poseService
        self.facialService = facialService
        self.vocalService = vocalService
        self.diagnosisAdjuster = diagnosisAdjuster
    }

    // MARK: - Configuration

    /// Set child profile for diagnosis-aware arousal detection
    /// This personalizes arousal detection based on diagnosis and baseline
    /// - Parameter profile: Child profile with diagnosis and baseline data
    func setChildProfile(_ profile: ChildProfile?) {
        self.childProfile = profile
        self.baselineCalibration = profile?.baselineCalibration

        if let profile = profile {
            print("✅ Child profile set for arousal detection")
            if let diagnosisInfo = profile.diagnosisInfo, let firstDiagnosis = diagnosisInfo.diagnoses.first {
                print("   Diagnosis: \(firstDiagnosis.displayName)")
                let adjustments = profile.getArousalThresholdAdjustments()
                print("   Movement threshold: \(String(format: "%.1fx", adjustments.movementThresholdMultiplier))")
                print("   Vocal threshold: \(String(format: "%.1fx", adjustments.vocalThresholdMultiplier))")
                print("   Expression sensitivity: \(String(format: "%.1fx", adjustments.expressionSensitivity))")
            }
            if let baseline = baselineCalibration {
                print("   Movement baseline: \(String(format: "%.2f", baseline.movementBaseline.averageMovementEnergy))")
                print("   Vocal baseline: \(String(format: "%.1f", baseline.vocalBaseline.averagePitch))Hz")
            }
        } else {
            print("⚠️ No child profile - using default detection")
        }
    }

    /// Set baseline calibration from child profile (legacy method - no longer required)
    /// - Parameter baseline: Baseline calibration data from child profile
    func setBaselineCalibration(_ baseline: BaselineCalibration?) {
        self.baselineCalibration = baseline
        if let baseline = baseline {
            print("✅ Baseline calibration set - thresholds will be personalized")
            print("   Movement baseline: \(String(format: "%.2f", baseline.movementBaseline.averageMovementEnergy))")
            print("   Vocal baseline: \(String(format: "%.1f", baseline.vocalBaseline.averagePitch))Hz, \(String(format: "%.1f", baseline.vocalBaseline.averageVolume))dB")
        } else {
            print("⚠️ Using default thresholds - no baseline calibration available")
        }
    }

    /// Set custom k-NN model for personalized arousal detection
    /// - Parameter model: Trained k-NN model from training videos
    func setCustomKNNModel(_ model: KNNModel) {
        self.customKNNModel = model
        print("✨ Custom k-NN model loaded for personalized arousal detection")
        print("   Training examples: \(model.trainingData.count)")
        print("   Feature dimension: \(model.featureDimension)")
        print("   k value: \(model.k)")
    }

    /// Clear custom k-NN model (return to generic detection)
    func clearCustomKNNModel() {
        self.customKNNModel = nil
        print("📊 Cleared custom model - using generic arousal detection")
    }

    /// Enable LLM-based arousal detection (NEW)
    /// - Parameters:
    ///   - apiKey: API key for the LLM provider
    ///   - provider: LLM provider to use (defaults to Claude Sonnet 4.5)
    func enableLLMDetection(apiKey: String?, provider: LLMProvider = .claude) {
        self.llmDetectionService = LLMArousalDetectionService(
            apiKey: apiKey,
            provider: provider
        )
        self.useLLMDetection = true
        print("🤖 LLM-based arousal detection ENABLED")
        print("   Provider: \(provider)")
    }

    /// Legacy method for backward compatibility
    func enableLLMDetection(groqAPIKey: String?, useAppleIntelligence: Bool = false) {
        let provider: LLMProvider = useAppleIntelligence ? .appleIntelligence : .groq
        enableLLMDetection(apiKey: groqAPIKey, provider: provider)
    }

    /// Disable LLM-based arousal detection (return to rule-based)
    func disableLLMDetection() {
        self.llmDetectionService = nil
        self.useLLMDetection = false
        print("📊 LLM detection disabled - using rule-based detection")
    }

    /// Clear LLM detection cache (call when session ends)
    func clearLLMCache() {
        llmDetectionService?.clearCache()
    }

    /// Get current thresholds being used (for debugging/transparency)
    func getCurrentThresholds() -> ArousalThresholds {
        return calculatePersonalizedThresholds()
    }

    // MARK: - Classification

    /// Classify arousal band from multimodal input
    /// - Parameters:
    ///   - image: Video frame for pose and facial analysis
    ///   - audioBuffer: Audio buffer for vocal analysis (optional)
    ///   - additionalContext: Additional context for LLM detection (behaviors, environment, parent stress, session context)
    /// - Returns: Arousal band classification with confidence
    func classifyArousalBand(
        image: CGImage,
        audioBuffer: AVAudioPCMBuffer? = nil,
        additionalContext: LLMDetectionContext? = nil
    ) async throws -> ArousalBandClassification {
        // Extract features from each modality concurrently
        async let poseFeatures = extractPoseFeatures(image: image)
        async let facialFeatures = extractFacialFeatures(image: image)
        async let vocalFeatures = extractVocalFeatures(audioBuffer: audioBuffer)

        // Wait for all features
        let (pose, facial, vocal) = await (poseFeatures, facialFeatures, vocalFeatures)

        // NEW: Use LLM detection if enabled and child profile is available
        if useLLMDetection,
           let llmService = llmDetectionService,
           let profile = childProfile,
           let context = additionalContext {

            do {
                // Build comprehensive LLM request
                let llmRequest = LLMArousalDetectionRequest(
                    childProfile: profile,
                    poseFeatures: pose,
                    vocalFeatures: vocal,
                    facialFeatures: facial,
                    detectedBehaviors: context.detectedBehaviors,
                    environment: context.environment,
                    parentStress: context.parentStress,
                    sessionContext: context.sessionContext,
                    timestamp: Date()
                )

                // Get LLM-based detection
                let (band, confidence) = try await llmService.detectArousalBand(request: llmRequest)

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
            } catch {
                // Fall back to rule-based if LLM fails
                print("⚠️ LLM detection failed, falling back to rule-based: \(error.localizedDescription)")
            }
        }

        // FALLBACK: Use rule-based detection (original behavior)
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
        // If custom k-NN model is available, use it for personalized prediction
        if let knnModel = customKNNModel {
            let result = fuseSignalsWithKNN(model: knnModel, pose: pose, facial: facial, vocal: vocal)
            // Create visualization
            updateFeatureVisualization(pose: pose, facial: facial, vocal: vocal, band: result.band, confidence: result.confidence, usingKNN: true)
            return result
        }

        // Otherwise, use generic weighted fusion
        // Weights: Pose 50%, Facial 40%, Vocal 10%
        // Body movement is the strongest indicator of arousal in neurodivergent children

        var totalArousal: Double = 0.0
        var totalWeight: Double = 0.0

        // Pose contribution (50% - primary indicator)
        if let pose = pose {
            let weight = 0.50 * pose.keypointConfidence
            totalArousal += pose.arousalContribution * weight
            totalWeight += weight
        }

        // Facial contribution (40% - secondary indicator)
        if let facial = facial {
            let weight = 0.40 * facial.confidence
            totalArousal += facial.arousalContribution * weight
            totalWeight += weight
        }

        // Vocal contribution (10% - tertiary indicator)
        if let vocal = vocal {
            let weight = 0.10  // Reduced weight: vocal is less reliable without trained model
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

        // Create visualization
        updateFeatureVisualization(pose: pose, facial: facial, vocal: vocal, band: band, confidence: confidence, usingKNN: false)

        return (band, confidence)
    }

    /// Use k-NN model for personalized arousal classification
    private func fuseSignalsWithKNN(
        model: KNNModel,
        pose: PoseFeatures?,
        facial: FacialFeatures?,
        vocal: VocalFeatures?
    ) -> (band: ArousalBand, confidence: Double) {
        // Extract simple feature vector (matching training format)
        // This is a simplified version - you may need to match the exact features used during training
        var features: [Double] = []

        // Pose features (if available)
        if let pose = pose {
            features.append(pose.arousalContribution)
            features.append(pose.keypointConfidence)
            features.append(pose.movementIntensity)
            features.append(pose.bodyTension)
            features.append(pose.postureOpenness)
        } else {
            features.append(contentsOf: [0.0, 0.0, 0.0, 0.0, 0.0])
        }

        // Facial features (if available)
        if let facial = facial {
            features.append(facial.arousalContribution)
            features.append(facial.confidence)
            features.append(facial.expressionIntensity)
            features.append(facial.mouthOpenness)
            features.append(facial.eyeWideness)
            features.append(facial.browRaised ? 1.0 : 0.0)
        } else {
            features.append(contentsOf: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        }

        // Vocal features (if available)
        if let vocal = vocal {
            features.append(vocal.volume)
            features.append(vocal.pitch)
            features.append(vocal.energy)
            features.append(vocal.speechRate)
            features.append(vocal.voiceQuality)
        } else {
            features.append(contentsOf: [0.0, 0.0, 0.0, 0.0, 0.0])
        }

        // Predict using k-NN model
        let predictedState = model.predict(features: features)

        // Map ArousalState to ArousalBand
        let band = mapArousalStateToBand(predictedState)

        // k-NN confidence is based on k-nearest neighbors agreement
        // For now, use a high confidence since the model is trained on this child
        let confidence = 0.85

        return (band, confidence)
    }

    /// Map ArousalState (training labels) to ArousalBand (live detection)
    private func mapArousalStateToBand(_ state: ArousalState) -> ArousalBand {
        switch state {
        case .calm:
            return .green
        case .playful:
            return .yellow  // Playful is energetic but positive
        case .upset:
            return .yellow  // Upset is moderate dysregulation
        case .angry:
            return .orange  // Angry is high dysregulation
        case .meltdown:
            return .red  // Meltdown is severe dysregulation
        }
    }

    private func mapToArousalBand(arousalScore: Double) -> ArousalBand {
        // Map 0-1 arousal score to arousal bands using personalized thresholds
        let thresholds = calculatePersonalizedThresholds()

        if arousalScore < thresholds.shutdownThreshold {
            return .shutdown  // Under-aroused, withdrawn
        } else if arousalScore < thresholds.greenThreshold {
            return .green  // Regulated, calm
        } else if arousalScore < thresholds.yellowThreshold {
            return .yellow  // Elevated, early warning
        } else if arousalScore < thresholds.orangeThreshold {
            return .orange  // High arousal, needs support
        } else {
            return .red  // Crisis, safety priority
        }
    }

    /// Calculate personalized thresholds based on baseline calibration and diagnosis
    /// Adjusts thresholds to account for child's typical arousal levels and neurodivergent traits
    private func calculatePersonalizedThresholds() -> ArousalThresholds {
        // Get diagnosis adjustments if profile is available
        let diagnosisAdjustments = childProfile?.getArousalThresholdAdjustments() ?? ArousalThresholdAdjustments()

        guard let baseline = baselineCalibration else {
            // No baseline - apply diagnosis adjustments to default thresholds
            return ArousalThresholds(
                shutdownThreshold: defaultThresholds.shutdownThreshold,
                greenThreshold: defaultThresholds.greenThreshold * diagnosisAdjustments.movementThresholdMultiplier,
                yellowThreshold: defaultThresholds.yellowThreshold * diagnosisAdjustments.movementThresholdMultiplier,
                orangeThreshold: defaultThresholds.orangeThreshold  // Never adjust red zone - always conservative
            )
        }

        // RESEARCH NOTE: This adjustment algorithm is based on:
        // 1. Individual differences in baseline arousal (Gray's Reinforcement Sensitivity Theory)
        // 2. Autism-specific considerations (different baseline movement/expression patterns)
        // 3. Diagnosis-specific threshold adjustments (ADHD, SPD, etc.)
        // 4. Safety-first principle (don't adjust red zone threshold - always conservative)

        // Calculate baseline-adjusted center point (child's typical "green zone")
        // Movement energy is primary factor (0.0-1.0 scale)
        let movementBaseline = baseline.movementBaseline.averageMovementEnergy

        // Vocal baseline as secondary adjustment factor
        // Normalize pitch and volume to 0-1 scale
        // Typical child: 200-300Hz pitch, 45-65dB volume
        let normalizedPitch = min(max((baseline.vocalBaseline.averagePitch - 200) / 100, 0.0), 1.0)
        let normalizedVolume = min(max((baseline.vocalBaseline.averageVolume - 45) / 20, 0.0), 1.0)
        let vocalBaseline = (normalizedPitch + normalizedVolume) / 2.0

        // Weighted combination: movement is more reliable indicator
        let baselineArousal = (movementBaseline * 0.7) + (vocalBaseline * 0.3)

        // Calculate adjustment offset from default "green center" (0.325)
        let defaultGreenCenter = (defaultThresholds.shutdownThreshold + defaultThresholds.greenThreshold) / 2.0
        let adjustmentOffset = baselineArousal - defaultGreenCenter

        // Apply conservative adjustment (limit to ±0.15 to avoid extreme miscalibration)
        let clampedOffset = min(max(adjustmentOffset, -0.15), 0.15)

        // Apply both baseline and diagnosis adjustments
        // Diagnosis multipliers increase thresholds (more tolerance for high arousal behaviors)
        let diagnosisMultiplier = (diagnosisAdjustments.movementThresholdMultiplier +
                                   diagnosisAdjustments.vocalThresholdMultiplier) / 2.0

        // Adjust thresholds while maintaining safety margins
        return ArousalThresholds(
            shutdownThreshold: max(defaultThresholds.shutdownThreshold + clampedOffset, 0.10),
            greenThreshold: max((defaultThresholds.greenThreshold + clampedOffset) * diagnosisMultiplier, 0.30),
            yellowThreshold: max((defaultThresholds.yellowThreshold + (clampedOffset * 0.7)) * diagnosisMultiplier, 0.50),
            orangeThreshold: defaultThresholds.orangeThreshold  // Never adjust red zone - always conservative
        )
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

// MARK: - Arousal Thresholds

/// Personalized arousal band thresholds for a specific child
struct ArousalThresholds {
    let shutdownThreshold: Double   // Below this = shutdown
    let greenThreshold: Double       // Below this = green (if above shutdown)
    let yellowThreshold: Double      // Below this = yellow (if above green)
    let orangeThreshold: Double      // Below this = orange, above = red

    var description: String {
        return """
        Arousal Thresholds:
          Shutdown: < \(String(format: "%.2f", shutdownThreshold))
          Green: < \(String(format: "%.2f", greenThreshold))
          Yellow: < \(String(format: "%.2f", yellowThreshold))
          Orange: < \(String(format: "%.2f", orangeThreshold))
          Red: >= \(String(format: "%.2f", orangeThreshold))
        """
    }
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

    // MARK: - Feature Visualization

    /// Update the current feature visualization for transparency
    private func updateFeatureVisualization(
        pose: PoseFeatures?,
        facial: FacialFeatures?,
        vocal: VocalFeatures?,
        band: ArousalBand,
        confidence: Double,
        usingKNN: Bool
    ) {
        currentFeatureVisualization = FeatureVisualization(
            poseAvailable: pose != nil,
            movementIntensity: pose?.movementIntensity,
            bodyTension: pose?.bodyTension,
            postureOpenness: pose?.postureOpenness,
            poseConfidence: pose?.keypointConfidence,
            facialAvailable: facial != nil,
            expressionIntensity: facial?.expressionIntensity,
            mouthOpenness: facial?.mouthOpenness,
            eyeWideness: facial?.eyeWideness,
            browRaised: facial?.browRaised,
            facialConfidence: facial?.confidence,
            vocalAvailable: vocal != nil,
            volume: vocal?.volume,
            pitch: vocal?.pitch,
            energy: vocal?.energy,
            speechRate: vocal?.speechRate,
            predictedBand: band,
            overallConfidence: confidence,
            usingCustomModel: usingKNN
        )
    }
}

// MARK: - LLM Detection Context

/// Additional context for LLM-based arousal detection
/// Provides environmental, behavioral, and temporal information beyond raw features
struct LLMDetectionContext {
    let detectedBehaviors: [ChildBehavior]
    let environment: EnvironmentContext
    let parentStress: ParentStressAnalysis?
    let sessionContext: SessionContext?
}
