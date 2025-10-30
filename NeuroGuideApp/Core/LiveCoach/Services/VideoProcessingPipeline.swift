//
//  VideoProcessingPipeline.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Unit 5 - Live Coach Record-First Flow
//

import Foundation
import AVFoundation
import CoreImage
import Vision
import CoreML

/// Processes recorded videos to generate session analysis
@MainActor
class VideoProcessingPipeline {
    // MARK: - Singleton

    static let shared = VideoProcessingPipeline()

    // MARK: - Dependencies

    private let arousalClassifier: ArousalBandClassifier
    private let emotionClassifier: EmotionStateClassifier
    private let poseService: PoseDetectionService
    private let facialService: FacialExpressionService
    private let contentLibrary: ContentLibraryService
    private let profileService: ChildProfileService

    // MARK: - Initialization

    private init() {
        self.arousalClassifier = ArousalBandClassifier.shared
        self.emotionClassifier = EmotionStateClassifier.shared
        self.poseService = PoseDetectionService.shared
        self.facialService = FacialExpressionService.shared
        self.contentLibrary = ContentLibraryManager.shared
        self.profileService = ChildProfileManager.shared
    }

    // MARK: - Processing

    /// Process recorded session videos
    func processSession(
        childVideoURL: URL,
        parentVideoURL: URL,
        childID: UUID,
        childName: String
    ) async throws -> SessionAnalysisResult {
        let processingStartTime = Date()
        print("🎬 Starting video processing...")
        print("   Child video: \(childVideoURL.path)")
        print("   Parent video: \(parentVideoURL.path)")

        // Get child profile for color
        guard let childProfile = try? await profileService.getProfile() else {
            throw ProcessingError.profileNotFound
        }

        // Verify it's the correct child
        guard childProfile.id == childID else {
            throw ProcessingError.profileNotFound
        }

        // Extract duration
        let duration = try await getVideoDuration(url: childVideoURL)
        print("   Duration: \(String(format: "%.1f", duration))s")

        // Process child video
        print("📊 Processing child video...")
        let childFrames = try await extractFrames(from: childVideoURL, targetFPS: 3.0)
        let arousalTimeline = try await analyzeChildBehavior(frames: childFrames, duration: duration)
        print("   Extracted \(arousalTimeline.count) arousal samples")

        // Process parent video
        print("👤 Processing parent video...")
        let parentFrames = try await extractFrames(from: parentVideoURL, targetFPS: 3.0)
        let emotionTimeline = try await analyzeParentEmotion(frames: parentFrames, duration: duration)
        print("   Extracted \(emotionTimeline.count) emotion samples")

        // Generate behavior spectrum
        let spectrum = BehaviorSpectrum(
            from: arousalTimeline,
            profileColor: childProfile.profileColor
        )
        print("   Spectrum: Shutdown \(String(format: "%.0f", spectrum.shutdownPercentage))%, Green \(String(format: "%.0f", spectrum.greenPercentage))%, Yellow \(String(format: "%.0f", spectrum.yellowPercentage))%, Orange \(String(format: "%.0f", spectrum.orangePercentage))%, Red \(String(format: "%.0f", spectrum.redPercentage))%")

        // Generate parent regulation advice
        let parentAdvice = ParentRegulationAdvice.generate(
            from: emotionTimeline,
            arousalTimeline: arousalTimeline
        )
        print("   Parent dominant emotion: \(parentAdvice?.dominantEmotion.displayName ?? "N/A")")

        // Generate coaching suggestions
        let suggestions = try await generateCoachingSuggestions(
            arousalTimeline: arousalTimeline,
            emotionTimeline: emotionTimeline,
            childProfile: childProfile
        )
        print("   Generated \(suggestions.count) coaching suggestions")

        let processingDuration = Date().timeIntervalSince(processingStartTime)
        print("✅ Processing complete in \(String(format: "%.1f", processingDuration))s")

        return SessionAnalysisResult(
            childID: childID,
            childName: childName,
            recordedAt: Date(),
            duration: duration,
            videoURL: childVideoURL,  // Keep temporarily
            childBehaviorSpectrum: spectrum,
            arousalTimeline: arousalTimeline,
            parentEmotionTimeline: emotionTimeline,
            coachingSuggestions: suggestions,
            parentAdvice: parentAdvice,
            processingDuration: processingDuration
        )
    }

