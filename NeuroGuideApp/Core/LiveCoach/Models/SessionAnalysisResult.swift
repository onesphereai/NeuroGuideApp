//
//  SessionAnalysisResult.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Unit 5 - Live Coach Record-First Flow
//

import Foundation
import SwiftUI

/// Result of analyzing a recorded session
struct SessionAnalysisResult: Codable, Identifiable {
    let id: UUID
    let childID: UUID
    let childName: String
    let recordedAt: Date
    let duration: TimeInterval
    let videoURL: URL?  // Nil after video is discarded

    // Analysis results
    let childBehaviorSpectrum: BehaviorSpectrum
    let arousalTimeline: [ArousalBandSample]
    let parentEmotionTimeline: [EmotionSample]
    let coachingSuggestions: [CoachingSuggestion]
    let parentAdvice: ParentRegulationAdvice?

    // Metadata
    let processingDuration: TimeInterval
    let degradationMode: DegradationMode?

    init(
        id: UUID = UUID(),
        childID: UUID,
        childName: String,
        recordedAt: Date = Date(),
        duration: TimeInterval,
        videoURL: URL? = nil,
        childBehaviorSpectrum: BehaviorSpectrum,
        arousalTimeline: [ArousalBandSample],
        parentEmotionTimeline: [EmotionSample],
        coachingSuggestions: [CoachingSuggestion],
        parentAdvice: ParentRegulationAdvice?,
        processingDuration: TimeInterval,
        degradationMode: DegradationMode? = nil
    ) {
        self.id = id
        self.childID = childID
        self.childName = childName
        self.recordedAt = recordedAt
        self.duration = duration
        self.videoURL = videoURL
        self.childBehaviorSpectrum = childBehaviorSpectrum
        self.arousalTimeline = arousalTimeline
        self.parentEmotionTimeline = parentEmotionTimeline
        self.coachingSuggestions = coachingSuggestions
        self.parentAdvice = parentAdvice
        self.processingDuration = processingDuration
        self.degradationMode = degradationMode
    }

