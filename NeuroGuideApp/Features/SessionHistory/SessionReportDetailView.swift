//
//  SessionReportDetailView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 10 - Session History Access
//
//  Detailed view of a single session report
//

import SwiftUI

struct SessionReportDetailView: View {
    let session: SessionAnalysisResult
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    sessionHeader

                    // Arousal Timeline
                    arousalTimelineSection

                    // Behavior Spectrum
                    behaviorSpectrumSection

                    // Coaching Suggestions
                    coachingSuggestionsSection

                    // Parent Advice
                    if let advice = session.parentAdvice {
                        parentAdviceSection(advice)
                    }

                    // Co-Regulation Events
                    coRegulationSection

                    // Metadata
                    metadataSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Session Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var sessionHeader: some View {
        VStack(spacing: 12) {
            // Child name
            Text(session.childName)
                .font(.title.bold())
                .foregroundColor(.primary)

            // Date and duration
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                    Text(formattedDate)
                        .font(.subheadline)
                }

                Divider()
                    .frame(height: 20)

                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.subheadline)
                    Text(formattedDuration)
                        .font(.subheadline)
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Arousal Timeline

    private var arousalTimelineSection: some View {
        SectionCard(title: "Arousal Timeline", icon: "waveform.path.ecg") {
            VStack(spacing: 16) {
                // Timeline visualization
                arousalTimelineChart

                // Summary stats
                HStack(spacing: 12) {
                    Text("Dominant State:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(session.childBehaviorSpectrum.dominantBand.displayName)
                        .font(.caption.bold())
                        .foregroundColor(session.childBehaviorSpectrum.dominantBand.swiftUIColor)

                    Spacer()
                }
            }
        }
    }

    private var arousalTimelineChart: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard !session.arousalTimeline.isEmpty else { return }

                let maxTime = session.arousalTimeline.map { $0.timestamp }.max() ?? 1.0
                let pointWidth = size.width / CGFloat(session.arousalTimeline.count)

                for (index, sample) in session.arousalTimeline.enumerated() {
                    let x = CGFloat(index) * pointWidth
                    let rect = CGRect(x: x, y: 0, width: pointWidth, height: size.height)

                    context.fill(
                        Path(rect),
                        with: .color(sample.band.swiftUIColor.opacity(0.8))
                    )
                }
            }
        }
        .frame(height: 60)
        .cornerRadius(8)
    }

    // MARK: - Behavior Spectrum

    private var behaviorSpectrumSection: some View {
        SectionCard(title: "Behavior Spectrum", icon: "chart.bar.fill") {
            VStack(spacing: 12) {
                BandPercentageBar(
                    band: .shutdown,
                    percentage: session.childBehaviorSpectrum.shutdownPercentage
                )

                BandPercentageBar(
                    band: .green,
                    percentage: session.childBehaviorSpectrum.greenPercentage
                )

                BandPercentageBar(
                    band: .yellow,
                    percentage: session.childBehaviorSpectrum.yellowPercentage
                )

                BandPercentageBar(
                    band: .orange,
                    percentage: session.childBehaviorSpectrum.orangePercentage
                )

                BandPercentageBar(
                    band: .red,
                    percentage: session.childBehaviorSpectrum.redPercentage
                )
            }
        }
    }

    // MARK: - Coaching Suggestions

    private var coachingSuggestionsSection: some View {
        SectionCard(title: "Coaching Suggestions", icon: "lightbulb.fill") {
            if session.coachingSuggestions.isEmpty {
                Text("No suggestions for this session")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(session.coachingSuggestions.enumerated()), id: \.offset) { index, suggestion in
                        SuggestionRow(number: index + 1, suggestion: suggestion)
                    }
                }
            }
        }
    }

    // MARK: - Parent Advice

    private func parentAdviceSection(_ advice: ParentRegulationAdvice) -> some View {
        SectionCard(title: "Parent Self-Regulation", icon: advice.dominantEmotion.icon) {
            VStack(alignment: .leading, spacing: 16) {
                // Dominant emotion
                HStack {
                    Text("Dominant Emotion:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(advice.dominantEmotion.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(advice.dominantEmotion.color)

                    Text("(\(Int(advice.emotionPercentage))% of session)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Regulation strategies
                VStack(alignment: .leading, spacing: 8) {
                    Text("Regulation Strategies:")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    ForEach(Array(advice.regulationStrategies.enumerated()), id: \.offset) { index, strategy in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(strategy)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Co-Regulation Section

    private var coRegulationSection: some View {
        Group {
            if !session.arousalTimeline.isEmpty {
                SectionCard(title: "Co-Regulation Moments", icon: "figure.2.and.child.holdinghands") {
                    Text("Co-regulation data will appear here when available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        SectionCard(title: "Session Details", icon: "info.circle") {
            VStack(spacing: 8) {
                MetadataRow(label: "Session ID", value: session.id.uuidString.prefix(8) + "...")
                MetadataRow(label: "Processing Time", value: String(format: "%.1fs", session.processingDuration))

                if let degradation = session.degradationMode {
                    MetadataRow(label: "Degradation Mode", value: degradation.displayName)
                }

                if session.videoURL != nil {
                    MetadataRow(label: "Video", value: "Saved")
                } else {
                    MetadataRow(label: "Video", value: "Discarded")
                }
            }
        }
    }

    // MARK: - Formatting

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: session.recordedAt)
    }

    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Section Card

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.blue)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Band Percentage Bar

struct BandPercentageBar: View {
    let band: ArousalBand
    let percentage: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(band.displayName)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: geometry.size.width, height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(band.swiftUIColor)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            Text("\(Int(percentage))%")
                .font(.caption.bold())
                .foregroundColor(band.swiftUIColor)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Suggestion Row

struct SuggestionRow: View {
    let number: Int
    let suggestion: CoachingSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.text)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(suggestion.category.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let attribution = suggestion.sourceAttribution {
                        Text("• \(attribution)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Metadata Row

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption.bold())
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Degradation Mode Display

extension DegradationMode {
    var displayName: String {
        switch self {
        case .cameraOnly:
            return "Camera Only"
        case .microphoneOnly:
            return "Audio Only"
        case .manualOnly:
            return "Manual Only"
        }
    }
}

// MARK: - Preview

#Preview {
    SessionReportDetailView(
        session: SessionAnalysisResult(
            childID: UUID(),
            childName: "Alex",
            recordedAt: Date(),
            duration: 120.0,
            videoURL: nil,
            childBehaviorSpectrum: BehaviorSpectrum(
                profileColor: "#4A90E2",
                shutdownPercentage: 10,
                greenPercentage: 40,
                yellowPercentage: 30,
                orangePercentage: 15,
                redPercentage: 5
            ),
            arousalTimeline: [
                ArousalBandSample(timestamp: 0, band: .green, confidence: 0.9),
                ArousalBandSample(timestamp: 30, band: .yellow, confidence: 0.85),
                ArousalBandSample(timestamp: 60, band: .orange, confidence: 0.8),
                ArousalBandSample(timestamp: 90, band: .yellow, confidence: 0.85),
                ArousalBandSample(timestamp: 120, band: .green, confidence: 0.9)
            ],
            parentEmotionTimeline: [],
            coachingSuggestions: [
                CoachingSuggestion(
                    text: "Practice Deep Breathing - Try breathing exercises when you notice stress building",
                    category: .regulation,
                    priority: .high,
                    sourceAttribution: "Evidence-based practice"
                )
            ],
            parentAdvice: ParentRegulationAdvice(
                dominantEmotion: .calm,
                emotionPercentage: 75.0,
                regulationStrategies: [
                    "Great job staying regulated!",
                    "Your calm presence helped your child co-regulate."
                ],
                specificMoments: []
            ),
            processingDuration: 2.5
        )
    )
}
