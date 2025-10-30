//
//  LiveCoachSession.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 5 - Live Coach System
//

import Foundation

/// Represents a live coaching session
/// Tracks session state, observations, and coaching suggestions delivered
struct LiveCoachSession: Identifiable, Equatable {
    // MARK: - Identity

    let id: UUID

    // MARK: - Session Info

    let childID: UUID
    let startTime: Date
    var endTime: Date?
    var sessionState: SessionState

    // MARK: - Session Data

    var observations: [SessionObservation]
    var suggestionsDelivered: [DeliveredSuggestion]
    var arousalBandHistory: [ArousalBandReading]
    var parentStateHistory: [ParentStateObservation]
    var coRegulationEvents: [CoRegulationEvent]

    // MARK: - Session Metadata

    var cameraDenied: Bool
    var microphoneDenied: Bool
    var degradedMode: DegradationMode?
    var notes: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        childID: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        sessionState: SessionState = .initializing,
        observations: [SessionObservation] = [],
        suggestionsDelivered: [DeliveredSuggestion] = [],
        arousalBandHistory: [ArousalBandReading] = [],
        parentStateHistory: [ParentStateObservation] = [],
        coRegulationEvents: [CoRegulationEvent] = [],
        cameraDenied: Bool = false,
        microphoneDenied: Bool = false,
        degradedMode: DegradationMode? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.childID = childID
        self.startTime = startTime
        self.endTime = endTime
        self.sessionState = sessionState
        self.observations = observations
        self.suggestionsDelivered = suggestionsDelivered
        self.arousalBandHistory = arousalBandHistory
        self.parentStateHistory = parentStateHistory
        self.coRegulationEvents = coRegulationEvents
        self.cameraDenied = cameraDenied
        self.microphoneDenied = microphoneDenied
        self.degradedMode = degradedMode
        self.notes = notes
    }
}

// MARK: - Session State

/// Lifecycle states for a live coaching session
enum SessionState: String, Codable {
    case initializing = "initializing"      // Requesting permissions
    case active = "active"                  // Session running
    case paused = "paused"                  // Session paused by user
    case ended = "ended"                    // Session completed
    case error = "error"                    // Session error state

    var displayName: String {
        switch self {
        case .initializing:
            return "Starting..."
        case .active:
            return "Active"
        case .paused:
            return "Paused"
        case .ended:
            return "Ended"
        case .error:
            return "Error"
        }
    }

    var icon: String {
        switch self {
        case .initializing:
            return "hourglass"
        case .active:
            return "record.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .ended:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Degradation Mode

/// Mode when operating with limited permissions
enum DegradationMode: String, Codable {
    case cameraOnly = "camera_only"         // Mic denied, camera allowed
    case microphoneOnly = "microphone_only" // Camera denied, mic allowed
    case manualOnly = "manual_only"         // Both denied, manual input only

    var description: String {
        switch self {
        case .cameraOnly:
            return "Camera only (microphone not available)"
        case .microphoneOnly:
            return "Audio only (camera not available)"
        case .manualOnly:
            return "Manual observation mode (camera and microphone not available)"
        }
    }

    var icon: String {
        switch self {
        case .cameraOnly:
            return "video.fill"
        case .microphoneOnly:
            return "mic.fill"
        case .manualOnly:
            return "hand.raised.fill"
        }
    }
}

// MARK: - Session Observation

/// A single observation recorded during a session
struct SessionObservation: Identifiable, Equatable, Codable {
    let id: UUID
    let timestamp: Date
    let observationType: ObservationType
    let description: String
    let arousalBand: ArousalBand?
    let emotionState: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        observationType: ObservationType,
        description: String,
        arousalBand: ArousalBand? = nil,
        emotionState: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.observationType = observationType
        self.description = description
        self.arousalBand = arousalBand
        self.emotionState = emotionState
    }
}

/// Type of observation
enum ObservationType: String, Codable {
    case automatic = "automatic"  // ML-detected
    case manual = "manual"        // User-entered
    case inferred = "inferred"    // Inferred from other signals

    var displayName: String {
        switch self {
        case .automatic:
            return "Auto-detected"
        case .manual:
            return "Manual"
        case .inferred:
            return "Inferred"
        }
    }
}

// MARK: - Delivered Suggestion

/// A coaching suggestion that was delivered during the session
struct DeliveredSuggestion: Identifiable, Equatable, Codable {
    let id: UUID
    let timestamp: Date
    let contentItemID: UUID
    let suggestionText: String
    let arousalBand: ArousalBand
    let userFeedback: SuggestionFeedback?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        contentItemID: UUID,
        suggestionText: String,
        arousalBand: ArousalBand,
        userFeedback: SuggestionFeedback? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.contentItemID = contentItemID
        self.suggestionText = suggestionText
        self.arousalBand = arousalBand
        self.userFeedback = userFeedback
    }
}

/// User feedback on a suggestion
enum SuggestionFeedback: String, Codable {
    case helpful = "helpful"
    case notHelpful = "not_helpful"
    case skipped = "skipped"

