//
//  AudioAnalyzer.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach: Audio Analysis for Vocal Stress and Environment
//

import Foundation
import AVFoundation
import Accelerate

/// Analyzes audio for vocal prosody and environmental noise
class AudioAnalyzer {

    // MARK: - Properties

    private var prosodyHistory: [ProsodyFeatures] = []
    private let maxHistorySize = 30  // Keep 1 second of history

    // MARK: - Ambient Noise Analysis

    /// Analyze ambient noise level from audio buffer
    func analyzeAmbientNoise(from buffer: AVAudioPCMBuffer) -> NoiseLevel {
        guard let channelData = buffer.floatChannelData?[0] else {
            return .moderate
        }

        let frameCount = Int(buffer.frameLength)

        // Calculate RMS (Root Mean Square) for volume
        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameCount))

        // Convert to decibels
        // dB = 20 * log10(rms)
        // Add reference level to get absolute dB SPL estimate
        let db = 20 * log10(rms) + 90  // +90 to approximate dB SPL

        // Classify noise level
        switch db {
        case ..<40:
            return .quiet
        case 40..<60:
            return .moderate
        case 60..<80:
            return .loud
        default:
            return .veryLoud
        }
    }

    /// Classify type of ambient noise (experimental)
    func classifyNoiseType(from buffer: AVAudioPCMBuffer) -> NoiseType {
        guard let channelData = buffer.floatChannelData?[0] else {
            return .unclear
        }

        let frameCount = Int(buffer.frameLength)

        // Perform FFT to analyze frequency spectrum
        let spectrum = performFFT(channelData, frameCount: frameCount)

        // Analyze spectral characteristics
        if hasVoiceCharacteristics(spectrum) {
            return .voices
        } else if hasMechanicalCharacteristics(spectrum) {
            return .mechanical
        } else if hasMusicCharacteristics(spectrum) {
            return .music
        } else {
            return .unclear
        }
    }

    // MARK: - Vocal Prosody Analysis

    /// Extract prosody features from audio buffer
    func extractVocalProsody(from buffer: AVAudioPCMBuffer) -> ProsodyFeatures {
        guard let channelData = buffer.floatChannelData?[0] else {
            return ProsodyFeatures(
                fundamentalFrequency: 0,
                energy: 0,
                speakingRate: 0,
                pitchVariation: 0
            )
        }

        let frameCount = Int(buffer.frameLength)
        let sampleRate = buffer.format.sampleRate

        // 1. Extract fundamental frequency (pitch)
        let pitch = extractFundamentalFrequency(channelData, frameCount: frameCount, sampleRate: Float(sampleRate))

        // 2. Calculate energy
        var energy: Float = 0.0
        vDSP_rmsqv(channelData, 1, &energy, vDSP_Length(frameCount))

        // 3. Estimate speaking rate (simplified - uses zero-crossing rate as proxy)
        let speakingRate = estimateSpeakingRate(channelData, frameCount: frameCount, sampleRate: Float(sampleRate))

        // 4. Calculate pitch variation (jitter)
        let pitchVariation = calculatePitchVariation()

        let features = ProsodyFeatures(
            fundamentalFrequency: pitch,
            energy: energy,
            speakingRate: speakingRate,
            pitchVariation: pitchVariation
        )

        // Add to history
        prosodyHistory.append(features)
        if prosodyHistory.count > maxHistorySize {
            prosodyHistory.removeFirst()
        }

        return features
    }

    /// Classify vocal stress from prosody features
    func classifyVocalStress(prosody: ProsodyFeatures) -> VocalStress {
        let pitch = prosody.fundamentalFrequency
        let rate = prosody.speakingRate
        let jitter = prosody.pitchVariation

        // Stressed voice characteristics:
        // - Higher pitch (>180 Hz for women, >140 Hz for men - using conservative threshold)
        // - Faster speaking rate (>5.0 syllables/sec)
        // - Higher pitch variation

        let isHighPitch = pitch > 180
        let isFastRate = rate > 5.0
        let isHighJitter = jitter > 0.05

        if isHighPitch && isFastRate && isHighJitter {
            return .strained
        } else if isHighPitch || isFastRate {
            return .elevated
        } else if pitch < 100 && rate < 2.0 {
            return .flat
        } else {
            return .calm
        }
    }

    /// Create vocal affect from prosody
    func createVocalAffect(prosody: ProsodyFeatures) -> VocalAffect {
        let classification = classifyVocalStress(prosody: prosody)

        // Calculate confidence based on signal quality
        let confidence: Float = prosody.energy > 0.01 ? 0.75 : 0.5

        return VocalAffect(
            prosody: prosody,
            affectClassification: classification,
            confidence: confidence,
            timestamp: Date()
        )
    }

    // MARK: - Private Helper Functions

    private func performFFT(_ data: UnsafeMutablePointer<Float>, frameCount: Int) -> [Float] {
        // Simplified FFT for spectral analysis
        let log2n = vDSP_Length(ceil(log2(Double(frameCount))))
        let bufferSize = Int(1 << log2n)

        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return []
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        // Prepare buffers
        var realPart = [Float](repeating: 0, count: bufferSize/2)
        var imaginaryPart = [Float](repeating: 0, count: bufferSize/2)

        var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imaginaryPart)

        // Convert interleaved data to split complex
        data.withMemoryRebound(to: DSPComplex.self, capacity: bufferSize/2) { complexData in
            vDSP_ctoz(complexData, 2, &splitComplex, 1, vDSP_Length(bufferSize/2))
        }

        // Perform FFT
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

        // Calculate magnitude spectrum
        var magnitudes = [Float](repeating: 0, count: bufferSize/2)
        vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(bufferSize/2))

        return magnitudes
    }

    private func hasVoiceCharacteristics(_ spectrum: [Float]) -> Bool {
        // Voice has strong components in 300-3000 Hz range
        // This is a simplified heuristic

        guard spectrum.count > 100 else { return false }

        let lowRange = spectrum[10..<30]  // Rough approximation
        let midRange = spectrum[30..<100]

        let lowEnergy = lowRange.reduce(0, +)
        let midEnergy = midRange.reduce(0, +)

        // Voice has more energy in mid range
        return midEnergy > lowEnergy * 1.5
    }

    private func hasMechanicalCharacteristics(_ spectrum: [Float]) -> Bool {
        // Mechanical sounds often have strong harmonics
        // Simplified detection

        guard spectrum.count > 50 else { return false }

        let lowRange = spectrum[5..<25]
        let lowEnergy = lowRange.reduce(0, +)

        // Mechanical hum has strong low frequencies
        return lowEnergy > spectrum.reduce(0, +) * 0.3
    }

    private func hasMusicCharacteristics(_ spectrum: [Float]) -> Bool {
        // Music has complex harmonic structure
        // Very simplified detection

        guard spectrum.count > 100 else { return false }

        // Look for multiple peaks (harmonics)
        var peakCount = 0
        for i in 1..<(spectrum.count-1) {
            if spectrum[i] > spectrum[i-1] && spectrum[i] > spectrum[i+1] && spectrum[i] > 0.1 {
                peakCount += 1
            }
        }

        // Music typically has multiple harmonic peaks
        return peakCount >= 5
    }

    private func extractFundamentalFrequency(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Float) -> Float {
        // Use autocorrelation to find pitch
        // Simplified implementation

        let minLag = Int(sampleRate / 400)  // Max pitch 400 Hz
        let maxLag = Int(sampleRate / 80)   // Min pitch 80 Hz

        var maxCorrelation: Float = 0
        var bestLag = minLag

        // Simple autocorrelation
        for lag in minLag..<min(maxLag, frameCount/2) {
            var correlation: Float = 0

            for i in 0..<(frameCount - lag) {
                correlation += data[i] * data[i + lag]
            }

            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestLag = lag
            }
        }

        // Convert lag to frequency
        let pitch = sampleRate / Float(bestLag)

        // Return 0 if pitch is outside reasonable vocal range
        if pitch < 80 || pitch > 400 {
            return 0
        }

        return pitch
    }

    private func estimateSpeakingRate(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Float) -> Float {
        // Estimate speaking rate using zero-crossing rate as a proxy
        var zeroCrossings = 0

        for i in 1..<frameCount {
            if data[i] * data[i-1] < 0 {
                zeroCrossings += 1
            }
        }

        // Convert to approximate syllables per second
        // This is a very rough approximation
        let duration = Float(frameCount) / sampleRate
        let crossingRate = Float(zeroCrossings) / duration

        // Typical speech has ZCR around 100-300 Hz
        // Map to syllables/sec (rough estimate: 2-6 syll/sec)
        let speakingRate = (crossingRate / 300.0) * 6.0

        return max(0, min(10, speakingRate))  // Clamp to reasonable range
    }

    private func calculatePitchVariation() -> Float {
        guard prosodyHistory.count >= 5 else { return 0 }

        // Calculate variation in pitch over recent history
        let recentPitches = prosodyHistory.suffix(5).map { $0.fundamentalFrequency }

        let mean = recentPitches.reduce(0, +) / Float(recentPitches.count)

        var variance: Float = 0
        for pitch in recentPitches {
            let diff = pitch - mean
            variance += diff * diff
        }
        variance /= Float(recentPitches.count)

        let stdDev = sqrt(variance)

        // Normalize by mean to get relative variation
        return mean > 0 ? stdDev / mean : 0
    }

    /// Clear prosody history
    func clearHistory() {
        prosodyHistory.removeAll()
    }
}