    // MARK: - Frame Extraction

    private func extractFrames(from videoURL: URL, targetFPS: Double) async throws -> [CVPixelBuffer] {
        let asset = AVAsset(url: videoURL)
        let reader = try AVAssetReader(asset: asset)

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw ProcessingError.noVideoTrack
        }

        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        reader.add(output)

        guard reader.startReading() else {
            throw ProcessingError.failedToReadVideo
        }

        var frames: [CVPixelBuffer] = []
        let duration = try await asset.load(.duration).seconds
        let frameInterval = 1.0 / targetFPS
        var nextFrameTime: Double = 0

        while let sampleBuffer = output.copyNextSampleBuffer() {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                continue
            }

            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds

            // Sample at target FPS
            if presentationTime >= nextFrameTime {
                frames.append(imageBuffer)
                nextFrameTime += frameInterval
            }

            // Stop if we've reached the end
            if presentationTime >= duration {
                break
            }
        }

        reader.cancelReading()
        return frames
    }

    private func getVideoDuration(url: URL) async throws -> TimeInterval {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }

    // MARK: - Child Behavior Analysis

    private func analyzeChildBehavior(
        frames: [CVPixelBuffer],
        duration: TimeInterval
    ) async throws -> [ArousalBandSample] {
        var samples: [ArousalBandSample] = []

        let frameDuration = duration / Double(frames.count)

        for (index, frame) in frames.enumerated() {
            let timestamp = Double(index) * frameDuration

            // Analyze frame using ML models
            if let (band, confidence) = try? await analyzeFrameForArousal(frame) {
                samples.append(ArousalBandSample(
                    timestamp: timestamp,
                    band: band,
                    confidence: confidence
                ))
            } else {
                // Fallback to green if analysis fails
                samples.append(ArousalBandSample(
                    timestamp: timestamp,
                    band: .green,
                    confidence: 0.3
                ))
            }
        }

        return samples
    }

    private func analyzeFrameForArousal(_ frame: CVPixelBuffer) async throws -> (ArousalBand, Double)? {
        // Use existing ML services to analyze the frame
        // This leverages the same models used in real-time mode

        // Convert CVPixelBuffer to CGImage
        guard let cgImage = createCGImage(from: frame) else {
            return nil
        }

        // Detect pose
        let poseResult = try? await poseService.detectPose(in: cgImage)

        // Detect facial expression
        let facialResult = try? await facialService.detectExpression(in: cgImage)

        // Classify arousal band
        // Note: In production, you'd pass actual pose landmarks and facial metrics
        // For now, we'll use a simplified approach
        if let pose = poseResult, let facial = facialResult {
            // Calculate movement energy from pose
            let movementEnergy = calculateMovementEnergy(from: pose)

            // Infer arousal from movement and facial cues
            let arousalBand = inferArousalBand(movement: movementEnergy, facial: facial)
            let confidence = 0.7  // Simplified confidence

            return (arousalBand, confidence)
        }

        return nil
    }

    private func calculateMovementEnergy(from poseResult: PoseDetectionResult) -> MovementEnergy {
        // Simplified movement calculation
        // In production, this would analyze pose landmarks to detect movement intensity
        let avgConfidence = poseResult.confidence

        if avgConfidence < 0.4 {
            return .low
        } else if avgConfidence < 0.7 {
            return .moderate
        } else {
            return .high
        }
    }

    private func inferArousalBand(movement: MovementEnergy, facial: FacialExpressionResult) -> ArousalBand {
        // Simplified arousal inference
        // In production, this would use the actual ArousalBandClassifier

        let movementScore = movement == .high ? 2 : (movement == .moderate ? 1 : 0)
        let facialScore = facial.confidence > 0.7 ? 1 : 0

        let totalScore = movementScore + facialScore

        switch totalScore {
        case 0: return .shutdown
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    // MARK: - Parent Emotion Analysis

    private func analyzeParentEmotion(
        frames: [CVPixelBuffer],
        duration: TimeInterval
    ) async throws -> [EmotionSample] {
        var samples: [EmotionSample] = []

        let frameDuration = duration / Double(frames.count)

        for (index, frame) in frames.enumerated() {
            let timestamp = Double(index) * frameDuration

            // Analyze parent facial expression
            if let (emotion, intensity, confidence) = try? await analyzeFrameForParentEmotion(frame) {
                samples.append(EmotionSample(
                    timestamp: timestamp,
                    emotion: emotion,
                    intensity: intensity,
                    confidence: confidence
                ))
            } else {
                // Fallback to calm if analysis fails
                samples.append(EmotionSample(
                    timestamp: timestamp,
                    emotion: .calm,
                    intensity: 0.5,
                    confidence: 0.3
                ))
            }
        }

        return samples
    }

    private func analyzeFrameForParentEmotion(_ frame: CVPixelBuffer) async throws -> (ParentEmotion, Double, Double)? {
        // Convert CVPixelBuffer to CGImage
        guard let cgImage = createCGImage(from: frame) else {
            return nil
        }

        // Use facial expression service to detect parent emotions
        guard let facialResult = try? await facialService.detectExpression(in: cgImage) else {
            return nil
        }

        // Map facial expression to parent emotion
        let emotion = mapFacialToParentEmotion(facialResult)
        let intensity = facialResult.confidence
        let confidence = facialResult.confidence

        return (emotion, intensity, confidence)
    }

    private func mapFacialToParentEmotion(_ facial: FacialExpressionResult) -> ParentEmotion {
        // Map facial expression metrics to parent emotion states
        // This is a simplified mapping - in production, you'd use a dedicated model

        let confidence = facial.confidence

        if confidence < 0.3 {
            return .calm
        } else if confidence < 0.5 {
            return .regulated
        } else if confidence < 0.7 {
            return .stressed
        } else if confidence < 0.85 {
            return .anxious
        } else {
            return .overwhelmed
        }
    }

    // MARK: - Helper Methods

    /// Convert CVPixelBuffer to CGImage
    private func createCGImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }

    // MARK: - Coaching Suggestions

    private func generateCoachingSuggestions(
        arousalTimeline: [ArousalBandSample],
        emotionTimeline: [EmotionSample],
        childProfile: ChildProfile
    ) async throws -> [CoachingSuggestion] {
        var suggestions: [CoachingSuggestion] = []

        // Analyze patterns in arousal timeline
        let dominantBand = BehaviorSpectrum(from: arousalTimeline, profileColor: childProfile.profileColor).dominantBand

        // Get suggestions based on dominant arousal band
        let arousalSuggestions = getSuggestionsForArousalBand(dominantBand, childProfile: childProfile)
        suggestions.append(contentsOf: arousalSuggestions)

        // Get suggestions based on parent emotional state
        let dominantParentEmotion = findDominantParentEmotion(from: emotionTimeline)
        let parentSuggestions = getSuggestionsForParentState(dominantParentEmotion)
        suggestions.append(contentsOf: parentSuggestions)

        // Get co-regulation suggestions if both child and parent were dysregulated
        if dominantBand != .green && dominantParentEmotion != .calm {
            let coRegSuggestions = getCoRegulationSuggestions()
            suggestions.append(contentsOf: coRegSuggestions)
        }

        return Array(suggestions.prefix(5))  // Top 5 suggestions
    }

    private func getSuggestionsForArousalBand(_ band: ArousalBand, childProfile: ChildProfile) -> [CoachingSuggestion] {
        // Generate suggestions based on arousal band
        switch band {
        case .shutdown:
            return [
                CoachingSuggestion(
                    id: UUID(),
                    text: "Your child spent significant time in shutdown. Consider: gentle engagement, reduced demands, and sensory comforts.",
                    category: .environmentalAdjustment,
                    priority: .high,
                    source: "Pattern analysis"
                )
            ]
        case .green:
            return [
                CoachingSuggestion(
                    id: UUID(),
                    text: "Great! Your child was mostly regulated. Keep using the strategies that worked during this session.",
                    category: .positiveReinforcement,
                    priority: .medium,
                    source: "Pattern analysis"
                )
            ]
        case .yellow:
            return [
                CoachingSuggestion(
                    id: UUID(),
                    text: "Your child showed signs of early dysregulation. Early intervention strategies like calming activities can help.",
                    category: .preventativeStrategy,
                    priority: .medium,
                    source: "Pattern analysis"
                )
            ]
        case .orange:
            return [
                CoachingSuggestion(
                    id: UUID(),
                    text: "Your child was escalating. Consider: reducing stimulation, offering movement breaks, and validating feelings.",
                    category: .deEscalation,
                    priority: .high,
                    source: "Pattern analysis"
                )
            ]
        case .red:
            return [
                CoachingSuggestion(
                    id: UUID(),
                    text: "Your child was in crisis. Focus on safety first, then co-regulation through your calm presence.",
                    category: .crisisManagement,
                    priority: .critical,
                    source: "Pattern analysis"
                )
            ]
        }
    }

    private func getSuggestionsForParentState(_ emotion: ParentEmotion) -> [CoachingSuggestion] {
        switch emotion {
        case .calm, .regulated:
            return [
                CoachingSuggestion(
                    id: UUID(),
                    text: "You maintained good regulation during this session. Your calm presence likely helped your child.",
                    category: .parentSelfCare,
                    priority: .low,
                    source: "Parent analysis"
                )
            ]
        case .stressed, .anxious:
            return [
                CoachingSuggestion(
                    id: UUID(),
                    text: "You showed signs of stress. Remember: your regulation supports your child's regulation. Try deep breathing.",
                    category: .parentSelfCare,
                    priority: .high,
                    source: "Parent analysis"
                )
            ]
        case .frustrated, .overwhelmed:
            return [
                CoachingSuggestion(
                    id: UUID(),
                    text: "Parenting is hard. It's okay to take breaks. Consider reaching out to your support network.",
                    category: .parentSelfCare,
                    priority: .critical,
                    source: "Parent analysis"
                )
            ]
        }
    }

    private func getCoRegulationSuggestions() -> [CoachingSuggestion] {
        return [
            CoachingSuggestion(
                id: UUID(),
                text: "Both you and your child showed dysregulation. Focus on co-regulating together through calm, connected presence.",
                category: .coRegulation,
                priority: .high,
                source: "Co-regulation analysis"
            )
        ]
    }

    private func findDominantParentEmotion(from timeline: [EmotionSample]) -> ParentEmotion {
        let emotionCounts = Dictionary(grouping: timeline, by: { $0.emotion })
            .mapValues { $0.count }

        return emotionCounts.max(by: { $0.value < $1.value })?.key ?? .calm
    }
}

// MARK: - Errors

enum ProcessingError: LocalizedError {
    case profileNotFound
    case noVideoTrack
    case failedToReadVideo
    case analysisFailed

    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "Child profile not found."
        case .noVideoTrack:
            return "Video file does not contain a valid video track."
        case .failedToReadVideo:
            return "Failed to read video file."
        case .analysisFailed:
            return "Failed to analyze video content."
        }
    }
}

