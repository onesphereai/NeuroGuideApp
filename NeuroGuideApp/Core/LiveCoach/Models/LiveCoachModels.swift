//
//  LiveCoachModels.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System (Advanced Enhancement)
//

import Foundation
import Vision
import CoreGraphics

// MARK: - Movement Energy

enum MovementEnergy: String, Codable {
    case low
    case moderate
    case high

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
}

// MARK: - Pose Data

struct PoseData {
    let landmarks: [BodyLandmark]
    let confidence: Float
    let timestamp: Date

    func landmark(for joint: VNHumanBodyPoseObservation.JointName) -> BodyLandmark? {
        return landmarks.first { $0.joint == joint }
    }
}

struct BodyLandmark {
    let joint: VNHumanBodyPoseObservation.JointName
    let position: CGPoint
    let confidence: Float
}

// MARK: - Vocal Affect

struct VocalAffect {
    let prosody: ProsodyFeatures
    let affectClassification: VocalStress
    let confidence: Float
    let timestamp: Date
}

struct ProsodyFeatures {
    let fundamentalFrequency: Float  // Hz
    let energy: Float                // RMS amplitude
    let speakingRate: Float          // Estimated syllables/sec
    let pitchVariation: Float        // Jitter (0-1)
}

enum VocalStress: String, Codable {
    case calm
    case elevated
    case strained
    case flat

    var displayName: String {
        switch self {
        case .calm: return "Calm"
        case .elevated: return "Elevated"
        case .strained: return "Strained"
        case .flat: return "Flat"
        }
    }
}

// MARK: - Parent Stress

struct ParentStressAnalysis {
    let facialTension: TensionLevel
    let vocalStress: VocalStress
    let overallStressLevel: StressLevel
    let confidence: Float
    let timestamp: Date
}

enum TensionLevel: String, Codable {
    case relaxed
    case moderate
    case high

    var displayName: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
}

enum StressLevel: String, Codable {
    case calm
    case building
    case high

    var displayName: String {
        switch self {
        case .calm: return "Calm"
        case .building: return "Building Stress"
        case .high: return "High Stress"
        }
    }

    var interventionNeeded: Bool {
        return self == .high
    }

    var suggestion: String {
        switch self {
        case .calm:
            return "You're doing great. Stay present."
        case .building:
            return "Take a breath. You've got this."
        case .high:
            return "Pause. Breathe. Your calm helps them regulate."
        }
    }

    var icon: String {
        switch self {
        case .calm: return "heart.fill"
        case .building: return "heart.circle"
        case .high: return "heart.circle.fill"
        }
    }
}

// MARK: - Environment Context

struct EnvironmentContext {
    let lightingLevel: LightingLevel
    let visualComplexity: VisualComplexity
    let noiseLevel: NoiseLevel
    let noiseType: NoiseType?
    let crowdDensity: CrowdDensity?
    let timestamp: Date

    var isOptimal: Bool {
        return lightingLevel.isOptimal && visualComplexity != .cluttered && noiseLevel.isOptimal
    }

    var suggestions: [String] {
        var suggestions: [String] = []

        if !lightingLevel.isOptimal {
            suggestions.append(lightingLevel.suggestion)
        }

        if let complexitySuggestion = visualComplexity.suggestion {
            suggestions.append(complexitySuggestion)
        }

        if !noiseLevel.isOptimal {
            suggestions.append(noiseLevel.suggestion)
        }

        return suggestions
    }
}

enum LightingLevel: String, Codable {
    case bright
    case normal
    case dim
    case flickering

    var isOptimal: Bool {
        return self == .normal || self == .dim
    }

    var displayName: String {
        switch self {
        case .bright: return "Bright"
        case .normal: return "Normal"
        case .dim: return "Dim"
        case .flickering: return "Flickering"
        }
    }

    var suggestion: String {
        switch self {
        case .bright: return "Try dimming lights or closing blinds"
        case .flickering: return "Fix flickering lights - can be triggering"
        case .normal, .dim: return ""
        }
    }

    var icon: String {
        switch self {
        case .bright: return "sun.max.fill"
        case .normal: return "sun.min.fill"
        case .dim: return "moon.fill"
        case .flickering: return "bolt.fill"
        }
    }
}

enum VisualComplexity: String, Codable {
    case calm
    case moderate
    case cluttered

    var displayName: String {
        switch self {
        case .calm: return "Calm"
        case .moderate: return "Moderate"
        case .cluttered: return "Cluttered"
        }
    }

    var suggestion: String? {
        if self == .cluttered {
            return "Environment looks busy. Try moving to calmer space."
        }
        return nil
    }

    var icon: String {
        switch self {
        case .calm: return "circle.fill"
        case .moderate: return "circle.lefthalf.filled"
        case .cluttered: return "square.grid.3x3.fill"
        }
    }
}

