//
//  CoRegulationSummaryCard.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 8 - Co-Regulation Feedback System
//
//  Summary card displaying co-regulation statistics during active session
//

import SwiftUI

/// Card displaying co-regulation statistics for current session
struct CoRegulationSummaryCard: View {
    let eventsCount: Int
    let successRate: Double
    let latestEvent: CoRegulationEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Co-Regulation Moments")
                    .font(.headline)

                Spacer()

                // Events count badge
                if eventsCount > 0 {
                    Text("\(eventsCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(
                            Circle()
                                .fill(Color.blue)
                        )
                }
            }

            if eventsCount > 0 {
                // Statistics
                HStack(spacing: 20) {
                    // Total events
                    StatItem(
                        icon: "checkmark.circle.fill",
                        value: "\(eventsCount)",
                        label: eventsCount == 1 ? "Event" : "Events",
                        color: .green
                    )

                    Divider()
                        .frame(height: 40)

                    // Success rate
                    StatItem(
                        icon: "star.fill",
                        value: "\(Int(successRate * 100))%",
                        label: "Success",
                        color: .yellow
                    )
                }

                // Latest event preview
                if let event = latestEvent {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Most Recent")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)

                            Text(event.childStateBefore.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Image(systemName: "arrow.forward")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(event.childStateAfter.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }

                        if let notes = event.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.3))

                    Text("No co-regulation events yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Keep supporting your child - moments will appear here!")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Compact Variant

/// Compact summary for smaller screens
struct CoRegulationSummaryCompact: View {
    let eventsCount: Int
    let successRate: Double

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Co-Regulation")
                    .font(.headline)

                if eventsCount > 0 {
                    Text("\(eventsCount) moments • \(Int(successRate * 100))% success")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No events yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if eventsCount > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // With events
        CoRegulationSummaryCard(
            eventsCount: 5,
            successRate: 0.80,
            latestEvent: CoRegulationEvent(
                sessionID: UUID(),
                parentState: .coRegulating,
                parentEngagement: 0.85,
                childStateBefore: .orange,
                childStateAfter: .yellow,
                stateImprovement: true,
                duration: 45.0,
                effectiveness: 0.75,
                notes: "Parent used calming voice and gentle touch"
            )
        )

        // Empty state
        CoRegulationSummaryCard(
            eventsCount: 0,
            successRate: 0.0,
            latestEvent: nil
        )

        // Compact variant
        CoRegulationSummaryCompact(
            eventsCount: 3,
            successRate: 0.66
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
