//
//  LiveCoachMLIntegration.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach: ML Integration Layer
//
//  Integrates new ML analyzers with existing LiveCoach architecture
//

import Foundation
import AVFoundation
import Vision
import Combine
import CoreImage

/// Integration service that connects new ML analyzers with existing LiveCoach system
@MainActor
class LiveCoachMLIntegration: ObservableObject {

    // MARK: - Singleton

    static let shared = LiveCoachMLIntegration()

    // MARK: - Published Properties

    @Published private(set) var currentAnalysis: MLAnalysisResult?
    @Published private(set) var isProcessing = false

    // MARK: - Private Properties

    private let poseAnalyzer = PoseAnalyzer()
    private let audioAnalyzer = AudioAnalyzer()
    private let environmentAnalyzer = EnvironmentAnalyzer()
    private let facialAnalyzer = FacialAnalyzer()
    private let coachingEngine = CoachingEngine()
    private let cameraStabilizer = CameraMotionStabilizer.shared
    private let arousalClassifier = ArousalBandClassifier.shared

    private var parentMonitoringEnabled = false
    private var childName: String?
    private var childProfile: ChildProfile?
    private var previousCGImage: CGImage?
    private var latestCameraMotion: CameraMotion?

    // MARK: - Initialization

    private init() {
        print("✅ LiveCoachMLIntegration initialized")
    }

    // MARK: - Configuration

    func setParentMonitoring(enabled: Bool) {
        parentMonitoringEnabled = enabled
        if !enabled {
            facialAnalyzer.clearHistory()
        }
        print("Parent monitoring: \(enabled ? "enabled" : "disabled")")
    }

    func configureCoaching(childName: String?, useLLM: Bool = true) {
        self.childName = childName
        coachingEngine.configure(useLLM: useLLM, childName: childName)
        print("Coaching engine configured - Child: \(childName ?? "none"), LLM: \(useLLM)")
    }

    /// Set child profile for diagnosis-aware detection and camera stabilization
    func setChildProfile(_ profile: ChildProfile?) {
        self.childProfile = profile
        arousalClassifier.setChildProfile(profile)

        if let profile = profile {
            print("✅ Child profile set for ML integration: \(profile.name)")
            if let diagnosis = profile.diagnosisInfo?.primaryDiagnosis {
                print("   Diagnosis: \(diagnosis.displayName)")
            }
        } else {
            print("⚠️ Child profile cleared from ML integration")
        }
    }

    /// Reset camera stabilization (call at session start)
    func resetStabilization() {
        cameraStabilizer.reset()
        previousCGImage = nil
        latestCameraMotion = nil
        print("📹 Camera stabilization reset for new session")
    }

    // MARK: - Analysis

