//
//  CoRegulationHistory.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation

/// Tracks history of co-regulation strategies and their effectiveness
/// Helps prioritize strategies that have worked in the past
struct CoRegulationHistory: Codable {
    /// Total number of Live Coach sessions completed
    var totalSessions: Int

    /// Strategy usage count (Strategy ID -> usage count)
    var strategyUsage: [UUID: Int]

    /// Average helpfulness rating across all sessions (1-5 scale)
    var averageHelpfulness: Double

    /// Date of last update
    var lastUpdated: Date?

    init(
        totalSessions: Int = 0,
        strategyUsage: [UUID: Int] = [:],
        averageHelpfulness: Double = 0.0,
        lastUpdated: Date? = nil
    ) {
        self.totalSessions = totalSessions
        self.strategyUsage = strategyUsage
        self.averageHelpfulness = averageHelpfulness
        self.lastUpdated = lastUpdated
    }

    /// Record a completed session with strategies used and helpfulness rating
    mutating func recordSession(strategies: [UUID], helpfulness: Int) {
        totalSessions += 1

        // Update strategy usage counts
        for strategyID in strategies {
            strategyUsage[strategyID, default: 0] += 1
        }

        // Update average helpfulness using exponential moving average
        let newHelpfulness = Double(helpfulness)
        if averageHelpfulness == 0.0 {
            averageHelpfulness = newHelpfulness
        } else {
            // Weight: 80% historical, 20% new rating
            averageHelpfulness = (averageHelpfulness * 0.8) + (newHelpfulness * 0.2)
        }

        lastUpdated = Date()
    }

    /// Get most frequently used strategies
    func getTopStrategies(limit: Int = 5) -> [UUID] {
        return strategyUsage
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    /// Get usage count for a specific strategy
    func getUsageCount(for strategyID: UUID) -> Int {
        return strategyUsage[strategyID] ?? 0
    }
}
