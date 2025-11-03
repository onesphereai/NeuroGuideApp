//
//  SessionContext.swift
//  NeuroGuide
//
//  Session history and trends for context-aware LLM coaching
//

import Foundation

/// Captures session history and trends for context-aware coaching suggestions
struct SessionContext {
    /// Session duration in minutes
    var durationMinutes: Int

    /// Timeline of arousal bands over time
    var arousalTimeline: [ArousalTimelineEntry]

    /// Recently delivered suggestions (to avoid repetition)
    var recentSuggestions: [String]

    /// Co-regulation events observed
    var coRegulationEvents: [String]

    /// Observed behavioral patterns
    var patterns: [String]

    /// Child profile information
    var childProfile: ChildProfile?

    // MARK: - Computed Properties

    /// Summary of behavior trends during this session
    var behaviorSummary: String {
        guard !arousalTimeline.isEmpty else {
            return "Session just started"
        }

        let states = arousalTimeline.map { $0.band }
        let uniqueStates = Set(states)

        // Detect escalation or improvement
        if states.count >= 3 {
            let recent = states.suffix(3)
            if isEscalating(recent) {
                return "Escalating - moved from regulated toward dysregulated state"
            } else if isImproving(recent) {
                return "Improving - moving toward more regulated state"
            }
        }

        // Check for cycling
        if uniqueStates.count >= 3 {
            return "Cycling between multiple arousal states (\(uniqueStates.map { $0.displayName }.joined(separator: ", ")))"
        }

        // Stable state
        if uniqueStates.count == 1 {
            return "Maintaining stable \(states.first!.displayName) state"
        }

        return "Variable arousal with fluctuations between states"
    }

    /// Formatted arousal timeline for prompt (last 2 minutes)
    var arousalTimelineFormatted: String {
        let recentEntries = arousalTimeline.suffix(6) // ~2 min at 20sec intervals
        guard !recentEntries.isEmpty else {
            return "No timeline data yet"
        }

        return recentEntries.map { entry in
            let secondsAgo = Int(Date().timeIntervalSince(entry.timestamp))
            return "\(secondsAgo)s ago: \(entry.band.displayName)"
        }.joined(separator: "\n")
    }

    /// Recent suggestions formatted for prompt
    var recentSuggestionsFormatted: String {
        guard !recentSuggestions.isEmpty else {
            return "No suggestions provided yet this session"
        }

        return recentSuggestions.suffix(5).enumerated().map { index, suggestion in
            "\(index + 1). \(suggestion)"
        }.joined(separator: "\n")
    }

    /// Co-regulation events formatted
    var coRegulationEventsFormatted: String {
        guard !coRegulationEvents.isEmpty else {
            return "No co-regulation events detected yet"
        }

        return coRegulationEvents.suffix(3).map { "• \($0)" }.joined(separator: "\n")
    }

    /// Patterns formatted
    var patternsFormatted: String {
        guard !patterns.isEmpty else {
            return "Not enough data to detect patterns yet"
        }

        return patterns.map { "• \($0)" }.joined(separator: "\n")
    }

    // MARK: - Pattern Detection

    private func isEscalating(_ states: ArraySlice<ArousalBand>) -> Bool {
        // Check if moving toward more dysregulated states
        let values = states.map { bandToValue($0) }
        guard values.count >= 2 else { return false }

        // Check if generally increasing (more dysregulated)
        let changes = zip(values, values.dropFirst()).map { $0.1 - $0.0 }
        let positiveChanges = changes.filter { $0 > 0 }.count
        return positiveChanges > changes.count / 2
    }

    private func isImproving(_ states: ArraySlice<ArousalBand>) -> Bool {
        // Check if moving toward more regulated states
        let values = states.map { bandToValue($0) }
        guard values.count >= 2 else { return false }

        // Check if generally decreasing (more regulated)
        let changes = zip(values, values.dropFirst()).map { $0.1 - $0.0 }
        let negativeChanges = changes.filter { $0 < 0 }.count
        return negativeChanges > changes.count / 2
    }

    private func bandToValue(_ band: ArousalBand) -> Int {
        switch band {
        case .shutdown: return -1
        case .green: return 0
        case .yellow: return 1
        case .orange: return 2
        case .red: return 3
        }
    }
}

/// Entry in arousal timeline
struct ArousalTimelineEntry {
    let timestamp: Date
    let band: ArousalBand
}

// MARK: - SessionContext Builder

extension SessionContext {
    /// Create initial empty session context
    static func initial(childProfile: ChildProfile?) -> SessionContext {
        return SessionContext(
            durationMinutes: 0,
            arousalTimeline: [],
            recentSuggestions: [],
            coRegulationEvents: [],
            patterns: [],
            childProfile: childProfile
        )
    }

    /// Add arousal observation to timeline
    mutating func addArousalObservation(band: ArousalBand) {
        arousalTimeline.append(ArousalTimelineEntry(timestamp: Date(), band: band))

        // Keep only last 10 minutes of data (~30 entries at 20s intervals)
        if arousalTimeline.count > 30 {
            arousalTimeline.removeFirst(arousalTimeline.count - 30)
        }

        // Update patterns
        updatePatterns()
    }

    /// Add delivered suggestion
    mutating func addSuggestion(_ suggestion: String) {
        recentSuggestions.append(suggestion)

        // Keep only last 10 suggestions
        if recentSuggestions.count > 10 {
            recentSuggestions.removeFirst(recentSuggestions.count - 10)
        }
    }

    /// Add co-regulation event
    mutating func addCoRegulationEvent(_ description: String) {
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: timestamp)

        coRegulationEvents.append("\(timeString): \(description)")

        // Keep only last 5 events
        if coRegulationEvents.count > 5 {
            coRegulationEvents.removeFirst(coRegulationEvents.count - 5)
        }
    }

    /// Update duration
    mutating func updateDuration(_ minutes: Int) {
        durationMinutes = minutes
    }

    /// Detect and update patterns
    private mutating func updatePatterns() {
        patterns.removeAll()

        guard arousalTimeline.count >= 5 else { return }

        let recentStates = arousalTimeline.suffix(10).map { $0.band }

        // Pattern: Rapid cycling
        let uniqueRecent = Set(recentStates.suffix(6))
        if uniqueRecent.count >= 3 {
            patterns.append("Rapid cycling between arousal states")
        }

        // Pattern: Prolonged dysregulation
        let redCount = recentStates.filter { $0 == .red || $0 == .orange }.count
        if redCount >= 5 {
            patterns.append("Prolonged dysregulation (in red/orange zone for extended period)")
        }

        // Pattern: Stable regulation
        let greenCount = recentStates.filter { $0 == .green }.count
        if greenCount >= 7 {
            patterns.append("Strong regulation (maintaining green zone)")
        }

        // Pattern: Fluctuating
        if uniqueRecent.count == 2 && recentStates.count >= 6 {
            let transitions = zip(recentStates, recentStates.dropFirst()).filter { $0.0 != $0.1 }.count
            if transitions >= 3 {
                patterns.append("Frequent transitions between states (may indicate sensory seeking or environmental triggers)")
            }
        }
    }
}
