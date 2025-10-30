//
//  BehaviorSpectrumView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Unit 5 - Live Coach Record-First Flow
//

import SwiftUI

/// Displays child's behavior spectrum from session analysis
struct BehaviorSpectrumView: View {
    let spectrum: BehaviorSpectrum
    let childName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("\(childName)'s Behavior Spectrum")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Distribution of arousal states during this session")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Spectrum bar
            SpectrumBar(spectrum: spectrum)

            // Legend with percentages
            SpectrumLegend(spectrum: spectrum)

            // Dominant state summary
            DominantStateSummary(spectrum: spectrum, childName: childName)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Spectrum Bar

struct SpectrumBar: View {
    let spectrum: BehaviorSpectrum

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Shutdown
                if spectrum.shutdownPercentage > 0 {
                    Rectangle()
                        .fill(
                            Color.blue.blend(
                                with: Color(hex: spectrum.profileColor) ?? .blue,
                                ratio: 0.3
                            )
                        )
                        .frame(width: geometry.size.width * (spectrum.shutdownPercentage / 100))
                }

                // Green
                if spectrum.greenPercentage > 0 {
                    Rectangle()
                        .fill(
                            Color.green.blend(
                                with: Color(hex: spectrum.profileColor) ?? .blue,
                                ratio: 0.3
                            )
                        )
                        .frame(width: geometry.size.width * (spectrum.greenPercentage / 100))
                }

                // Yellow
                if spectrum.yellowPercentage > 0 {
                    Rectangle()
                        .fill(
                            Color.yellow.blend(
                                with: Color(hex: spectrum.profileColor) ?? .blue,
                                ratio: 0.3
                            )
                        )
                        .frame(width: geometry.size.width * (spectrum.yellowPercentage / 100))
                }

                // Orange
                if spectrum.orangePercentage > 0 {
                    Rectangle()
                        .fill(
                            Color.orange.blend(
                                with: Color(hex: spectrum.profileColor) ?? .blue,
                                ratio: 0.3
                            )
                        )
                        .frame(width: geometry.size.width * (spectrum.orangePercentage / 100))
                }