    /// Discard the video file but keep analysis results
    mutating func discardVideo() {
        if let url = videoURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - ArousalBandSample

/// Sample of arousal band at a specific timestamp
struct ArousalBandSample: Codable, Identifiable {
    let id: UUID
    let timestamp: TimeInterval  // 0-60s into the session
    let band: ArousalBand
    let confidence: Double  // 0.0-1.0

    init(id: UUID = UUID(), timestamp: TimeInterval, band: ArousalBand, confidence: Double) {
        self.id = id
        self.timestamp = timestamp
        self.band = band
        self.confidence = confidence
    }
}

// MARK: - EmotionSample

/// Sample of parent emotion at a specific timestamp
struct EmotionSample: Codable, Identifiable {
    let id: UUID
    let timestamp: TimeInterval
    let emotion: ParentEmotion
    let intensity: Double  // 0.0-1.0
    let confidence: Double  // 0.0-1.0

    init(
        id: UUID = UUID(),
        timestamp: TimeInterval,
        emotion: ParentEmotion,
        intensity: Double,
        confidence: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.emotion = emotion
        self.intensity = intensity
        self.confidence = confidence
    }
}

// MARK: - ParentEmotion

enum ParentEmotion: String, Codable, CaseIterable {
    case calm = "calm"
    case stressed = "stressed"
    case frustrated = "frustrated"
    case anxious = "anxious"
    case overwhelmed = "overwhelmed"
    case regulated = "regulated"

    var displayName: String {
        switch self {
        case .calm: return "Calm"
        case .stressed: return "Stressed"
        case .frustrated: return "Frustrated"
        case .anxious: return "Anxious"
        case .overwhelmed: return "Overwhelmed"
        case .regulated: return "Well-Regulated"
        }
    }

    var color: Color {
        switch self {
        case .calm, .regulated: return .green
        case .stressed: return .orange
        case .frustrated: return .red
        case .anxious: return .yellow
        case .overwhelmed: return .purple
        }
    }

    var icon: String {
        switch self {
        case .calm: return "leaf.fill"
        case .stressed: return "bolt.fill"
        case .frustrated: return "flame.fill"
        case .anxious: return "exclamationmark.triangle.fill"
        case .overwhelmed: return "cloud.fill"
        case .regulated: return "checkmark.circle.fill"
        }
    }
}

// MARK: - BehaviorSpectrum

/// Distribution of child's arousal bands over the session
struct BehaviorSpectrum: Codable {
    let profileColor: String  // Hex color from child profile
    let shutdownPercentage: Double  // 0-100
    let greenPercentage: Double
    let yellowPercentage: Double
    let orangePercentage: Double
    let redPercentage: Double

    init(
        profileColor: String,
        shutdownPercentage: Double,
        greenPercentage: Double,
        yellowPercentage: Double,
        orangePercentage: Double,
        redPercentage: Double
    ) {
        self.profileColor = profileColor
        self.shutdownPercentage = shutdownPercentage
        self.greenPercentage = greenPercentage
        self.yellowPercentage = yellowPercentage
        self.orangePercentage = orangePercentage
        self.redPercentage = redPercentage
    }

    /// Initialize from arousal timeline samples
    init(from samples: [ArousalBandSample], profileColor: String) {
        self.profileColor = profileColor

        guard !samples.isEmpty else {
            self.shutdownPercentage = 0
            self.greenPercentage = 0
            self.yellowPercentage = 0
            self.orangePercentage = 0
            self.redPercentage = 0
            return
        }

        let total = Double(samples.count)
        let shutdownCount = Double(samples.filter { $0.band == .shutdown }.count)
        let greenCount = Double(samples.filter { $0.band == .green }.count)
        let yellowCount = Double(samples.filter { $0.band == .yellow }.count)
        let orangeCount = Double(samples.filter { $0.band == .orange }.count)
        let redCount = Double(samples.filter { $0.band == .red }.count)

        self.shutdownPercentage = (shutdownCount / total) * 100
        self.greenPercentage = (greenCount / total) * 100
        self.yellowPercentage = (yellowCount / total) * 100
        self.orangePercentage = (orangeCount / total) * 100
        self.redPercentage = (redCount / total) * 100
    }

    /// Get dominant arousal band
    var dominantBand: ArousalBand {
        let percentages: [(ArousalBand, Double)] = [
            (.shutdown, shutdownPercentage),
            (.green, greenPercentage),
            (.yellow, yellowPercentage),
            (.orange, orangePercentage),
            (.red, redPercentage)
        ]

        return percentages.max(by: { $0.1 < $1.1 })?.0 ?? .green
    }

    /// Get spectrum colors blended with profile color
    var spectrumColors: [(color: Color, percentage: Double)] {
        let baseColor = Color(hex: profileColor) ?? .blue

        return [
            (color: Color.blue.blend(with: baseColor, ratio: 0.3), percentage: shutdownPercentage),
            (color: Color.green.blend(with: baseColor, ratio: 0.3), percentage: greenPercentage),
            (color: Color.yellow.blend(with: baseColor, ratio: 0.3), percentage: yellowPercentage),
            (color: Color.orange.blend(with: baseColor, ratio: 0.3), percentage: orangePercentage),
            (color: Color.red.blend(with: baseColor, ratio: 0.3), percentage: redPercentage)
        ].filter { $0.percentage > 0 }
    }
}

// MARK: - ParentRegulationAdvice

/// Advice for parent based on their emotional state during session
struct ParentRegulationAdvice: Codable {
    let dominantEmotion: ParentEmotion
    let emotionPercentage: Double  // Percentage of session in this emotion
    let regulationStrategies: [String]
    let specificMoments: [EmotionMoment]  // Specific timestamps where emotion was detected

    struct EmotionMoment: Codable, Identifiable {
        let id: UUID
        let timestamp: TimeInterval
        let emotion: ParentEmotion
        let contextualNote: String  // e.g., "When child moved to red zone"

        init(id: UUID = UUID(), timestamp: TimeInterval, emotion: ParentEmotion, contextualNote: String) {
            self.id = id
            self.timestamp = timestamp
            self.emotion = emotion
            self.contextualNote = contextualNote
        }
    }

    init(
        dominantEmotion: ParentEmotion,
        emotionPercentage: Double,
        regulationStrategies: [String],
        specificMoments: [EmotionMoment]
    ) {
        self.dominantEmotion = dominantEmotion
        self.emotionPercentage = emotionPercentage
        self.regulationStrategies = regulationStrategies
        self.specificMoments = specificMoments
    }

    /// Generate advice from emotion timeline
    static func generate(from emotionTimeline: [EmotionSample], arousalTimeline: [ArousalBandSample]) -> ParentRegulationAdvice? {
        guard !emotionTimeline.isEmpty else { return nil }

        // Find dominant emotion
        let emotionCounts = Dictionary(grouping: emotionTimeline, by: { $0.emotion })
            .mapValues { $0.count }

        guard let (dominantEmotion, count) = emotionCounts.max(by: { $0.value < $1.value }) else {
            return nil
        }

        let emotionPercentage = (Double(count) / Double(emotionTimeline.count)) * 100

        // Get regulation strategies for dominant emotion
        let strategies = getRegulationStrategies(for: dominantEmotion)

        // Find specific moments where parent showed stress
        let stressfulEmotions: [ParentEmotion] = [.stressed, .frustrated, .anxious, .overwhelmed]
        let stressfulMoments = emotionTimeline
            .filter { stressfulEmotions.contains($0.emotion) && $0.intensity > 0.6 }
            .map { sample -> EmotionMoment in
                // Find child's state at this timestamp
                let childState = arousalTimeline
                    .min(by: { abs($0.timestamp - sample.timestamp) < abs($1.timestamp - sample.timestamp) })
                let contextNote = childState.map { "When child was in \($0.band.displayName) zone" } ?? "During session"

                return EmotionMoment(
                    timestamp: sample.timestamp,
                    emotion: sample.emotion,
                    contextualNote: contextNote
                )
            }
            .prefix(3)  // Top 3 moments

        return ParentRegulationAdvice(
            dominantEmotion: dominantEmotion,
            emotionPercentage: emotionPercentage,
            regulationStrategies: strategies,
            specificMoments: Array(stressfulMoments)
        )
    }

    private static func getRegulationStrategies(for emotion: ParentEmotion) -> [String] {
        switch emotion {
        case .calm, .regulated:
            return [
                "Great job staying regulated! Continue using the strategies that worked for you.",
                "Your calm presence likely helped your child co-regulate.",
                "Notice what helped you stay calm to use again in future sessions."
            ]
        case .stressed:
            return [
                "Take slow, deep breaths - inhale for 4 counts, hold for 4, exhale for 6.",
                "Ground yourself: notice 5 things you can see, 4 you can hear, 3 you can touch.",
                "It's okay to take a brief pause - your child's safety is maintained."
            ]
        case .frustrated:
            return [
                "Acknowledge your frustration is valid - parenting is hard.",
                "Take a brief break if possible - even 30 seconds can help.",
                "Try progressive muscle relaxation: tense and release each muscle group."
            ]
        case .anxious:
            return [
                "Name your worry: 'I'm worried about X.' This helps externalize anxiety.",
                "Focus on what you can control right now in this moment.",
                "Use box breathing: breathe in 4, hold 4, out 4, hold 4."
            ]
        case .overwhelmed:
            return [
                "You're not alone - feeling overwhelmed is a normal response.",
                "Break things down: focus on just the next 60 seconds.",
                "It's okay to ask for help or take a break when you need it."
            ]
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#000000"
        }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }

    func blend(with color: Color, ratio: Double) -> Color {
        let ratio = max(0, min(1, ratio))  // Clamp between 0 and 1

        let components1 = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let components2 = UIColor(color).cgColor.components ?? [0, 0, 0, 1]

        let r = components1[0] * (1 - ratio) + components2[0] * ratio
        let g = components1[1] * (1 - ratio) + components2[1] * ratio
        let b = components1[2] * (1 - ratio) + components2[2] * ratio

        return Color(red: r, green: g, blue: b)
    }
}
