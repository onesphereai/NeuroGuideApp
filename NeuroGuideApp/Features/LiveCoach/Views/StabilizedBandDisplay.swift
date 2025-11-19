//
//  StabilizedBandDisplay.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 7 - Multi-Tier Arousal Display (Tier 2: Actionable Information)
//
//  Displays stable, actionable arousal band information
//  Only updates when band has sustained for 15-30 seconds
//  Clear text, large font, designed for conscious decision-making
//

import SwiftUI

/// Tier 2: Stabilized arousal band display with clear, actionable information
struct StabilizedBandDisplay: View {
    let band: ArousalBand?

    @State private var displayedBand: ArousalBand? = nil

    var body: some View {
        Group {
            if let displayBand = displayedBand {
                VStack(spacing: 16) {
                    // Emoji icon
                    Text(displayBand.emoji)
                        .font(.system(size: 48))

                    // Band name
                    Text(displayBand.displayName)
                        .font(.title.bold())
                        .foregroundColor(displayBand.swiftUIColor)

                    // Parent-friendly description
                    Text(displayBand.stabilizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(displayBand.swiftUIColor.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(displayBand.swiftUIColor.opacity(0.3), lineWidth: 2)
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            } else {
                // Initial state - waiting for first stabilized reading
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)

                    Text("Stabilizing readings...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .onChange(of: band) { newBand in
            // Smooth transition when band changes
            withAnimation(.easeInOut(duration: 1.0)) {
                displayedBand = newBand
            }
        }
        .onAppear {
            // Set initial band if available
            if let band = band {
                displayedBand = band
            }
        }
    }
}

// MARK: - Compact Variant (for smaller screens)

struct StabilizedBandDisplayCompact: View {
    let band: ArousalBand?

    @State private var displayedBand: ArousalBand? = nil

    var body: some View {
        Group {
            if let displayBand = displayedBand {
                HStack(spacing: 12) {
                    // Emoji
                    Text(displayBand.emoji)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        // Band name
                        Text(displayBand.displayName)
                            .font(.headline)
                            .foregroundColor(displayBand.swiftUIColor)

                        // Brief description
                        Text(displayBand.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(displayBand.swiftUIColor.opacity(0.1))
                )
                .transition(.opacity)
            } else {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Stabilizing readings...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .onChange(of: band) { newBand in
            withAnimation(.easeInOut(duration: 1.0)) {
                displayedBand = newBand
            }
        }
        .onAppear {
            if let band = band {
                displayedBand = band
            }
        }
    }
}

// MARK: - Preview

struct StabilizedBandDisplay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Full size preview
            VStack(spacing: 20) {
                ForEach(ArousalBand.allCases, id: \.self) { band in
                    StabilizedBandDisplay(band: band)
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Full Size")

            // Compact preview
            VStack(spacing: 20) {
                ForEach(ArousalBand.allCases, id: \.self) { band in
                    StabilizedBandDisplayCompact(band: band)
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Compact")

            // Nil state
            VStack(spacing: 20) {
                StabilizedBandDisplay(band: nil)
                StabilizedBandDisplayCompact(band: nil)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Nil State")
        }
    }
}
