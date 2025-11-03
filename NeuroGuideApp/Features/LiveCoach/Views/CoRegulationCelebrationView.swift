//
//  CoRegulationCelebrationView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 8 - Co-Regulation Feedback System
//
//  Real-time celebration overlay when co-regulation event is detected
//

import SwiftUI

/// Celebration overlay for successful co-regulation events
struct CoRegulationCelebrationView: View {
    let event: CoRegulationEvent
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

    var body: some View {
        VStack(spacing: 16) {
            // Success icon with animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(scale)

            // Success message
            VStack(spacing: 8) {
                Text("Great Connection!")
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text(event.eventDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Effectiveness indicator
                if event.effectiveness > 0.7 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("Highly Effective")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.1))
                    )
                }
            }
            .opacity(opacity)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Compact Variant

/// Compact celebration banner (less intrusive)
struct CoRegulationBanner: View {
    let event: CoRegulationEvent
    @State private var offset: CGFloat = -100

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hands.sparkles.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Co-Regulation Success!")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Child moved from \(event.childStateBefore.displayName) to \(event.childStateAfter.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                offset = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGray6)
            .ignoresSafeArea()

        VStack(spacing: 40) {
            // Full celebration
            CoRegulationCelebrationView(
                event: CoRegulationEvent(
                    sessionID: UUID(),
                    parentState: .coRegulating,
                    parentEngagement: 0.85,
                    childStateBefore: .orange,
                    childStateAfter: .yellow,
                    stateImprovement: true,
                    duration: 45.0,
                    effectiveness: 0.75
                )
            )

            // Compact banner
            CoRegulationBanner(
                event: CoRegulationEvent(
                    sessionID: UUID(),
                    parentState: .calm,
                    parentEngagement: 0.90,
                    childStateBefore: .red,
                    childStateAfter: .orange,
                    stateImprovement: true,
                    duration: 60.0,
                    effectiveness: 0.85
                )
            )
        }
    }
}
