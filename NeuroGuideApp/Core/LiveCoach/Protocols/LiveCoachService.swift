//
//  LiveCoachService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 5 - Live Coach System
//

import Foundation
import Combine

/// Protocol for live coaching session management
@MainActor
protocol LiveCoachService: AnyObject {
    // MARK: - Session Management

    /// Current active session (if any)
    var currentSession: LiveCoachSession? { get }

    /// Whether a session is currently active
    var isSessionActive: Bool { get }

    /// Publisher for session state changes
    var sessionPublisher: AnyPublisher<LiveCoachSession?, Never> { get }

    /// Start a new live coaching session
    /// - Parameter childID: The child profile ID
    /// - Returns: The newly created session
    /// - Throws: SessionError if session cannot be started
    func startSession(childID: UUID) async throws -> LiveCoachSession

    /// End the current session
    /// - Parameter notes: Optional session notes
    /// - Throws: SessionError if no active session
    func endSession(notes: String?) async throws

    /// Pause the current session
    /// - Throws: SessionError if no active session
    func pauseSession() async throws

    /// Resume a paused session
    /// - Throws: SessionError if session is not paused
    func resumeSession() async throws

    // MARK: - Observations

    /// Add a manual observation to the current session
    /// - Parameters:
    ///   - description: Description of the observation
    ///   - arousalBand: Optional arousal band
    ///   - emotionState: Optional emotion state
    /// - Throws: SessionError if no active session
    func addObservation(
        description: String,
        arousalBand: ArousalBand?,
        emotionState: String?
    ) async throws

    /// Record an arousal band reading
    /// - Parameters:
    ///   - arousalBand: The detected arousal band
    ///   - confidence: Confidence score (0.0 to 1.0)
    ///   - source: Source of the reading
    /// - Throws: SessionError if no active session
    func recordArousalBandReading(
        arousalBand: ArousalBand,
        confidence: Double,
        source: ReadingSource
    ) async throws

    /// Record a parent state observation
    /// - Parameters:
    ///   - state: The detected parent state
    ///   - confidence: Confidence score (0.0 to 1.0)
    ///   - features: Extracted features
    /// - Throws: SessionError if no active session
    func recordParentStateObservation(
        state: ParentState,
        confidence: Double,
        features: ParentStateFeatures
    ) async throws

    /// Record a co-regulation event
    /// - Parameter event: The co-regulation event
    /// - Throws: SessionError if no active session
    func recordCoRegulationEvent(_ event: CoRegulationEvent) async throws

    // MARK: - Suggestions

    /// Record that a suggestion was delivered
    /// - Parameters:
    ///   - contentItemID: The content item ID
    ///   - suggestionText: The suggestion text shown
    ///   - arousalBand: Arousal band at time of delivery
    /// - Throws: SessionError if no active session
    func recordDeliveredSuggestion(
        contentItemID: UUID,
        suggestionText: String,
        arousalBand: ArousalBand
    ) async throws

    /// Record user feedback on a suggestion
    /// - Parameters:
    ///   - suggestionID: The delivered suggestion ID
    ///   - feedback: User feedback
    /// - Throws: SessionError if no active session or suggestion not found
    func recordSuggestionFeedback(
        suggestionID: UUID,
        feedback: SuggestionFeedback
    ) async throws

    // MARK: - Session History

    /// Get all sessions for a child
    /// - Parameter childID: The child profile ID
    /// - Returns: Array of sessions
    func getSessionHistory(childID: UUID) async throws -> [LiveCoachSession]

    /// Get a specific session by ID
    /// - Parameter sessionID: The session ID
    /// - Returns: The session, if found
    func getSession(id: UUID) async throws -> LiveCoachSession?
}

/// Protocol for permission management
@MainActor
protocol PermissionsService: AnyObject {
    /// Check camera permission status
    var cameraStatus: PermissionStatus { get }

    /// Check microphone permission status
    var microphoneStatus: PermissionStatus { get }

    /// Publisher for permission changes
    var permissionsPublisher: AnyPublisher<PermissionUpdate, Never> { get }

    /// Request camera permission
    /// - Returns: Whether permission was granted
    func requestCameraPermission() async -> Bool

    /// Request microphone permission
    /// - Returns: Whether permission was granted
    func requestMicrophonePermission() async -> Bool

    /// Request both camera and microphone permissions
    /// - Returns: Tuple of (camera granted, microphone granted)
    func requestAllPermissions() async -> (camera: Bool, microphone: Bool)

    /// Determine degradation mode based on current permissions
    /// - Returns: Degradation mode, or nil if both permissions granted
    func getDegradationMode() -> DegradationMode?
}

// MARK: - Supporting Types

/// Permission status
enum PermissionStatus: String {
    case notDetermined = "not_determined"
    case granted = "granted"
    case denied = "denied"
    case restricted = "restricted"

    var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Asked"
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        }
    }
}

/// Permission update event
struct PermissionUpdate {
    let permissionType: PermissionType
    let status: PermissionStatus

    enum PermissionType {
        case camera
        case microphone
    }
}

/// Session-related errors
enum SessionError: LocalizedError {
    case noActiveSession
    case sessionAlreadyActive
    case sessionNotPaused
    case invalidState
    case suggestionNotFound
    case permissionDenied(String)

    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active session"
        case .sessionAlreadyActive:
            return "A session is already active"
        case .sessionNotPaused:
            return "Session is not paused"
        case .invalidState:
            return "Invalid session state"
        case .suggestionNotFound:
            return "Suggestion not found"
        case .permissionDenied(let permission):
            return "\(permission) permission denied"
        }
    }
}
