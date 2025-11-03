//
//  StabilizedBandTracker.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 7 - Multi-Tier Arousal Display
//
//  Tracks arousal band over time and only reports changes when a band
//  has sustained for a minimum duration, reducing false alarms from
//  momentary fluctuations.
//

import Foundation

/// Tracks arousal bands and filters out transient changes
/// Only reports a new band when it has sustained for the threshold duration
@MainActor
class StabilizedBandTracker {

    // MARK: - Configuration

    /// Minimum duration a band must sustain before being reported
    private let sustainThreshold: TimeInterval

    // MARK: - State

    /// The current stable band being displayed to the user
    private(set) var currentStableBand: ArousalBand?

    /// The candidate band that might become stable
    private var candidateBand: ArousalBand?

    /// When the candidate band first appeared
    private var candidateStartTime: Date?

    // MARK: - Initialization

    init(sustainThreshold: TimeInterval = 20.0) {
        self.sustainThreshold = sustainThreshold
        print("🎯 StabilizedBandTracker initialized with \(sustainThreshold)s threshold")
    }

    // MARK: - Public API

    /// Update with a new arousal band reading
    /// - Parameter band: The current arousal band from real-time detection
    /// - Returns: The stable band to display, or nil if no change
    func update(band: ArousalBand) -> ArousalBand? {
        let now = Date()

        // Case 1: Same as candidate - check if it has sustained long enough
        if band == candidateBand {
            guard let startTime = candidateStartTime else {
                // This shouldn't happen, but handle gracefully
                candidateStartTime = now
                return nil
            }

            let duration = now.timeIntervalSince(startTime)

            if duration >= sustainThreshold {
                // Band has sustained! Update stable band
                let oldBand = currentStableBand
                currentStableBand = candidateBand

                // Reset candidate tracking
                candidateBand = nil
                candidateStartTime = nil

                if oldBand != currentStableBand {
                    print("✅ Stable band changed: \(oldBand?.rawValue ?? "nil") → \(currentStableBand?.rawValue ?? "nil")")
                    return currentStableBand
                }
            }

            return nil  // Still waiting for sustain
        }

        // Case 2: New band detected - start tracking as candidate
        else {
            // If we already have a stable band and the new band matches it,
            // we can skip the sustain check (band returned to stable state)
            if band == currentStableBand {
                candidateBand = nil
                candidateStartTime = nil
                return nil  // Already displaying this band
            }

            // New candidate band
            candidateBand = band
            candidateStartTime = now

            print("🔄 New candidate band: \(band.rawValue) (needs \(sustainThreshold)s)")
            return nil  // Don't update display yet
        }
    }

    /// Reset the tracker (e.g., when session ends)
    func reset() {
        currentStableBand = nil
        candidateBand = nil
        candidateStartTime = nil
        print("🔄 StabilizedBandTracker reset")
    }

    /// Get the current progress toward sustaining the candidate band (0.0 to 1.0)
    func getCandidateProgress() -> Double {
        guard let startTime = candidateStartTime else { return 0.0 }

        let elapsed = Date().timeIntervalSince(startTime)
        return min(elapsed / sustainThreshold, 1.0)
    }

    /// Check if currently tracking a candidate band
    var hasCandidate: Bool {
        return candidateBand != nil
    }

    /// Get the candidate band being tracked
    var candidate: ArousalBand? {
        return candidateBand
    }
}
