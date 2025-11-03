//
//  LiveCoachSessionManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 5 - Live Coach System
//

import Foundation
import Combine

/// Main implementation of LiveCoachService
/// Manages live coaching session lifecycle and state
@MainActor
class LiveCoachSessionManager: LiveCoachService, ObservableObject {
    // MARK: - Singleton

    static let shared = LiveCoachSessionManager()

    // MARK: - Published Properties

    @Published private(set) var currentSession: LiveCoachSession?

    // MARK: - Computed Properties

    var isSessionActive: Bool {
        return currentSession?.isActive ?? false
    }

    var sessionPublisher: AnyPublisher<LiveCoachSession?, Never> {
        $currentSession.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private var sessionHistory: [LiveCoachSession] = []
    private let permissionsService: PermissionsService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(permissionsService: PermissionsService = PermissionsManager.shared) {
        self.permissionsService = permissionsService
        setupPermissionObserver()
    }

    // MARK: - Session Management

    func startSession(childID: UUID) async throws -> LiveCoachSession {
        // Check if session already active
        if currentSession != nil {
            throw SessionError.sessionAlreadyActive
        }

        // Request permissions
        let (cameraGranted, micGranted) = await permissionsService.requestAllPermissions()

        // Determine degradation mode
        let degradationMode = permissionsService.getDegradationMode()

        // Create new session
        var session = LiveCoachSession(
            childID: childID,
            sessionState: .initializing,
            cameraDenied: !cameraGranted,
            microphoneDenied: !micGranted,
            degradedMode: degradationMode
        )

        // Transition to active state
        session.sessionState = .active

        currentSession = session

        print("✅ Started session \(session.id) for child \(childID)")
        if let mode = degradationMode {
            print("⚠️ Session in degraded mode: \(mode.description)")
        }

        return session
    }

    func endSession(notes: String?) async throws {
        guard var session = currentSession else {
            throw SessionError.noActiveSession
        }

        // Update session
        session.endTime = Date()
        session.sessionState = .ended
        session.notes = notes

        // Archive session
        sessionHistory.append(session)

        // Convert to SessionAnalysisResult and save to SessionHistoryManager
        let analysisResult = convertToAnalysisResult(session: session)
        do {
            try await SessionHistoryManager.shared.saveSession(analysisResult)
            print("💾 Session saved to history")
        } catch {
            print("❌ Failed to save session to history: \(error)")
        }

        // Clear current session
        currentSession = nil

        print("✅ Ended session \(session.id) - Duration: \(session.durationString)")
    }

    func pauseSession() async throws {
        guard var session = currentSession else {
            throw SessionError.noActiveSession
        }

        guard session.sessionState == .active else {
            throw SessionError.invalidState
        }

        session.sessionState = .paused
        currentSession = session

        print("⏸️ Paused session \(session.id)")
    }

    func resumeSession() async throws {
        guard var session = currentSession else {
            throw SessionError.noActiveSession
        }

        guard session.sessionState == .paused else {
            throw SessionError.sessionNotPaused
        }

        session.sessionState = .active
        currentSession = session

        print("▶️ Resumed session \(session.id)")
    }

    // MARK: - Observations

    func addObservation(
        description: String,
        arousalBand: ArousalBand?,
        emotionState: String?
    ) async throws {
        guard var session = currentSession else {
            throw SessionError.noActiveSession
        }

        let observation = SessionObservation(
            observationType: .manual,
            description: description,
            arousalBand: arousalBand,
            emotionState: emotionState
        )

        session.observations.append(observation)
        currentSession = session

        print("📝 Added observation: \(description)")
    }

    func recordArousalBandReading(
        arousalBand: ArousalBand,
        confidence: Double,
        source: ReadingSource
    ) async throws {
        guard var session = currentSession else {
            throw SessionError.noActiveSession
        }

        let reading = ArousalBandReading(
            arousalBand: arousalBand,
            confidence: confidence,
            source: source
        )

        session.arousalBandHistory.append(reading)
        currentSession = session

        print("📊 Recorded arousal band: \(arousalBand.displayName) (confidence: \(String(format: "%.2f", confidence)))")
    }

    func recordParentStateObservation(
        state: ParentState,
        confidence: Double,
        features: ParentStateFeatures
    ) async throws {
        guard var session = currentSession else {
            throw SessionError.noActiveSession
        }

        let observation = ParentStateObservation(
            sessionID: session.id,
            state: state,
            confidence: confidence,
            source: .mlModel,
            facialTension: features.facialTension,
            vocalStress: features.vocalStress,
            bodyLanguage: features.bodyLanguage,
            engagementLevel: features.engagementLevel
        )

        session.parentStateHistory.append(observation)
        currentSession = session

        print("👤 Recorded parent state: \(state.displayName) (confidence: \(String(format: "%.2f", confidence)))")
    }

    func recordCoRegulationEvent(_ event: CoRegulationEvent) async throws {
        guard var session = currentSession else {
            throw SessionError.noActiveSession
        }

        session.coRegulationEvents.append(event)
        currentSession = session

        print("🤝 Recorded co-regulation event: \(event.eventDescription)")
    }

    // MARK: - Suggestions

    func recordDeliveredSuggestion(
        contentItemID: UUID,
        suggestionText: String,
        arousalBand: ArousalBand
    ) async throws {
        guard var session = currentSession else {
            throw SessionError.noActiveSession
        }

        let suggestion = DeliveredSuggestion(
            contentItemID: contentItemID,
            suggestionText: suggestionText,
            arousalBand: arousalBand
        )

        session.suggestionsDelivered.append(suggestion)
        currentSession = session

        print("💡 Delivered suggestion: \(suggestionText)")
    }

    func recordSuggestionFeedback(
        suggestionID: UUID,
        feedback: SuggestionFeedback
    ) async throws {
        guard var session = currentSession else {
            throw SessionError.noActiveSession
        }

        // Find the suggestion
        guard let index = session.suggestionsDelivered.firstIndex(where: { $0.id == suggestionID }) else {
            throw SessionError.suggestionNotFound
        }

        // Update feedback
        var suggestion = session.suggestionsDelivered[index]
        session.suggestionsDelivered[index] = DeliveredSuggestion(
            id: suggestion.id,
            timestamp: suggestion.timestamp,
            contentItemID: suggestion.contentItemID,
            suggestionText: suggestion.suggestionText,
            arousalBand: suggestion.arousalBand,
            userFeedback: feedback
        )

        currentSession = session

        print("👍 Recorded feedback for suggestion: \(feedback.displayName)")
    }

    // MARK: - Session History

    func getSessionHistory(childID: UUID) async throws -> [LiveCoachSession] {
        return sessionHistory.filter { $0.childID == childID }
    }

    func getSession(id: UUID) async throws -> LiveCoachSession? {
        // Check current session
        if currentSession?.id == id {
            return currentSession
        }

        // Check history
        return sessionHistory.first(where: { $0.id == id })
    }

    // MARK: - Private Methods

    private func setupPermissionObserver() {
        permissionsService.permissionsPublisher
            .sink { [weak self] update in
                Task { @MainActor in
                    await self?.handlePermissionUpdate(update)
                }
            }
            .store(in: &cancellables)
    }

    private func handlePermissionUpdate(_ update: PermissionUpdate) async {
        guard var session = currentSession else { return }

        // Update session based on permission change
        switch update.permissionType {
        case .camera:
            session.cameraDenied = (update.status != .granted)
        case .microphone:
            session.microphoneDenied = (update.status != .granted)
        }

        // Update degradation mode
        session.degradedMode = permissionsService.getDegradationMode()

        currentSession = session

        print("🔄 Permission updated: \(update.permissionType) -> \(update.status.displayName)")
    }

    /// Convert LiveCoachSession to SessionAnalysisResult for history storage
    private func convertToAnalysisResult(session: LiveCoachSession) -> SessionAnalysisResult {
        // Use default values for child name and color (async profile fetching not possible in this context)
        let childName = "Child"
        let profileColor = "#4A90E2"

        // Convert arousal history to timeline
        let arousalTimeline = session.arousalBandHistory.enumerated().map { index, reading in
            ArousalBandSample(
                timestamp: Double(index) * 3.0, // 3-second intervals
                band: reading.arousalBand,
                confidence: reading.confidence
            )
        }

        // Create behavior spectrum from arousal timeline
        let spectrum = BehaviorSpectrum(from: arousalTimeline, profileColor: profileColor)

        // Convert parent state history to emotion timeline
        let emotionTimeline = session.parentStateHistory.map { observation in
            EmotionSample(
                timestamp: observation.timestamp.timeIntervalSince(session.startTime),
                emotion: mapParentStateToEmotion(observation.state),
                intensity: observation.confidence,
                confidence: observation.confidence
            )
        }

        // Convert suggestions to CoachingSuggestion format
        let coachingSuggestions = session.suggestionsDelivered.map { suggestion in
            CoachingSuggestion(
                text: suggestion.suggestionText,
                category: .regulation,
                priority: .medium
            )
        }

        // Generate parent advice from emotion timeline
        let parentAdvice = ParentRegulationAdvice.generate(from: emotionTimeline, arousalTimeline: arousalTimeline)

        return SessionAnalysisResult(
            childID: session.childID,
            childName: childName,
            recordedAt: session.startTime,
            duration: session.duration,
            videoURL: nil, // Live sessions don't have saved video
            childBehaviorSpectrum: spectrum,
            arousalTimeline: arousalTimeline,
            parentEmotionTimeline: emotionTimeline,
            coachingSuggestions: coachingSuggestions,
            parentAdvice: parentAdvice,
            processingDuration: 0.0, // No processing for live sessions
            degradationMode: session.degradedMode
        )
    }

    /// Map ParentState to ParentEmotion
    private func mapParentStateToEmotion(_ state: ParentState) -> ParentEmotion {
        switch state {
        case .calm:
            return .calm
        case .coRegulating:
            return .regulated
        case .stressed:
            return .stressed
        case .dysregulated:
            return .overwhelmed
        }
    }
}