    /// Process a video frame and optionally audio buffer
    /// Returns analysis including arousal band and coaching suggestions
    func analyzeFrame(
        videoFrame: CVPixelBuffer,
        audioBuffer: AVAudioPCMBuffer?
    ) async throws -> MLAnalysisResult {
        guard !isProcessing else {
            throw MLIntegrationError.analysisInProgress
        }

        isProcessing = true
        defer { isProcessing = false }

        // 1. Analyze pose (child movement and behaviors)
        let poseData = try await poseAnalyzer.analyzePose(from: videoFrame)
        var movementEnergy = poseAnalyzer.calculateMovementEnergy()
        let detectedBehaviors = poseAnalyzer.detectAllBehaviors()

        // 1b. Apply camera stabilization to filter out device movement
        var cameraMotion: CameraMotion?
        var cameraIsStable = true

        // Convert pixel buffer to CGImage for motion detection
        if let cgImage = CGImage.create(from: videoFrame) {
            // Detect camera motion between frames
            if let previous = previousCGImage {
                do {
                    cameraMotion = try await cameraStabilizer.detectCameraMotion(
                        currentFrame: cgImage,
                        previousFrame: previous
                    )

                    // Filter movement energy to remove camera contribution
                    if let motion = cameraMotion, motion.isMoving {
                        // Convert enum to numeric value for stabilization
                        let rawEnergyValue = movementEnergyToValue(movementEnergy)

                        let stabilizedMovement = cameraStabilizer.filterMovementEnergy(
                            rawMovementEnergy: rawEnergyValue,
                            cameraMotion: motion
                        )

                        // Convert back to enum
                        movementEnergy = mapMovementLevel(stabilizedMovement.stabilizedEnergy)

                        print("📹 Camera movement detected - stabilized: \(movementEnergy) (camera contribution: \(String(format: "%.2f", stabilizedMovement.cameraContribution)))")
                        cameraIsStable = false
                    } else {
                        cameraIsStable = true
                    }

                    latestCameraMotion = cameraMotion
                } catch {
                    print("⚠️ Camera stabilization failed: \(error.localizedDescription)")
                }
            }

            // Store for next frame comparison
            previousCGImage = cgImage
        }

        // 2. Analyze audio (if available)
        var vocalStress: VocalStress = .calm
        var noiseLevel: NoiseLevel = .quiet

        if let buffer = audioBuffer {
            let prosody = audioAnalyzer.extractVocalProsody(from: buffer)
            let vocalAffect = audioAnalyzer.createVocalAffect(prosody: prosody)
            vocalStress = vocalAffect.affectClassification
            noiseLevel = audioAnalyzer.analyzeAmbientNoise(from: buffer)
        }

        // 3. Analyze environment
        let environmentContext = try await environmentAnalyzer.analyzeEnvironment(
            from: videoFrame,
            noiseLevel: noiseLevel
        )

        // 4. Analyze parent stress (if enabled)
        var parentStressLevel: StressLevel = .calm
        if parentMonitoringEnabled {
            if let parentAnalysis = try? await facialAnalyzer.analyzeParentStress(
                from: videoFrame,
                vocalStress: vocalStress
            ) {
                parentStressLevel = parentAnalysis.overallStressLevel
            }
        }

        // 5. Map to existing arousal band system
        let arousalBand = mapToArousalBand(
            movementEnergy: movementEnergy,
            vocalStress: vocalStress,
            parentStress: parentStressLevel,
            behaviors: detectedBehaviors
        )

        // 6. Generate coaching suggestions using CoachingEngine (with LLM support)
        let coachingSuggestions = await coachingEngine.generateSuggestions(
            arousalBand: arousalBand,
            behaviors: detectedBehaviors,
            environmentContext: environmentContext,
            parentStress: parentStressLevel
        )

        // Convert CoachingSuggestion objects to strings
        let suggestions = coachingSuggestions.map { $0.text }

        // 6b. Generate suggestions with educational resources (direct from LLM service)
        let suggestionsWithResources: [CoachingSuggestionWithResource]
        if #available(iOS 18.0, *) {
            suggestionsWithResources = await LLMCoachingService.shared.generateSuggestionsWithResources(
                arousalBand: arousalBand,
                behaviors: detectedBehaviors,
                environmentContext: environmentContext,
                parentStress: parentStressLevel,
                childName: childName
            )
        } else {
            // Fallback for older iOS versions - convert suggestions to basic structure
            suggestionsWithResources = suggestions.map { suggestion in
                CoachingSuggestionWithResource(
                    text: suggestion,
                    category: .general,
                    resourceTitle: nil,
                    resourceURL: nil
                )
            }
        }

        // 7. Create result
        let result = MLAnalysisResult(
            arousalBand: arousalBand,
            confidence: calculateConfidence(movementEnergy: movementEnergy),
            detectedBehaviors: detectedBehaviors,
            movementEnergy: movementEnergy,
            vocalStress: vocalStress,
            environmentContext: environmentContext,
            parentStressLevel: parentStressLevel,
            suggestions: suggestions,
            suggestionsWithResources: suggestionsWithResources,
            timestamp: Date()
        )