    var displayName: String {
        switch self {
        case .helpful:
            return "Helpful"
        case .notHelpful:
            return "Not Helpful"
        case .skipped:
            return "Skipped"
        }
    }
}

// MARK: - Arousal Band Reading

/// A single arousal band reading during a session
struct ArousalBandReading: Identifiable, Equatable, Codable {
    let id: UUID
    let timestamp: Date
    let arousalBand: ArousalBand
    let confidence: Double  // 0.0 to 1.0
    let source: ReadingSource

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        arousalBand: ArousalBand,
        confidence: Double,
        source: ReadingSource
    ) {
        self.id = id
        self.timestamp = timestamp
        self.arousalBand = arousalBand
        self.confidence = confidence
        self.source = source
    }
}

/// Source of an arousal band reading
enum ReadingSource: String, Codable {
    case mlModel = "ml_model"      // ML inference
    case manual = "manual"         // User input
    case fallback = "fallback"     // Fallback heuristic

    var displayName: String {
        switch self {
        case .mlModel:
            return "ML Detection"
        case .manual:
            return "Manual Entry"
        case .fallback:
            return "Estimated"
        }
    }
}

// MARK: - Helper Methods

extension LiveCoachSession {
    /// Duration of the session so far
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    /// Formatted duration string
    var durationString: String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Whether the session is currently running
    var isActive: Bool {
        return sessionState == .active
    }

    /// Current arousal band (most recent reading)
    var currentArousalBand: ArousalBand? {
        return arousalBandHistory.last?.arousalBand
    }

    /// Average confidence of arousal band readings
    var averageConfidence: Double {
        guard !arousalBandHistory.isEmpty else { return 0.0 }
        let sum = arousalBandHistory.reduce(0.0) { $0 + $1.confidence }
        return sum / Double(arousalBandHistory.count)
    }

    /// Whether session is operating in degraded mode
    var isDegraded: Bool {
        return degradedMode != nil
    }

    /// Current parent state (most recent reading)
    var currentParentState: ParentState? {
        return parentStateHistory.last?.state
    }

    /// Number of successful co-regulation events
    var successfulCoRegulationCount: Int {
        return coRegulationEvents.filter { $0.wasSuccessful }.count
    }

    /// Co-regulation success rate
    var coRegulationSuccessRate: Double {
        guard !coRegulationEvents.isEmpty else { return 0.0 }
        return Double(successfulCoRegulationCount) / Double(coRegulationEvents.count)
    }
}

// MARK: - Codable Implementation

extension LiveCoachSession: Codable {
    enum CodingKeys: String, CodingKey {
        case id, childID, startTime, endTime, sessionState
        case observations, suggestionsDelivered, arousalBandHistory
        case parentStateHistory, coRegulationEvents
        case cameraDenied, microphoneDenied, degradedMode, notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        childID = try container.decode(UUID.self, forKey: .childID)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        sessionState = try container.decode(SessionState.self, forKey: .sessionState)
        observations = try container.decode([SessionObservation].self, forKey: .observations)
        suggestionsDelivered = try container.decode([DeliveredSuggestion].self, forKey: .suggestionsDelivered)
        arousalBandHistory = try container.decode([ArousalBandReading].self, forKey: .arousalBandHistory)
        parentStateHistory = try container.decodeIfPresent([ParentStateObservation].self, forKey: .parentStateHistory) ?? []
        coRegulationEvents = try container.decodeIfPresent([CoRegulationEvent].self, forKey: .coRegulationEvents) ?? []
        cameraDenied = try container.decode(Bool.self, forKey: .cameraDenied)
        microphoneDenied = try container.decode(Bool.self, forKey: .microphoneDenied)
        degradedMode = try container.decodeIfPresent(DegradationMode.self, forKey: .degradedMode)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(childID, forKey: .childID)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(sessionState, forKey: .sessionState)
        try container.encode(observations, forKey: .observations)
        try container.encode(suggestionsDelivered, forKey: .suggestionsDelivered)
        try container.encode(arousalBandHistory, forKey: .arousalBandHistory)
        try container.encode(parentStateHistory, forKey: .parentStateHistory)
        try container.encode(coRegulationEvents, forKey: .coRegulationEvents)
        try container.encode(cameraDenied, forKey: .cameraDenied)
        try container.encode(microphoneDenied, forKey: .microphoneDenied)
        try container.encodeIfPresent(degradedMode, forKey: .degradedMode)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}
