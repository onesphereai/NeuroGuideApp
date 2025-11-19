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
        VStack(alignment: .leading, spacing: 18) {
            // Modern Header with gradient icon
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.15), Color.green.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Co-Regulation Moments")
                    .font(.system(size: 17, weight: .bold))

                Spacer()

                // Modern count badge
                if eventsCount > 0 {
                    Text("\(eventsCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 28, minHeight: 28)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .green],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
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

                // Modern latest event preview
                if let event = latestEvent {
                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Most Recent")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }

                            Text(event.childStateBefore.displayName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.1))
                                )

                            Image(systemName: "arrow.forward")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)

                            Text(event.childStateAfter.displayName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.15))
                                )
                        }

                        if let notes = event.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                    }
                }
            } else {
                // Modern empty state
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)

                        Image(systemName: "figure.2.and.child.holdinghands")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.4), .green.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("No co-regulation events yet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text("Keep supporting your child - moments will appear here!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.green.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 12, weight: .medium))
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
