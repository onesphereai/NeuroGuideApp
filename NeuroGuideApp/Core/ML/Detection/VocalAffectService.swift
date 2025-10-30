//
//  VocalAffectService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 2 - ML Foundation (Vocal Affect Analysis)
//

import Foundation
import AVFoundation
import Combine

/// Service for analyzing vocal affect (prosody, volume, rate)
/// Currently uses AVFoundation for basic audio features
/// TODO: Replace with trained model for neurodivergent vocal patterns
@MainActor
class VocalAffectService: ObservableObject {
    // MARK: - Singleton

    static let shared = VocalAffectService()

    // MARK: - Published Properties

    @Published private(set) var isProcessing = false
    @Published private(set) var lastAnalysisTime: Date?

    // MARK: - Private Properties

    private let performanceMonitor: ModelPerformanceMonitorProtocol
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?

    // MARK: - Initialization

    init(performanceMonitor: ModelPerformanceMonitorProtocol = PerformanceMonitor.shared) {
        self.performanceMonitor = performanceMonitor
    }

    // MARK: - Vocal Affect Analysis

    /// Analyze vocal affect from audio buffer
    /// - Parameter audioBuffer: Input audio buffer
    /// - Returns: Vocal affect analysis result
    func analyzeAudio(buffer: AVAudioPCMBuffer) async throws -> VocalAffectResult {
        isProcessing = true
        defer { isProcessing = false }

        let startTime = Date()

        // Extract audio features
        let features = extractAudioFeatures(from: buffer)

        // Analyze affect
        let affect = analyzeAffect(features: features)

        // Record performance
        let latency = Date().timeIntervalSince(startTime)
        recordPerformance(latency: latency)

        lastAnalysisTime = Date()

        return VocalAffectResult(
            affect: affect,
            features: features,
            timestamp: Date(),
            latency: latency
        )
    }

    /// Extract vocal features for arousal analysis
    /// - Parameter buffer: Audio buffer
    /// - Returns: Extracted vocal features
    func extractVocalFeatures(from buffer: AVAudioPCMBuffer) async throws -> VocalFeatures {
        let result = try await analyzeAudio(buffer: buffer)
        return result.features
    }

    // MARK: - Audio Feature Extraction

    private func extractAudioFeatures(from buffer: AVAudioPCMBuffer) -> VocalFeatures {
        guard let channelData = buffer.floatChannelData else {
            return VocalFeatures.default
        }

        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))

        // Calculate basic audio features
        let volume = calculateVolume(samples: samples)
        let pitch = estimatePitch(samples: samples, sampleRate: buffer.format.sampleRate)
        let energy = calculateEnergy(samples: samples)
        let zeroCrossingRate = calculateZeroCrossingRate(samples: samples)

        return VocalFeatures(
            volume: volume,
            pitch: pitch,
            energy: energy,
            speechRate: estimateSpeechRate(samples: samples),
            voiceQuality: estimateVoiceQuality(zeroCrossingRate: zeroCrossingRate)
        )
    }

    private func calculateVolume(samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0.0 }

        // RMS volume
        let sum = samples.reduce(0.0) { $0 + ($1 * $1) }
        let rms = sqrt(sum / Float(samples.count))

        // Normalize to 0-1 range (assuming typical range -1 to 1)
        return min(Double(rms) * 2, 1.0)
    }

    private func estimatePitch(samples: [Float], sampleRate: Double) -> Double {
        // Simplified pitch estimation
        // In production, use autocorrelation or YIN algorithm
        // For now, return mock value based on energy
        let energy = calculateEnergy(samples: samples)
        return 100.0 + (energy * 100.0)  // Mock pitch in Hz
    }

    private func calculateEnergy(samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0.0 }

        let sum = samples.reduce(0.0) { $0 + abs($1) }
        let energy = sum / Float(samples.count)

        return min(Double(energy) * 2, 1.0)
    }

    private func calculateZeroCrossingRate(samples: [Float]) -> Double {
        guard samples.count > 1 else { return 0.0 }

        var crossings = 0
        for i in 1..<samples.count {
            if (samples[i] >= 0 && samples[i-1] < 0) || (samples[i] < 0 && samples[i-1] >= 0) {
                crossings += 1
            }
        }

        return Double(crossings) / Double(samples.count)
    }

    private func estimateSpeechRate(samples: [Float]) -> Double {
        // Simplified speech rate estimation
        // In production, use phoneme detection or syllable counting
        // For now, correlate with volume variations
        let volume = calculateVolume(samples: samples)
        return volume  // Mock: higher volume = faster speech (not accurate)
    }

    private func estimateVoiceQuality(zeroCrossingRate: Double) -> Double {
        // Voice quality: smooth vs harsh
        // High zero-crossing rate suggests harsher/noisier voice
        return 1.0 - zeroCrossingRate  // Inverted: lower ZCR = smoother voice
    }

    // MARK: - Affect Analysis

    private func analyzeAffect(features: VocalFeatures) -> VocalAffectAnalysis {
        // Map audio features to affect dimensions
        // This is a simplified heuristic
        // In production, use trained model on neurodivergent vocal patterns

        let arousalLevel = estimateArousalLevel(features: features)
        let valence = estimateValence(features: features)
        let intensity = features.energy

        return VocalAffectAnalysis(
            arousalLevel: arousalLevel,
            valence: valence,
            intensity: intensity,
            confidence: 0.7  // Mock confidence for stub
        )
    }

    private func estimateArousalLevel(features: VocalFeatures) -> Double {
        // High arousal indicators:
        // - High volume
        // - High pitch
        // - High energy
        // - Fast speech rate

        let weights: (volume: Double, pitch: Double, energy: Double, rate: Double) = (0.3, 0.2, 0.3, 0.2)

        // Normalize pitch to 0-1 (assuming 50-250 Hz range)
        let normalizedPitch = (features.pitch - 50.0) / 200.0

        let arousal = (features.volume * weights.volume) +
                      (normalizedPitch * weights.pitch) +
                      (features.energy * weights.energy) +
                      (features.speechRate * weights.rate)

        return min(max(arousal, 0.0), 1.0)
    }

    private func estimateValence(features: VocalFeatures) -> Double {
        // Positive valence indicators:
        // - Moderate to high pitch variation
        // - Smooth voice quality
        // - Moderate volume

        // For stub, return neutral valence
        return 0.5
    }

    // MARK: - Performance Tracking

    private func recordPerformance(latency: TimeInterval) {
        let metrics = ModelPerformanceMetrics(
            modelType: .vocalAffect,
            inferenceLatency: latency,
            memoryUsage: 0,
            batteryImpact: 0.03,  // Minimal battery impact
            timestamp: Date()
        )

        performanceMonitor.recordInference(metrics)
    }
}

