//
//  DualCameraPreviewView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System (Dual Camera UI)
//

import SwiftUI
import AVFoundation

/// Dual camera preview showing child (rear) and parent (front) cameras
/// Child camera is primary view, parent camera is picture-in-picture
struct DualCameraPreviewView: View {
    let childSession: AVCaptureSession
    let parentSession: AVCaptureSession
    let childState: ArousalBand?
    let parentState: ParentState?

    @State private var parentCameraPosition: CGPoint = .zero
    @State private var parentCameraSize: CGSize = CGSize(width: 120, height: 160)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Child camera (main view)
            ChildCameraPreview(
                session: childSession,
                arousalBand: childState
            )

            // Parent camera (PiP)
            ParentCameraPiPView(
                session: parentSession,
                parentState: parentState,
                size: parentCameraSize
            )
            .offset(x: parentCameraPosition.x, y: parentCameraPosition.y)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        parentCameraPosition = CGPoint(
                            x: value.translation.width,
                            y: value.translation.height
                        )
                    }
            )
            .padding(12)
        }
    }
}

// MARK: - Child Camera Preview

/// Main camera preview for child (rear camera)
struct ChildCameraPreview: View {
    let session: AVCaptureSession
    let arousalBand: ArousalBand?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CameraPreviewView(session: session)

            // Arousal band indicator overlay
            if let band = arousalBand {
                HStack(spacing: 8) {
                    Circle()
                        .fill(colorForBand(band))
                        .frame(width: 12, height: 12)
                    Text(band.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                )
                .foregroundColor(.white)
                .padding(12)
            }
        }
    }

    private func colorForBand(_ band: ArousalBand) -> Color {
        switch band {
        case .shutdown: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        }
    }
}

// MARK: - Parent Camera PiP View

/// Picture-in-picture view for parent camera (front)
struct ParentCameraPiPView: View {
    let session: AVCaptureSession
    let parentState: ParentState?
    let size: CGSize

    var body: some View {
        VStack(spacing: 0) {
            // Camera preview
            CameraPreviewView(session: session)
                .frame(width: size.width, height: size.height)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColorForState(parentState), lineWidth: 3)
                )

            // Parent state label
            if let state = parentState {
                HStack(spacing: 4) {
                    Image(systemName: state.icon)
                        .font(.caption2)
                    Text(state.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                )
                .foregroundColor(.white)
                .offset(y: -8)
            }
        }
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private func borderColorForState(_ state: ParentState?) -> Color {
        guard let state = state else { return .white }

        switch state {
        case .calm: return .green
        case .stressed: return .yellow
        case .coRegulating: return .blue
        case .dysregulated: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
        VStack {
            Text("Dual Camera Preview")
                .foregroundColor(.white)
                .padding()

            // Mock preview
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .overlay(
                    VStack {
                        Image(systemName: "video.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Child Camera (Rear)")
                            .foregroundColor(.white.opacity(0.5))
                    }
                )
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 120, height: 160)
                            .cornerRadius(12)
                            .overlay(
                                VStack {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white.opacity(0.5))
                                    Text("Parent")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 3)
                            )

                        Text("Calm")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.7)))
                            .foregroundColor(.white)
                            .offset(y: -8)
                    }
                    .padding(12)
                }
        }
    }
}
