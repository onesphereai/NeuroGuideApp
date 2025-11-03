//
//  SessionHistoryListView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 10 - Session History Access
//
//  List view showing all past coaching sessions
//

import SwiftUI

struct SessionHistoryListView: View {
    @ObservedObject private var historyManager = SessionHistoryManager.shared
    @EnvironmentObject var navigationState: NavigationState
    @State private var selectedSession: SessionAnalysisResult?

    var body: some View {
        NavigationView {
            ZStack {
                if historyManager.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        navigationState.currentScreen = .home
                    }
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionReportDetailView(session: session)
            }
        }
    }

    // MARK: - Session List

    private var sessionList: some View {
        List {
            ForEach(historyManager.getAllSessions()) { session in
                SessionRowView(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSession = session
                    }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No Sessions Yet")
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text("Complete a Live Coach session to see it here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                navigationState.currentScreen = .liveCoach
            } label: {
                HStack {
                    Image(systemName: "video.fill")
                    Text("Start Live Coach")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: SessionAnalysisResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and child name
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.childName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Duration badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text(formattedDuration)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.1))
                )
            }

            // Arousal summary bar
            arousalSummaryBar

            // Quick stats
            HStack(spacing: 20) {
                StatBadge(
                    icon: "waveform.path.ecg",
                    label: "Dominant",
                    value: session.childBehaviorSpectrum.dominantBand.displayName,
                    color: session.childBehaviorSpectrum.dominantBand.swiftUIColor
                )

                if session.coachingSuggestions.count > 0 {
                    StatBadge(
                        icon: "lightbulb.fill",
                        label: "Suggestions",
                        value: "\(session.coachingSuggestions.count)",
                        color: .yellow
                    )
                }

                if let advice = session.parentAdvice {
                    StatBadge(
                        icon: advice.dominantEmotion.icon,
                        label: "Parent",
                        value: advice.dominantEmotion.displayName,
                        color: advice.dominantEmotion.color
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Arousal Summary Bar

    private var arousalSummaryBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                let spectrum = session.childBehaviorSpectrum

                if spectrum.shutdownPercentage > 0 {
                    Rectangle()
                        .fill(ArousalBand.shutdown.swiftUIColor)
                        .frame(width: geometry.size.width * CGFloat(spectrum.shutdownPercentage / 100))
                }

                if spectrum.greenPercentage > 0 {
                    Rectangle()
                        .fill(ArousalBand.green.swiftUIColor)
                        .frame(width: geometry.size.width * CGFloat(spectrum.greenPercentage / 100))
                }

                if spectrum.yellowPercentage > 0 {
                    Rectangle()
                        .fill(ArousalBand.yellow.swiftUIColor)
                        .frame(width: geometry.size.width * CGFloat(spectrum.yellowPercentage / 100))
                }

                if spectrum.orangePercentage > 0 {
                    Rectangle()
                        .fill(ArousalBand.orange.swiftUIColor)
                        .frame(width: geometry.size.width * CGFloat(spectrum.orangePercentage / 100))
                }

                if spectrum.redPercentage > 0 {
                    Rectangle()
                        .fill(ArousalBand.red.swiftUIColor)
                        .frame(width: geometry.size.width * CGFloat(spectrum.redPercentage / 100))
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
        .frame(height: 6)
    }

    // MARK: - Formatting

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.recordedAt)
    }

    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SessionHistoryListView()
            .environmentObject(NavigationState.shared)
    }
}