enum NoiseLevel: String, Codable {
    case quiet      // 0-40 dB
    case moderate   // 40-60 dB
    case loud       // 60-80 dB
    case veryLoud   // 80+ dB

    var dBRange: ClosedRange<Float> {
        switch self {
        case .quiet: return 0...40
        case .moderate: return 40...60
        case .loud: return 60...80
        case .veryLoud: return 80...120
        }
    }

    var isOptimal: Bool {
        return self == .quiet || self == .moderate
    }

    var displayName: String {
        switch self {
        case .quiet: return "Quiet"
        case .moderate: return "Moderate"
        case .loud: return "Loud"
        case .veryLoud: return "Very Loud"
        }
    }

    var suggestion: String {
        switch self {
        case .loud: return "Reduce noise (close windows, turn off TV)"
        case .veryLoud: return "Environment is very loud - move to quieter space"
        case .quiet, .moderate: return ""
        }
    }

    var icon: String {
        switch self {
        case .quiet: return "speaker.fill"
        case .moderate: return "speaker.wave.1.fill"
        case .loud: return "speaker.wave.2.fill"
        case .veryLoud: return "speaker.wave.3.fill"
        }
    }
}

enum NoiseType: String, Codable {
    case voices
    case mechanical
    case music
    case traffic
    case unclear

    var displayName: String {
        switch self {
        case .voices: return "Voices"
        case .mechanical: return "Mechanical"
        case .music: return "Music"
        case .traffic: return "Traffic"
        case .unclear: return "Mixed"
        }
    }
}

enum CrowdDensity: String, Codable {
    case solo
    case fewPeople
    case crowded

    var displayName: String {
        switch self {
        case .solo: return "Solo"
        case .fewPeople: return "Few People"
        case .crowded: return "Crowded"
        }
    }
}

// MARK: - Child Behaviors

enum ChildBehavior: String, Codable {
    // Regulation behaviors
    case handFlapping
    case rocking
    case spinning
    case jumping
    case pacing
    case stillness

    // Sensory responses
    case coveringEars
    case coveringEyes
    case retreating
    case seekingPressure

    // Communication
    case pointing
    case reaching
    case approaching

    // Dysregulation
    case escalating
    case meltdown

    case unknown

    var displayName: String {
        switch self {
        case .handFlapping: return "Hand-flapping"
        case .rocking: return "Rocking"
        case .spinning: return "Spinning"
        case .jumping: return "Jumping"
        case .pacing: return "Pacing"
        case .stillness: return "Stillness"
        case .coveringEars: return "Covering ears"
        case .coveringEyes: return "Covering eyes"
        case .retreating: return "Retreating"
        case .seekingPressure: return "Seeking pressure"
        case .pointing: return "Pointing"
        case .reaching: return "Reaching"
        case .approaching: return "Approaching"
        case .escalating: return "Escalating"
        case .meltdown: return "Meltdown"
        case .unknown: return "Observing"
        }
    }

    var icon: String {
        switch self {
        case .handFlapping: return "hand.wave.fill"
        case .rocking: return "figure.mind.and.body"
        case .spinning: return "arrow.triangle.2.circlepath"
        case .jumping: return "figure.jumprope"
        case .pacing: return "figure.walk"
        case .stillness: return "figure.stand"
        case .coveringEars: return "ear.fill"
        case .coveringEyes: return "eye.slash.fill"
        case .retreating: return "arrow.backward"
        case .seekingPressure: return "hand.raised.fill"
        case .pointing: return "hand.point.right.fill"
        case .reaching: return "hand.raised.fingers.spread.fill"
        case .approaching: return "figure.walk.arrival"
        case .escalating: return "arrow.up.circle.fill"
        case .meltdown: return "exclamationmark.triangle.fill"
        case .unknown: return "eye.fill"
        }
    }

    func interpretation(arousal: ArousalBand) -> String {
        switch self {
        case .handFlapping:
            if arousal == .green || arousal == .shutdown {
                return "Hand-flapping observed. May indicate joy, excitement, or self-regulation."
            } else {
                return "Hand-flapping with high arousal. Child may be working to regulate."
            }

        case .coveringEars:
            return "Covering ears observed. Child is experiencing auditory overwhelm."

        case .rocking:
            return "Rocking observed. This is self-soothing and helps regulation."

        case .jumping:
            if arousal == .green {
                return "Jumping observed. Likely seeking proprioceptive input or expressing joy."
            } else {
                return "Jumping observed. May be seeking movement to regulate."
            }

        case .retreating:
            return "Child is retreating. They need space and reduced demands."

        case .stillness:
            if arousal == .green {
                return "Child is calm and still."
            } else {
                return "Child is very still. May be in shutdown or freeze response."
            }

        case .meltdown:
            return "Child appears to be in meltdown. This is nervous system overwhelm, not a behavior problem."

        default:
            return "Observing child's behavior."
        }
    }

