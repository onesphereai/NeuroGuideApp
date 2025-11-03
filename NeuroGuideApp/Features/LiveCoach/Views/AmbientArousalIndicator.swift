//
//  AmbientArousalIndicator.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-31.
//  Unit 7 - Multi-Tier Arousal Display (Tier 1: Ambient Awareness)
//
//  Provides subtle, peripheral visual feedback of arousal state
//  Updates in real-time (~3 Hz) with smooth color transitions
//  NO text or numbers - pure ambient awareness
//

import SwiftUI

/// Tier 1: Ambient arousal indicator with smooth color transitions and pulse
struct AmbientArousalIndicator: View {
    let arousalBand: ArousalBand?

    @State private var pulsePhase: CGFloat = 0
    @State private var currentColor: Color = .gray

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(currentColor, lineWidth: 4)
            .opacity(baseOpacity + pulseAmplitude * CGFloat(sin(pulsePhase)))
            .scaleEffect(1.0 + scaleAmplitude * CGFloat(sin(pulsePhase)))
            .animation(.easeInOut(duration: animationDuration), value: currentColor)
            .onAppear {
                startPulseAnimation()
            }
            .onChange(of: arousalBand) { newBand in
                updateColor(for: newBand)
            }
    }

    // MARK: - Animation Parameters

    private var baseOpacity: CGFloat {
        return 0.4  // Base visibility
    }

    private var pulseAmplitude: CGFloat {
        guard let band = arousalBand else { return 0.0 }

        switch band {
        case .shutdown:
            return 0.15  // Gentle pulse
        case .green:
            return 0.0   // No pulse, steady glow
        case .yellow:
            return 0.10  // Subtle pulse
        case .orange:
            return 0.15  // Moderate pulse
        case .red:
            return 0.20  // Stronger pulse
        }
    }

    private var scaleAmplitude: CGFloat {
        guard let band = arousalBand else { return 0.0 }

        switch band {
        case .shutdown, .green:
            return 0.0   // No scale change
        case .yellow:
            return 0.01  // Very subtle
        case .orange:
            return 0.015 // Slightly more noticeable
        case .red:
            return 0.02  // Most noticeable
        }
    }

    private var animationDuration: TimeInterval {
        return arousalBand?.pulseFrequency ?? 2.0
    }

    // MARK: - Animation Logic

    private func startPulseAnimation() {
        withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
            pulsePhase = .pi * 2
        }
    }

    private func updateColor(for band: ArousalBand?) {
        withAnimation(.easeInOut(duration: 1.0)) {
            currentColor = band?.swiftUIColor ?? .gray
        }
    }
}

// MARK: - Preview

struct AmbientArousalIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            ForEach(ArousalBand.allCases, id: \.self) { band in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .frame(width: 300, height: 200)

                    AmbientArousalIndicator(arousalBand: band)
                        .frame(width: 300, height: 200)

                    Text(band.displayName)
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
