//
//  CameraStabilityIndicator.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-11-01.
//  Unit 5 - Live Coach (Camera Stability UI)
//

import SwiftUI

/// Subtle indicator showing camera stability status
struct CameraStabilityIndicator: View {
    let isStable: Bool
    let motionDescription: String?

    var body: some View {
        HStack(spacing: 6) {
            // Status icon
            if #available(iOS 17.0, *) {
                Image(systemName: isStable ? "camera.fill" : "camera.fill")
                    .font(.caption)
                    .foregroundColor(isStable ? .green : .orange)
                    .symbolEffect(.variableColor, isActive: !isStable)
            } else {
                // Fallback for iOS 16
                Image(systemName: isStable ? "camera.fill" : "camera.fill")
                    .font(.caption)
                    .foregroundColor(isStable ? .green : .orange)
                    .opacity(!isStable ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: !isStable)
            }

            // Status text
            Text(isStable ? "Stable" : "Adjusting...")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isStable ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(isStable ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

struct CameraStabilityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CameraStabilityIndicator(
                isStable: true,
                motionDescription: "Camera stable"
            )

            CameraStabilityIndicator(
                isStable: false,
                motionDescription: "Translation: 15.3px, Rotation: 2.1°"
            )
        }
        .padding()
    }
}