    func suggestions(arousal: ArousalBand) -> [String] {
        switch self {
        case .handFlapping:
            return [
                "Allow stimming - it's helping them regulate",
                "Ensure safe space for movement",
                "No intervention needed unless unsafe"
            ]

        case .coveringEars:
            return [
                "Reduce noise immediately",
                "Offer noise-canceling headphones if available",
                "Move to quieter space",
                "Lower your voice - minimize talking"
            ]

        case .rocking:
            return [
                "Allow rocking - it's self-soothing",
                "Ensure safe space (soft surfaces if needed)",
                "Don't interrupt this regulation strategy"
            ]

        case .jumping:
            return [
                "Allow safe jumping (trampoline, cushions)",
                "Ensure environment is safe",
                "Offer alternative proprioceptive input if needed"
            ]

        case .retreating:
            return [
                "Respect their need for space",
                "Reduce demands immediately",
                "Create quiet, safe area",
                "Don't force interaction"
            ]

        case .meltdown:
            return [
                "SAFETY FIRST - remove hazards",
                "Give space unless immediate danger",
                "Your calm is critical - breathe",
                "Don't reason, restrain, or demand eye contact",
                "This will pass"
            ]

        default:
            return ["Observe and wait before intervening"]
        }
    }
}

// MARK: - Coaching Suggestion

struct CoachingSuggestion: Identifiable, Equatable, Codable {
    let id: UUID
    let text: String
    let category: SuggestionCategory
    let priority: Priority
    let sourceAttribution: String?

    init(id: UUID = UUID(), text: String, category: SuggestionCategory, priority: Priority, sourceAttribution: String? = nil, source: String? = nil) {
        self.id = id
        self.text = text
        self.category = category
        self.priority = priority
        self.sourceAttribution = sourceAttribution
    }

    enum SuggestionCategory: String, Codable {
        case environmental
        case environmentalAdjustment
        case sensory
        case regulation
        case parentSupport
        case parentSelfCare
        case general
        case prevention
        case preventativeStrategy
        case deescalation
        case deEscalation
        case recovery
        case communication
        case positiveReinforcement
        case crisisManagement
        case coRegulation

        var displayName: String {
            switch self {
            case .environmental, .environmentalAdjustment: return "Environment"
            case .sensory: return "Sensory"
            case .regulation: return "Regulation"
            case .parentSupport, .parentSelfCare: return "Your Self-Care"
            case .general: return "General"
            case .prevention, .preventativeStrategy: return "Prevention"
            case .deescalation, .deEscalation: return "De-escalation"
            case .recovery: return "Recovery"
            case .communication: return "Communication"
            case .positiveReinforcement: return "Positive Reinforcement"
            case .crisisManagement: return "Crisis Management"
            case .coRegulation: return "Co-Regulation"
            }
        }

        var icon: String {
            switch self {
            case .environmental, .environmentalAdjustment: return "globe"
            case .sensory: return "hand.raised.fill"
            case .regulation: return "heart.fill"
            case .parentSupport, .parentSelfCare: return "person.fill"
            case .general: return "info.circle.fill"
            case .prevention, .preventativeStrategy: return "shield.fill"
            case .deescalation, .deEscalation: return "arrow.down.circle.fill"
            case .recovery: return "leaf.fill"
            case .communication: return "bubble.left.and.bubble.right.fill"
            case .positiveReinforcement: return "hand.thumbsup.fill"
            case .crisisManagement: return "exclamationmark.triangle.fill"
            case .coRegulation: return "person.2.fill"
            }
        }
    }

    enum Priority: Int, Codable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
    }

    static func == (lhs: CoachingSuggestion, rhs: CoachingSuggestion) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Live Coach Analysis

struct LiveCoachAnalysis {
    let arousalBand: ArousalBand
    let movementEnergy: MovementEnergy
    let detectedBehaviors: [ChildBehavior]
    let environmentContext: EnvironmentContext
    let parentStress: ParentStressAnalysis?
    let suggestions: [CoachingSuggestion]
    let timestamp: Date

    var primaryBehavior: ChildBehavior {
        return detectedBehaviors.first ?? .unknown
    }
}

// MARK: - Session Summary

struct LiveCoachSessionSummary: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval

    // Arousal distribution
    let arousalDistribution: [ArousalBand: TimeInterval]

    // Behaviors observed
    let behaviorsObserved: [ChildBehavior]

    // Suggestions shown
    let suggestionsShown: [String]  // Text only for privacy

    // Helpfulness rating (optional)
    var helpfulnessRating: Int?  // 1-5

    // Parent stress summary
    let averageParentStress: StressLevel?

    // Environment summary
    let environmentSummary: String?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var formattedDuration: String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}