// MARK: - Supporting Types

/// Result of vocal affect analysis
struct VocalAffectResult {
    let affect: VocalAffectAnalysis
    let features: VocalFeatures
    let timestamp: Date
    let latency: TimeInterval

    var meetsLatencyTarget: Bool {
        return latency < MLModelType.vocalAffect.latencyTarget
    }
}

/// Analysis of vocal affect
struct VocalAffectAnalysis {
    let arousalLevel: Double  // 0-1 (low to high)
    let valence: Double        // 0-1 (negative to positive)
    let intensity: Double      // 0-1 (quiet to loud)
    let confidence: Double     // 0-1

    /// Simplified affect classification
    var classification: VocalAffectClass {
        if arousalLevel < 0.3 {
            return .flat
        } else if arousalLevel < 0.6 {
            return .calm
        } else if arousalLevel < 0.8 {
            return .elevated
        } else {
            return .distressed
        }
    }
}

/// Vocal affect classification
enum VocalAffectClass: String {
    case flat = "Flat"           // Under-aroused, withdrawn
    case calm = "Calm"           // Regulated
    case elevated = "Elevated"   // Somewhat elevated
    case distressed = "Distressed"  // High arousal, distressed
}

/// Extracted vocal features
struct VocalFeatures {
    let volume: Double         // 0-1, RMS volume
    let pitch: Double          // Hz, fundamental frequency
    let energy: Double         // 0-1, signal energy
    let speechRate: Double     // 0-1 estimate
    let voiceQuality: Double   // 0-1, smooth to harsh

    static var `default`: VocalFeatures {
        return VocalFeatures(
            volume: 0.5,
            pitch: 150.0,
            energy: 0.5,
            speechRate: 0.5,
            voiceQuality: 0.5
        )
    }

    /// Estimate arousal contribution from vocal features
    /// Returns value 0-1 where higher = higher arousal
    var arousalContribution: Double {
        // High arousal indicators:
        // - High volume
        // - High energy
        // - Fast speech rate
        // - Harsh voice quality (low voice quality score)

        let weights: (volume: Double, energy: Double, rate: Double, quality: Double) = (0.3, 0.3, 0.2, 0.2)

        let arousal = (volume * weights.volume) +
                      (energy * weights.energy) +
                      (speechRate * weights.rate) +
                      ((1.0 - voiceQuality) * weights.quality)  // Inverted

        return min(max(arousal, 0.0), 1.0)
    }
}

/// Vocal affect errors
enum VocalAffectError: LocalizedError {
    case noAudioData
    case invalidBuffer
    case processingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noAudioData:
            return "No audio data available"
        case .invalidBuffer:
            return "Invalid audio buffer format"
        case .processingFailed(let error):
            return "Vocal affect analysis failed: \(error.localizedDescription)"
        }
    }
}
