//
//  TrainingVideoRecorderView.swift
//  NeuroGuide
//
//  Training video recorder interface
//

import SwiftUI
import AVFoundation

struct TrainingVideoRecorderView: View {
    @StateObject private var viewModel = TrainingVideoRecorderViewModel()
    @EnvironmentObject var navigationState: NavigationState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Camera Preview
            TrainingCameraPreviewView(session: viewModel.getCameraSession())
                .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Top Bar
                topBar

                Spacer()

                // Center Content
                if viewModel.recordingState == .countdown {
                    countdownView
                } else if viewModel.recordingState == .recording {
                    recordingIndicator
                } else if viewModel.recordingState == .review {
                    reviewControls
                }

                Spacer()

                // Bottom Controls
                if viewModel.recordingState == .idle {
                    bottomControls
                }
            }
            .padding()
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.setup()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }

            Spacer()

            // Training progress
            VStack(alignment: .trailing, spacing: 4) {
                Text("Training Progress")
                    .font(.caption)
                    .foregroundColor(.white)

                Text(viewModel.trainingProgress >= 1.0 ? "Complete!" : "\(Int(viewModel.trainingProgress * 100))%")
                    .font(.headline)
                    .foregroundColor(viewModel.isReadyToTrain ? .green : .white)
            }
            .padding(8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
        }
    }

    // MARK: - Countdown View

    private var countdownView: some View {
        VStack(spacing: 20) {
            Text("Get Ready!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("\(viewModel.countdown)")
                .font(.system(size: 120, weight: .bold))
                .foregroundColor(.white)
                .shadow(radius: 10)

            Text(viewModel.selectedArousalState.emoji)
                .font(.system(size: 80))
        }
    }

    // MARK: - Recording Indicator

    private var recordingIndicator: some View {
        VStack(spacing: 20) {
            // Recording dot
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)

                Text("RECORDING")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)

            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: viewModel.recordingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .frame(width: 200)

                Text("\(Int((1.0 - viewModel.recordingProgress) * 10))s")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)

            // Selected state
            Text("\(viewModel.selectedArousalState.emoji) \(viewModel.selectedArousalState.displayName)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
        }
    }

    // MARK: - Review Controls

    private var reviewControls: some View {
        VStack(spacing: 24) {
            Text("Review Your Recording")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("\(viewModel.selectedArousalState.emoji) \(viewModel.selectedArousalState.displayName)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(8)

            HStack(spacing: 20) {
                // Discard button
                Button(action: {
                    viewModel.discardVideo()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.title)
                        Text("Discard")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(16)
                }

                // Save button
                Button(action: {
                    Task {
                        await viewModel.saveVideo()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                        Text("Save")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(16)
                }
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.7))
        .cornerRadius(20)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Arousal state selector
            arousalStateSelector

            // Video counts
            videoCountsGrid

            // Record button
            recordButton

            // Training readiness message
            Text(viewModel.readinessMessage)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .shadow(radius: 2)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.4)]),
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    // MARK: - Arousal State Selector

    private var arousalStateSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Arousal State")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ArousalState.allCases, id: \.self) { state in
                        StateButton(
                            state: state,
                            isSelected: viewModel.selectedArousalState == state,
                            videoCount: viewModel.getVideoCount(for: state)
                        ) {
                            viewModel.selectedArousalState = state
                        }
                    }
                }
            }
        }
    }

    // MARK: - Video Counts Grid

    private var videoCountsGrid: some View {
        VStack(spacing: 8) {
            ForEach(ArousalState.allCases, id: \.self) { state in
                HStack {
                    Text("\(state.emoji) \(state.displayName)")
                        .font(.caption)
                        .foregroundColor(.white)

                    Spacer()

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))

                            Rectangle()
                                .fill(viewModel.getVideoCount(for: state) >= 10 ? Color.green : Color.blue)
                                .frame(width: geometry.size.width * viewModel.getStateProgress(for: state))
                        }
                    }
                    .frame(width: 80, height: 6)
                    .cornerRadius(3)

                    Text("\(viewModel.getVideoCount(for: state))/10")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button(action: {
            viewModel.startRecording()
        }) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 80, height: 80)

                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 90, height: 90)

                if viewModel.recordingState == .saving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
        .disabled(!viewModel.recordingState.canStartRecording)
    }
}

// MARK: - State Button

struct StateButton: View {
    let state: ArousalState
    let isSelected: Bool
    let videoCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(state.emoji)
                    .font(.title)

                Text(state.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)

                Text("\(videoCount)")
                    .font(.caption2)
                    .foregroundColor(videoCount >= 10 ? .green : .white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    Color.blue.opacity(0.8) :
                    Color.white.opacity(0.2)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.white)
    }
}

// MARK: - Training Camera Preview

struct TrainingCameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        guard let session = session else { return view }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Preview

#Preview {
    TrainingVideoRecorderView()
        .environmentObject(NavigationState.shared)
}
