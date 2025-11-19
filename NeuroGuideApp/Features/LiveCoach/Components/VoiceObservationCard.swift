//
//  VoiceObservationCard.swift
//  NeuroGuide
//
//  Voice observation recording for LLM context
//

import SwiftUI
import AVFoundation
import Combine

struct VoiceObservationCard: View {
    @Binding var isRecording: Bool
    @Binding var recordedObservations: [VoiceObservation]
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void

    @State private var audioLevel: CGFloat = 0.0
    @State private var showTranscription = true  // Show by default

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isRecording ? .red : .blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Voice Observations")
                        .font(.system(size: 16, weight: .bold))
                    Text(isRecording ? "Recording..." : "Add context for better suggestions")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(recordedObservations.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.blue))
            }

            // Recording button
            Button(action: {
                if isRecording {
                    onStopRecording()
                } else {
                    onStartRecording()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        // Pulsing effect when recording
                        if isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.3))
                                .frame(width: 64, height: 64)
                                .scaleEffect(1.0 + audioLevel * 0.3)
                                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: audioLevel)
                        }

                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 56, height: 56)

                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isRecording ? "Tap to Stop" : "Tap to Record")
                            .font(.system(size: 16, weight: .semibold))
                        Text(isRecording ? "Observation will be transcribed" : "Describe what you're observing")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            // Recent observations
            if !recordedObservations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Observations")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: {
                            showTranscription.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Text(showTranscription ? "Hide" : "Show All")
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: showTranscription ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.blue)
                        }
                    }

                    if showTranscription {
                        ForEach(recordedObservations.prefix(3)) { observation in
                            observationRow(observation: observation)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if isRecording {
                // Simulate audio level (replace with actual audio level monitoring)
                withAnimation {
                    audioLevel = CGFloat.random(in: 0.3...1.0)
                }
            }
        }
        .onChange(of: recordedObservations.count) { newCount in
            // Auto-expand transcriptions when new observation added
            if newCount > 0 && !showTranscription {
                withAnimation {
                    showTranscription = true
                }
            }
        }
    }

    private func observationRow(observation: VoiceObservation) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(observation.timestamp, style: .time)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Text(observation.transcription ?? "Transcribing...")
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.08))
        )
    }
}

struct VoiceObservation: Identifiable {
    let id = UUID()
    let timestamp: Date
    let audioURL: URL?
    var transcription: String?
    var sentToLLM: Bool = false
}
