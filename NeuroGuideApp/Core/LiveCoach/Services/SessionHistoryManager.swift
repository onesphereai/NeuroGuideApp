//
//  SessionHistoryManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Unit 5 - Live Coach Record-First Flow
//

import Foundation
import Combine

/// Manages session history with 4-week retention policy
@MainActor
class SessionHistoryManager: ObservableObject {
    // MARK: - Singleton

    static let shared = SessionHistoryManager()

    // MARK: - Published Properties

    @Published private(set) var sessions: [SessionAnalysisResult] = []

    // MARK: - Private Properties

    private let retentionPeriod: TimeInterval = 28 * 24 * 60 * 60  // 4 weeks in seconds
    private let storageKey = "sessionHistory"
    private let fileManager = FileManager.default

    // MARK: - Initialization

    private init() {
        loadSessions()
        cleanupOldSessions()
    }

    // MARK: - Session Management

    /// Save a new session result
    func saveSession(_ session: SessionAnalysisResult) throws {
        print("💾 Saving session: \(session.id)")

        // Add to in-memory list
        sessions.append(session)

        // Save to disk
        try persistSessions()

        print("✅ Session saved successfully")
    }

    /// Get sessions for a specific child
    func getSessions(for childID: UUID) -> [SessionAnalysisResult] {
        return sessions
            .filter { $0.childID == childID }
            .sorted { $0.recordedAt > $1.recordedAt }  // Most recent first
    }

    /// Get all sessions (sorted by date)
    func getAllSessions() -> [SessionAnalysisResult] {
        return sessions.sorted { $0.recordedAt > $1.recordedAt }
    }

    /// Get session by ID
    func getSession(id: UUID) -> SessionAnalysisResult? {
        return sessions.first { $0.id == id }
    }

    /// Delete a specific session
    func deleteSession(id: UUID) throws {
        print("🗑️ Deleting session: \(id)")

        guard let index = sessions.firstIndex(where: { $0.id == id }) else {
            throw SessionHistoryError.sessionNotFound
        }

        var session = sessions[index]

        // Delete video file if it exists
        session.discardVideo()

        // Remove from list
        sessions.remove(at: index)

        // Save to disk
        try persistSessions()

        print("✅ Session deleted successfully")
    }

    /// Discard video for a session (keep analysis results)
    func discardVideo(for sessionID: UUID) throws {
        print("🗑️ Discarding video for session: \(sessionID)")

        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw SessionHistoryError.sessionNotFound
        }

        // Discard video
        sessions[index].discardVideo()

        // Save updated session to disk
        try persistSessions()

        print("✅ Video discarded successfully")
    }

    /// Get statistics for a child over the retention period
    func getChildStatistics(for childID: UUID) -> ChildSessionStatistics? {
        let childSessions = getSessions(for: childID)

        guard !childSessions.isEmpty else { return nil }

        // Calculate statistics
        let totalSessions = childSessions.count
        let averageDuration = childSessions.map { $0.duration }.reduce(0, +) / Double(totalSessions)

        // Dominant arousal band across all sessions
        var bandCounts: [ArousalBand: Int] = [:]
        for session in childSessions {
            let band = session.childBehaviorSpectrum.dominantBand
            bandCounts[band, default: 0] += 1
        }
        let dominantBand = bandCounts.max(by: { $0.value < $1.value })?.key ?? .green

        // Average percentages across all sessions
        let avgShutdown = childSessions.map { $0.childBehaviorSpectrum.shutdownPercentage }.reduce(0, +) / Double(totalSessions)
        let avgGreen = childSessions.map { $0.childBehaviorSpectrum.greenPercentage }.reduce(0, +) / Double(totalSessions)
        let avgYellow = childSessions.map { $0.childBehaviorSpectrum.yellowPercentage }.reduce(0, +) / Double(totalSessions)
        let avgOrange = childSessions.map { $0.childBehaviorSpectrum.orangePercentage }.reduce(0, +) / Double(totalSessions)
        let avgRed = childSessions.map { $0.childBehaviorSpectrum.redPercentage }.reduce(0, +) / Double(totalSessions)

        return ChildSessionStatistics(
            totalSessions: totalSessions,
            averageDuration: averageDuration,
            dominantBand: dominantBand,
            averageShutdownPercentage: avgShutdown,
            averageGreenPercentage: avgGreen,
            averageYellowPercentage: avgYellow,
            averageOrangePercentage: avgOrange,
            averageRedPercentage: avgRed,
            mostRecentSession: childSessions.first?.recordedAt ?? Date()
        )
    }

    // MARK: - Persistence

    private func loadSessions() {
        guard let url = getStorageURL() else {
            print("⚠️ Could not get storage URL")
            return
        }

        guard fileManager.fileExists(atPath: url.path) else {
            print("ℹ️ No existing session history found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            sessions = try decoder.decode([SessionAnalysisResult].self, from: data)
            print("📂 Loaded \(sessions.count) sessions from disk")
        } catch {
            print("❌ Failed to load session history: \(error)")
            print("   Clearing corrupted session data...")
            // Clear corrupted data
            sessions = []
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func persistSessions() throws {
        guard let url = getStorageURL() else {
            throw SessionHistoryError.storageUnavailable
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970

        let data = try encoder.encode(sessions)
        try data.write(to: url, options: [.atomic, .completeFileProtection])

        print("💾 Persisted \(sessions.count) sessions to disk")
    }

    private func getStorageURL() -> URL? {
        guard let documentsDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        return documentsDirectory.appendingPathComponent(storageKey + ".json")
    }

    // MARK: - Cleanup

    /// Remove sessions older than 4 weeks
    private func cleanupOldSessions() {
        let cutoffDate = Date().addingTimeInterval(-retentionPeriod)
        let oldSessions = sessions.filter { $0.recordedAt < cutoffDate }

        guard !oldSessions.isEmpty else {
            print("ℹ️ No old sessions to clean up")
            return
        }

        print("🧹 Cleaning up \(oldSessions.count) sessions older than 4 weeks")

        // Discard videos and remove from list
        for session in oldSessions {
            var mutableSession = session
            mutableSession.discardVideo()
        }

        sessions.removeAll { $0.recordedAt < cutoffDate }

        // Save to disk
        do {
            try persistSessions()
            print("✅ Cleanup complete")
        } catch {
            print("❌ Failed to persist after cleanup: \(error)")
        }
    }

    /// Manually trigger cleanup (useful for testing)
    func performCleanup() {
        cleanupOldSessions()
    }

    /// Get storage size for session history
    func getStorageSize() -> Int64 {
        guard let url = getStorageURL(),
              let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }

        return fileSize
    }

    /// Format storage size for display
    func getFormattedStorageSize() -> String {
        let size = getStorageSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Child Session Statistics

struct ChildSessionStatistics {
    let totalSessions: Int
    let averageDuration: TimeInterval
    let dominantBand: ArousalBand
    let averageShutdownPercentage: Double
    let averageGreenPercentage: Double
    let averageYellowPercentage: Double
    let averageOrangePercentage: Double
    let averageRedPercentage: Double
    let mostRecentSession: Date

    var formattedAverageDuration: String {
        let minutes = Int(averageDuration) / 60
        let seconds = Int(averageDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Errors

enum SessionHistoryError: LocalizedError {
    case sessionNotFound
    case storageUnavailable
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Session not found in history."
        case .storageUnavailable:
            return "Unable to access storage."
        case .encodingFailed:
            return "Failed to save session data."
        case .decodingFailed:
            return "Failed to load session data."
        }
    }
}