                // Red
                if spectrum.redPercentage > 0 {
                    Rectangle()
                        .fill(
                            Color.red.blend(
                                with: Color(hex: spectrum.profileColor) ?? .blue,
                                ratio: 0.3
                            )
                        )
                        .frame(width: geometry.size.width * (spectrum.redPercentage / 100))
                }
            }
        }
        .frame(height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Behavior spectrum")
        .accessibilityValue(spectrumAccessibilityDescription)
    }

    private var spectrumAccessibilityDescription: String {
        var parts: [String] = []

        if spectrum.shutdownPercentage > 0 {
            parts.append("\(Int(spectrum.shutdownPercentage))% shutdown")
        }
        if spectrum.greenPercentage > 0 {
            parts.append("\(Int(spectrum.greenPercentage))% regulated")
        }
        if spectrum.yellowPercentage > 0 {
            parts.append("\(Int(spectrum.yellowPercentage))% elevated")
        }
        if spectrum.orangePercentage > 0 {
            parts.append("\(Int(spectrum.orangePercentage))% escalating")
        }
        if spectrum.redPercentage > 0 {
            parts.append("\(Int(spectrum.redPercentage))% crisis")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Spectrum Legend

struct SpectrumLegend: View {
    let spectrum: BehaviorSpectrum

    var body: some View {
        VStack(spacing: 8) {
            if spectrum.shutdownPercentage > 0 {
                LegendRow(
                    color: Color.blue.blend(
                        with: Color(hex: spectrum.profileColor) ?? .blue,
                        ratio: 0.3
                    ),
                    label: "Shutdown",
                    percentage: spectrum.shutdownPercentage
                )
            }

            if spectrum.greenPercentage > 0 {
                LegendRow(
                    color: Color.green.blend(
                        with: Color(hex: spectrum.profileColor) ?? .blue,
                        ratio: 0.3
                    ),
                    label: "Green Zone (Regulated)",
                    percentage: spectrum.greenPercentage
                )
            }

            if spectrum.yellowPercentage > 0 {
                LegendRow(
                    color: Color.yellow.blend(
                        with: Color(hex: spectrum.profileColor) ?? .blue,
                        ratio: 0.3
                    ),
                    label: "Yellow Zone (Elevated)",
                    percentage: spectrum.yellowPercentage
                )
            }

            if spectrum.orangePercentage > 0 {
                LegendRow(
                    color: Color.orange.blend(
                        with: Color(hex: spectrum.profileColor) ?? .blue,
                        ratio: 0.3
                    ),
                    label: "Orange Zone (Escalating)",
                    percentage: spectrum.orangePercentage
                )
            }

            if spectrum.redPercentage > 0 {
                LegendRow(
                    color: Color.red.blend(
                        with: Color(hex: spectrum.profileColor) ?? .blue,
                        ratio: 0.3
                    ),
                    label: "Red Zone (Crisis)",
                    percentage: spectrum.redPercentage
                )
            }
        }
    }
}

struct LegendRow: View {
    let color: Color
    let label: String
    let percentage: Double

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.subheadline)

            Spacer()

            Text("\(Int(percentage))%")
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Dominant State Summary

struct DominantStateSummary: View {
    let spectrum: BehaviorSpectrum
    let childName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForBand(spectrum.dominantBand))
                .font(.title2)
                .foregroundColor(colorForBand(spectrum.dominantBand))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Dominant State")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(summaryText)
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorForBand(spectrum.dominantBand).opacity(0.1))
        )
        .accessibilityElement(children: .combine)
    }

    private var summaryText: String {
        switch spectrum.dominantBand {
        case .shutdown:
            return "\(childName) spent most of this session in shutdown mode."
        case .green:
            return "\(childName) was mostly regulated during this session."
        case .yellow:
            return "\(childName) showed signs of elevated arousal."
        case .orange:
            return "\(childName) was escalating for much of this session."
        case .red:
            return "\(childName) was in crisis mode during this session."
        }
    }

    private func iconForBand(_ band: ArousalBand) -> String {
        switch band {
        case .shutdown: return "moon.zzz.fill"
        case .green: return "checkmark.circle.fill"
        case .yellow: return "exclamationmark.circle.fill"
        case .orange: return "flame.fill"
        case .red: return "exclamationmark.triangle.fill"
        }
    }

    private func colorForBand(_ band: ArousalBand) -> Color {
        Color(band.color).blend(
            with: Color(hex: spectrum.profileColor) ?? .blue,
            ratio: 0.3
        )
    }
}

// MARK: - Preview

struct BehaviorSpectrumView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mostly green
                BehaviorSpectrumView(
                    spectrum: BehaviorSpectrum(
                        profileColor: "#4A90E2",
                        shutdownPercentage: 5,
                        greenPercentage: 70,
                        yellowPercentage: 15,
                        orangePercentage: 8,
                        redPercentage: 2
                    ),
                    childName: "Alex"
                )

                // Mixed states
                BehaviorSpectrumView(
                    spectrum: BehaviorSpectrum(
                        profileColor: "#FF6B6B",
                        shutdownPercentage: 10,
                        greenPercentage: 30,
                        yellowPercentage: 25,
                        orangePercentage: 25,
                        redPercentage: 10
                    ),
                    childName: "Jamie"
                )

                // Mostly escalated
                BehaviorSpectrumView(
                    spectrum: BehaviorSpectrum(
                        profileColor: "#50C878",
                        shutdownPercentage: 0,
                        greenPercentage: 15,
                        yellowPercentage: 20,
                        orangePercentage: 45,
                        redPercentage: 20
                    ),
                    childName: "Taylor"
                )
            }
            .padding()
        }
    }
}
