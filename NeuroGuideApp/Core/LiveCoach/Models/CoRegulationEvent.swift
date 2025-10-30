//
//  CoRegulationEvent.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System (Co-Regulation Tracking)
//

import Foundation

/// Tracks moments when parent co-regulation correlates with child state improvement
struct CoRegulationEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let sessionID: UUID
    let timestamp: Date

    // Parent state during event
    let parentState: ParentState
    let parentEngagement: Double // 0-1

    // Child state changes
    let childStateBefore: ArousalBand
    let childStateAfter: ArousalBand
    let stateImprovement: Bool // Did child move to lower arousal?

    // Event metrics
    let duration: TimeInterval // How long parent engaged
    let effectiveness: Double // 0-1, how effective was co-regulation

    // Context
    let notes: String?

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        timestamp: Date = Date(),
        parentState: ParentState,
        parentEngagement: Double,
        childStateBefore: ArousalBand,
        childStateAfter: ArousalBand,
        stateImprovement: Bool,
        duration: TimeInterval,
        effectiveness: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.parentState = parentState
        self.parentEngagement = parentEngagement
        self.childStateBefore = childStateBefore
        self.childStateAfter = childStateAfter
        self.stateImprovement = stateImprovement
        self.duration = duration
        self.effectiveness = effectiveness
        self.notes = notes
    }

    /// Check if this was a successful co-regulation event
    var wasSuccessful: Bool {
        return stateImprovement && effectiveness > 0.6
    }

    /// Description of the event
    var eventDescription: String {
        if wasSuccessful {
            return "Parent \(parentState.displayName.lowercased()) helped child transition from \(childStateBefore.displayName) to \(childStateAfter.displayName)"
        } else {
            return "Parent attempted co-regulation while child was \(childStateBefore.displayName)"
        }
    }
}

/// Tracks co-regulation patterns over time
struct CoRegulationPattern {
    let totalEvents: Int
    let successfulEvents: Int
    let averageEffectiveness: Double
    let mostEffectiveParentState: ParentState?
    let mostCommonTransition: (from: ArousalBand, to: ArousalBand)?

    var successRate: Double {
        guard totalEvents > 0 else { return 0.0 }
        return Double(successfulEvents) / Double(totalEvents)
    }

    var description: String {
        let percentage = Int(successRate * 100)
        if let mostEffective = mostEffectiveParentState {
            return "\(percentage)% success rate when parent is \(mostEffective.displayName.lowercased())"
        } else {
            return "\(percentage)% success rate"
        }
    }
}

/// Helper to detect co-regulation events
@MainActor
class CoRegulationDetector {
    // MARK: - Properties

    private var childStateHistory: [(state: ArousalBand, timestamp: Date)] = []
    private var parentStateHistory: [(state: ParentState, engagement: Double, timestamp: Date)] = []

    private let detectionWindow: TimeInterval = 30.0 // 30 seconds
    private let minEngagementLevel: Double = 0.6 // Parent must be engaged

    // MARK: - Detection

    /// Record child arousal state
    func recordChildState(_ state: ArousalBand) {
        childStateHistory.append((state: state, timestamp: Date()))
        cleanupOldHistory()
    }

    /// Record parent state
    func recordParentState(_ state: ParentState, engagement: Double) {
        parentStateHistory.append((state: state, engagement: engagement, timestamp: Date()))
        cleanupOldHistory()
    }

    /// Detect if a co-regulation event occurred
    /// Returns event if parent engagement correlated with child improvement
    func detectCoRegulationEvent(sessionID: UUID) -> CoRegulationEvent? {
        guard childStateHistory.count >= 2,
              !parentStateHistory.isEmpty else {
            return nil
        }

        // Get recent child state change
        let recentChild = childStateHistory.suffix(2)
        guard recentChild.count == 2 else { return nil }

        let beforeState = recentChild[recentChild.startIndex].state
        let afterState = recentChild[recentChild.startIndex + 1].state
        let changeTime = recentChild[recentChild.startIndex + 1].timestamp

        // Check if child state improved (moved to lower arousal band)
        guard afterState.severity < beforeState.severity else {
            return nil
        }

        // Find parent states around the time of change
        let relevantParentStates = parentStateHistory.filter { entry in
            abs(entry.timestamp.timeIntervalSince(changeTime)) < detectionWindow
        }

        guard !relevantParentStates.isEmpty else {
            return nil
        }

        // Check if parent was engaged during this period
        let engagedStates = relevantParentStates.filter { $0.engagement >= minEngagementLevel }

        guard !engagedStates.isEmpty else {
            return nil
        }

        // Calculate average engagement and get most common state
        let avgEngagement = engagedStates.reduce(0.0) { $0 + $1.engagement } / Double(engagedStates.count)
        let parentState = engagedStates.last?.state ?? .calm

        // Calculate effectiveness based on arousal band improvement
        let severityReduction = Double(beforeState.severity - afterState.severity)
        let effectiveness = min(severityReduction / Double(ArousalBand.allCases.count - 1), 1.0)

        // Calculate duration of engagement
        let duration = engagedStates.last!.timestamp.timeIntervalSince(engagedStates.first!.timestamp)

        return CoRegulationEvent(
            sessionID: sessionID,
            timestamp: changeTime,
            parentState: parentState,
            parentEngagement: avgEngagement,
            childStateBefore: beforeState,
            childStateAfter: afterState,
            stateImprovement: true,
            duration: max(duration, 1.0),
            effectiveness: effectiveness,
            notes: nil
        )
    }

    /// Clear all history
    func clearHistory() {
        childStateHistory.removeAll()
        parentStateHistory.removeAll()
    }

    // MARK: - Private Helpers

    private func cleanupOldHistory() {
        let cutoffTime = Date().addingTimeInterval(-detectionWindow * 2)

        childStateHistory.removeAll { $0.timestamp < cutoffTime }
        parentStateHistory.removeAll { $0.timestamp < cutoffTime }
    }
}

// MARK: - ArousalBand Extension

extension ArousalBand {
    /// Severity level for co-regulation detection (0-4)
    var severity: Int {
        switch self {
        case .shutdown: return 0
        case .green: return 1
        case .yellow: return 2
        case .orange: return 3
        case .red: return 4
        }
    }
}
