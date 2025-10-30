//
//  ArousalTimelineGraphView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Unit 5 - Live Coach Record-First Flow
//

import SwiftUI

/// Graph showing arousal changes over the session timeline
struct ArousalTimelineGraphView: View {
    let samples: [ArousalBandSample]
    let duration: TimeInterval
    let profileColor: String

    @State private var selectedSample: ArousalBandSample?
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Arousal Timeline")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("How arousal levels changed during the session")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Graph
            ZStack(alignment: .topLeading) {
                // Background zones
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Red zone
                        ZoneBackground(color: .red.opacity(0.1), label: "Red")
                            .frame(height: geometry.size.height / 5)

                        // Orange zone
                        ZoneBackground(color: .orange.opacity(0.1), label: "Orange")
                            .frame(height: geometry.size.height / 5)

                        // Yellow zone
                        ZoneBackground(color: .yellow.opacity(0.1), label: "Yellow")
                            .frame(height: geometry.size.height / 5)

                        // Green zone
                        ZoneBackground(color: .green.opacity(0.1), label: "Green")
                            .frame(height: geometry.size.height / 5)

                        // Shutdown zone
                        ZoneBackground(color: .blue.opacity(0.1), label: "Shutdown")
                            .frame(height: geometry.size.height / 5)
                    }

                    // Timeline line
                    TimelinePath(samples: samples, duration: duration, profileColor: profileColor)
                        .stroke(
                            Color(hex: profileColor) ?? .blue,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )

                    // Data points
                    ForEach(samples) { sample in
                        DataPoint(
                            sample: sample,
                            duration: duration,
                            geometry: geometry,
                            isSelected: selectedSample?.id == sample.id
                        )
                        .onTapGesture {
                            selectedSample = sample
                            showDetails = true
                        }
                    }
                }
                .frame(height: 250)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )

            // Time axis
            TimeAxis(duration: duration)

            // Selected sample details
            if let sample = selectedSample {
                SampleDetailsCard(sample: sample)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Zone Background

struct ZoneBackground: View {
    let color: Color
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Timeline Path

struct TimelinePath: Shape {
    let samples: [ArousalBandSample]
    let duration: TimeInterval
    let profileColor: String

    func path(in rect: CGRect) -> Path {
        guard !samples.isEmpty else { return Path() }

        var path = Path()

        // Map first point
        let firstSample = samples[0]
        let firstX = xPosition(for: firstSample.timestamp, in: rect)
        let firstY = yPosition(for: firstSample.band, in: rect)
        path.move(to: CGPoint(x: firstX, y: firstY))

        // Draw line through all points
        for sample in samples.dropFirst() {
            let x = xPosition(for: sample.timestamp, in: rect)
            let y = yPosition(for: sample.band, in: rect)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }

    private func xPosition(for timestamp: TimeInterval, in rect: CGRect) -> CGFloat {
        let progress = timestamp / duration
        return rect.width * progress
    }

    private func yPosition(for band: ArousalBand, in rect: CGRect) -> CGFloat {
        let zoneHeight = rect.height / 5
        let zoneIndex: CGFloat

        switch band {
        case .red: zoneIndex = 0.5
        case .orange: zoneIndex = 1.5
        case .yellow: zoneIndex = 2.5
        case .green: zoneIndex = 3.5
        case .shutdown: zoneIndex = 4.5
        }

        return zoneIndex * zoneHeight
    }
}

// MARK: - Data Point

struct DataPoint: View {
    let sample: ArousalBandSample
    let duration: TimeInterval
    let geometry: GeometryProxy
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(colorForBand(sample.band))
            .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .position(
                x: xPosition,
                y: yPosition
            )
            .animation(.spring(response: 0.3), value: isSelected)
    }

    private var xPosition: CGFloat {
        let progress = sample.timestamp / duration
        return geometry.size.width * progress
    }

    private var yPosition: CGFloat {
        let zoneHeight = geometry.size.height / 5
        let zoneIndex: CGFloat

        switch sample.band {
        case .red: zoneIndex = 0.5
        case .orange: zoneIndex = 1.5
        case .yellow: zoneIndex = 2.5
        case .green: zoneIndex = 3.5
        case .shutdown: zoneIndex = 4.5
        }

        return zoneIndex * zoneHeight
    }

    private func colorForBand(_ band: ArousalBand) -> Color {
        Color(band.color)
    }
}

// MARK: - Time Axis

struct TimeAxis: View {
    let duration: TimeInterval

    var body: some View {
        HStack {
            ForEach(timeMarkers, id: \.self) { seconds in
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 4)

                    Text(formatTime(seconds))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var timeMarkers: [Int] {
        let totalSeconds = Int(duration)
        let interval = 10  // Every 10 seconds
        return stride(from: 0, through: totalSeconds, by: interval).map { $0 }
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds == 0 {
            return "0s"
        } else if seconds >= 60 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Sample Details Card

struct SampleDetailsCard: View {
    let sample: ArousalBandSample

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(sample.band.color))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("At \(formatTimestamp(sample.timestamp))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(sample.band.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Confidence: \(Int(sample.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(sample.band.color).opacity(0.1))
        )
        .accessibilityElement(children: .combine)
    }

    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Preview

struct ArousalTimelineGraphView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ArousalTimelineGraphView(
                samples: [
                    ArousalBandSample(timestamp: 0, band: .green, confidence: 0.8),
                    ArousalBandSample(timestamp: 5, band: .green, confidence: 0.7),
                    ArousalBandSample(timestamp: 10, band: .yellow, confidence: 0.6),
                    ArousalBandSample(timestamp: 15, band: .yellow, confidence: 0.7),
                    ArousalBandSample(timestamp: 20, band: .orange, confidence: 0.8),
                    ArousalBandSample(timestamp: 25, band: .orange, confidence: 0.9),
                    ArousalBandSample(timestamp: 30, band: .red, confidence: 0.85),
                    ArousalBandSample(timestamp: 35, band: .orange, confidence: 0.8),
                    ArousalBandSample(timestamp: 40, band: .yellow, confidence: 0.7),
                    ArousalBandSample(timestamp: 45, band: .green, confidence: 0.75),
                    ArousalBandSample(timestamp: 50, band: .green, confidence: 0.8),
                    ArousalBandSample(timestamp: 55, band: .green, confidence: 0.85),
                    ArousalBandSample(timestamp: 60, band: .green, confidence: 0.9)
                ],
                duration: 60,
                profileColor: "#4A90E2"
            )
            .padding()
        }
    }
}