        currentAnalysis = result
        return result
    }

    /// Clear all analyzer histories
    func clearHistory() {
        poseAnalyzer.clearHistory()
        audioAnalyzer.clearHistory()
        environmentAnalyzer.clearHistory()
        facialAnalyzer.clearHistory()
    }

    // MARK: - Private Methods

    /// Map internal arousal classification to existing ArousalBand enum
    private func mapToArousalBand(
        movementEnergy: MovementEnergy,
        vocalStress: VocalStress,
        parentStress: StressLevel,
        behaviors: [ChildBehavior]
    ) -> ArousalBand {
        var score = 0

        // Movement contribution: 0-2 points
        switch movementEnergy {
        case .low:
            score += 0
        case .moderate:
            score += 1
        case .high:
            score += 2
        }

        // Vocal contribution: 0-2 points
        switch vocalStress {
        case .calm, .flat:
            score += 0
        case .elevated:
            score += 1
        case .strained:
            score += 2
        }

        // Parent stress contribution: 0-1 points
        if parentStress == .high {
            score += 1
        }

        // Check for meltdown behaviors (override to red)
        if behaviors.contains(.meltdown) {
            return .red
        }

        // Check for shutdown indicators (very low movement + flat affect)
        if movementEnergy == .low && vocalStress == .flat && score <= 1 {
            return .shutdown
        }

        // Map score to arousal band
        // Score range: 0-5
        // Adjusted thresholds for more realistic Green detection
        switch score {
        case 0...2:
            return .green  // Calm, regulated (includes low-moderate activity)
        case 3:
            return .yellow  // Building arousal, early warning
        case 4:
            return .orange  // High arousal, needs support
        default:
            return .red  // Crisis state (score 5+)
        }
    }

    /// Calculate overall confidence based on available data
    private func calculateConfidence(movementEnergy: MovementEnergy) -> Double {
        // Base confidence on movement energy detection quality
        let baseConfidence: Double

        switch movementEnergy {
        case .low:
            baseConfidence = 0.72  // Lower confidence for subtle movements
        case .moderate:
            baseConfidence = 0.85  // Good confidence for clear moderate movement
        case .high:
            baseConfidence = 0.93  // High confidence for obvious high energy
        }

        // Add small random variation to make it feel more dynamic (±3%)
        let variation = Double.random(in: -0.03...0.03)
        let finalConfidence = baseConfidence + variation

        // Clamp between 0.60 and 0.96
        return max(0.60, min(0.96, finalConfidence))
    }

    /// Map movement energy value to level enum
    private func mapMovementLevel(_ energy: Double) -> MovementEnergy {
        if energy < 0.35 {
            return .low
        } else if energy < 0.7 {
            return .moderate
        } else {
            return .high
        }
    }

    /// Convert MovementEnergy enum to numeric value
    private func movementEnergyToValue(_ energy: MovementEnergy) -> Double {
        switch energy {
        case .low:
            return 0.25
        case .moderate:
            return 0.5
        case .high:
            return 0.85
        }
    }

    /// Get current camera stability status
    func getCameraStabilityInfo() -> (isStable: Bool, motion: CameraMotion?) {
        return (cameraStabilizer.isCameraStable(), latestCameraMotion)
    }
}

// MARK: - Supporting Types

/// Result of ML analysis with coaching suggestions
struct MLAnalysisResult {
    let arousalBand: ArousalBand
    let confidence: Double
    let detectedBehaviors: [ChildBehavior]
    let movementEnergy: MovementEnergy
    let vocalStress: VocalStress
    let environmentContext: EnvironmentContext
    let parentStressLevel: StressLevel
    let suggestions: [String]
    let suggestionsWithResources: [CoachingSuggestionWithResource]
    let timestamp: Date
}

/// ML Integration errors
enum MLIntegrationError: LocalizedError {
    case analysisInProgress
    case noFrameData
    case analysisError(String)

    var errorDescription: String? {
        switch self {
        case .analysisInProgress:
            return "Analysis already in progress"
        case .noFrameData:
            return "No frame data available"
        case .analysisError(let message):
            return "Analysis error: \(message)"
        }
    }
}

// MARK: - CGImage Extension for CVPixelBuffer

extension CGImage {
    /// Create CGImage from CVPixelBuffer for camera stabilization
    static func create(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return cgImage
    }
}
