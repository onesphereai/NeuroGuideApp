//
//  LaunchScreenView.swift
//  NeuroGuide
//
//  Unit 12 - Branding & Visual Identity
//  Launch screen with Attune branding
//

import SwiftUI

/// Brief, calming launch screen shown when app opens
struct LaunchScreenView: View {
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: CGFloat = 0.9

    var body: some View {
        ZStack {
            // Background color (adapts to light/dark mode)
            Color.ngBackground
                .ignoresSafeArea()

            VStack(spacing: NGSpacing.lg) {
                // Attune logo
                Image("attune-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                // Subtle tagline (optional)
                Text("Supporting neurodivergent families")
                    .font(.ngCallout)
                    .foregroundColor(.ngTextSecondary)
                    .opacity(logoOpacity * 0.8)
            }
        }
        .onAppear {
            // Gentle fade-in animation (respects Reduce Motion)
            withAnimation(.easeOut(duration: 0.6)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    LaunchScreenView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LaunchScreenView()
        .preferredColorScheme(.dark)
}
