//
//  LiveCoachView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 5 - Live Coach System
//

import SwiftUI
import AVFoundation

/// Main view for live coaching sessions
/// Allows starting/ending sessions and displays real-time coaching
struct LiveCoachView: View {
    @StateObject private var viewModel = LiveCoachViewModel()
    @State private var showEndSessionConfirmation = false
    @State private var sessionNotes = ""
    @State private var showAddObservation = false
    @State private var observationText = ""
    @EnvironmentObject var navigationState: NavigationState

    // Unit 9: Baseline alert message
    private var baselineAlertMessage: String {
        "Your child's baseline is \(viewModel.baselineDaysOld) days old. For best accuracy, we recommend recalibrating every 30 days as your child grows and changes.\n\nYou can continue with the current baseline or recalibrate now (takes 45 seconds)."
    }

    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Live Coach")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            navigationState.push(.home)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Home")
                            }
                        }
                        .accessibilityLabel("Back to Home")
                    }
                }
                .onAppear {
                    viewModel.setup()
                }
        }
        .navigationViewStyle(.stack)
    }

    private var mainContent: some View {
        Group {
            ZStack {
                if viewModel.isSessionActive {
                    // Active session view
                    activeSessionView(viewModel: viewModel)
                } else {
                    // Start session view
                    startSessionView(viewModel: viewModel)
                }
            }
        }
        .alert("End Session?", isPresented: $showEndSessionConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("End Session", role: .destructive) {
                            Task {
                                await viewModel.endSession(notes: sessionNotes.isEmpty ? nil : sessionNotes)
                                sessionNotes = ""
                            }
                        }
                    } message: {
                        Text("Are you sure you want to end this session?")
                    }
                    .alert("Error", isPresented: Binding(
                        get: { viewModel.errorMessage != nil },
                        set: { if !$0 { viewModel.errorMessage = nil } }
                    )) {
                        Button("OK", role: .cancel) {
                            viewModel.errorMessage = nil
                        }
                    } message: {
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                        }
                    }
                    .alert("Baseline Needs Updating", isPresented: $viewModel.showBaselineStaleAlert) {
                        Button("Continue Anyway", role: .cancel) {
                            viewModel.continueWithStaleBaseline()
                        }
                        Button("Recalibrate Now") {
                            viewModel.requestRecalibration()
                            // Present profile detail modal if profile exists
                            if let profile = viewModel.currentProfile {
                                navigationState.presentedModal = .profileDetail(profile: profile)
                            }
                        }
                    } message: {
                        Text(baselineAlertMessage)
                    }
    }

    // MARK: - Start Session View

    private func startSessionView(viewModel: LiveCoachViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Title
            if let childName = viewModel.childName {
                Text("Ready to Start a Session with \(childName)?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("Ready to Start a Session?")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            // Description
            Text("The Live Coach will provide real-time guidance based on your child's current state.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Permission status
            if let degradationMode = viewModel.degradationMode {
                degradationModeNotice(mode: degradationMode)
            }

            // Start button
            Button(action: {
                Task {
                    await viewModel.startSession()
                }
            }) {
                HStack {
                    if viewModel.isStarting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    Text(viewModel.isStarting ? "Starting..." : "Start Session")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(viewModel.isStarting)
            .padding(.horizontal, 32)

            Spacer()

            // Permission info
            permissionInfoView(viewModel: viewModel)
        }
    }

    // MARK: - Active Session View

    private func activeSessionView(viewModel: LiveCoachViewModel) -> some View {
        ZStack {
            VStack(spacing: 0) {
            // Session header
            sessionHeaderView(viewModel: viewModel)

            // Main content area
            ScrollView {
                VStack(spacing: 16) {
                    // Camera preview (dual or single)
                    if viewModel.isCameraActive {
                        if viewModel.isDualCameraMode,
                           let childSession = viewModel.getCaptureSession(),
                           let parentSession = viewModel.getParentCaptureSession() {
                            dualCameraPreviewSection(
                                childSession: childSession,
                                parentSession: parentSession,
                                viewModel: viewModel
                            )
                        } else if let session = viewModel.getCaptureSession() {
                            cameraPreviewSection(session: session, viewModel: viewModel)
                        }
                    }

                    // Unit 7: Tier 2 - Stabilized arousal band display
                    StabilizedBandDisplay(band: viewModel.stabilizedArousalBand)

                    // Unit 8: Co-Regulation Summary
                    CoRegulationSummaryCard(
                        eventsCount: viewModel.coRegulationEventsCount,
                        successRate: viewModel.getCoRegulationStats().successRate,
                        latestEvent: viewModel.latestCoRegulationEvent
                    )

                    // Movement and behaviors
                    if let movement = viewModel.currentMovementEnergy {
                        movementStatusCard(movement: movement, behaviors: viewModel.detectedBehaviors)
                    }

                    // Current emotion state (if emotion interface enabled)
                    if viewModel.isEmotionInterfaceEnabled, let emotionState = viewModel.currentEmotionState {
                        emotionStateSection(classification: emotionState)
                    }

                    // Coaching suggestions
                    if !viewModel.suggestionsWithResources.isEmpty {
                        coachingSuggestionsSection(viewModel: viewModel)
                    }

                    // Quick observations
                    quickObservationsSection(viewModel: viewModel)
                }
                .padding()
            }

            // Bottom controls
            sessionControlsView(viewModel: viewModel)
            }

            // Camera Stability Indicator (top-right overlay)
            if viewModel.isCameraActive {
                VStack {
                    HStack {
                        Spacer()
                        CameraStabilityIndicator(
                            isStable: viewModel.isCameraStable,
                            motionDescription: viewModel.cameraMotionDescription
                        )
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
            }

            // Unit 8: Co-Regulation Celebration Overlay
            if viewModel.showCoRegulationCelebration,
               let event = viewModel.latestCoRegulationEvent {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)

                CoRegulationCelebrationView(event: event)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showCoRegulationCelebration)
        .sheet(item: Binding(
            get: { viewModel.validationPrompt },
            set: { _ in }
        )) { prompt in
            EmotionValidationView(
                prompt: prompt,
                onValidation: { actualEmotion in
                    Task {
                        await viewModel.submitValidation(for: prompt, actual: actualEmotion)
                    }
                },
                onSkip: {
                    viewModel.skipValidation()
                }
            )
        }
    }

    // MARK: - Session Header

    private func sessionHeaderView(viewModel: LiveCoachViewModel) -> some View {
        VStack(spacing: 8) {
            HStack {
                // Session state indicator with child name
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        if let childName = viewModel.childName {
                            Text(childName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(viewModel.sessionDuration)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                    }
                }

                Spacer()

                // Pause/Resume button
                Button(action: {
                    Task {
                        await viewModel.togglePause()
                    }
                }) {
                    Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.title2)
                }

                // End session button
                Button(action: {
                    showEndSessionConfirmation = true
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)

            // Degradation mode banner
            if let mode = viewModel.degradationMode {
                degradationModeBanner(mode: mode)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 2)
    }

    // MARK: - Camera Preview

    private func cameraPreviewSection(session: AVFoundation.AVCaptureSession, viewModel: LiveCoachViewModel) -> some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(.blue)
                    Text("Live Camera")
                        .font(.headline)
                    Spacer()
                    if let confidence = viewModel.currentConfidence {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Detecting")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                ZStack {
                    CameraPreviewView(session: session)
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.6)
                        .aspectRatio(4/3, contentMode: .fit)
                        .cornerRadius(12)

                    // Unit 7: Tier 1 - Ambient arousal indicator overlay
                    AmbientArousalIndicator(arousalBand: viewModel.currentArousalBand)
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.6)
                        .aspectRatio(4/3, contentMode: .fit)
                }
            }
        }
        .frame(minHeight: 400)
    }

    private func dualCameraPreviewSection(
        childSession: AVFoundation.AVCaptureSession,
        parentSession: AVFoundation.AVCaptureSession,
        viewModel: LiveCoachViewModel
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.blue)
                Text("Dual Camera")
                    .font(.headline)
                Spacer()
                HStack(spacing: 12) {
                    if viewModel.currentConfidence != nil {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Child")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if viewModel.parentConfidence != nil {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("Parent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            ZStack {
                DualCameraPreviewView(
                    childSession: childSession,
                    parentSession: parentSession,
                    childState: viewModel.currentArousalBand,
                    parentState: viewModel.currentParentState
                )
                .frame(height: 300)
                .cornerRadius(12)

                // Unit 7: Tier 1 - Ambient arousal indicator overlay
                AmbientArousalIndicator(arousalBand: viewModel.currentArousalBand)
                    .frame(height: 300)
            }
        }
    }

    // MARK: - Current Arousal Band

    private func currentArousalBandCard(arousalBand: ArousalBand, viewModel: LiveCoachViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current State")
                    .font(.headline)
                Spacer()
                if let confidence = viewModel.currentConfidence {
                    Text("\(Int(confidence * 100))% confident")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                Circle()
                    .fill(colorForArousalBand(arousalBand))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(arousalBand.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(arousalBand.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Movement Status

    private func movementStatusCard(movement: MovementEnergy, behaviors: [ChildBehavior]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Movement & Behavior")
                .font(.headline)

            // Movement energy
            HStack(spacing: 12) {
                Image(systemName: movementIcon(for: movement))
                    .font(.system(size: 24))
                    .foregroundColor(movementColor(for: movement))
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(movementDisplayName(for: movement))
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Movement Energy Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Detected behaviors
            if !behaviors.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Observed Behaviors")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(behaviors.prefix(3), id: \.self) { behavior in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 6, height: 6)
                            Text(behavior.displayName)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Emotion State

    private func emotionStateSection(classification: EmotionClassification) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emotion Detection")
                .font(.headline)

            EmotionStateCard(classification: classification)
        }
    }

    // MARK: - Coaching Suggestions

    private func coachingSuggestionsSection(viewModel: LiveCoachViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestions")
                .font(.headline)

            ForEach(Array(viewModel.suggestionsWithResources.enumerated()), id: \.offset) { index, suggestionWithResource in
                suggestionCardWithResource(suggestion: suggestionWithResource)
            }
        }
    }

    private func suggestionCardWithResource(suggestion: CoachingSuggestionWithResource) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(suggestion.text)
                .font(.body)

            HStack(spacing: 12) {
                Button(action: {
                    // Mark as helpful
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Helpful")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }

                Button(action: {
                    // Mark as not helpful
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsdown.fill")
                        Text("Not Helpful")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Learn More button (if resource available)
                if let resourceTitle = suggestion.resourceTitle,
                   let resourceURL = suggestion.resourceURL,
                   let url = URL(string: resourceURL) {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                            Text("Learn More")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func suggestionCard(suggestion: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(suggestion)
                .font(.body)

            HStack {
                Button(action: {
                    // Mark as helpful
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Helpful")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }

                Button(action: {
                    // Mark as not helpful
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsdown.fill")
                        Text("Not Helpful")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Quick Observations

    private func quickObservationsSection(viewModel: LiveCoachViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Observations")
                .font(.headline)

            Button(action: {
                showAddObservation = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Observation")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
            .sheet(isPresented: $showAddObservation) {
                addObservationSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Add Observation Sheet

    private func addObservationSheet(viewModel: LiveCoachViewModel) -> some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Observation")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextField("Describe what you're observing...", text: $observationText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .padding(.horizontal)
                }

                // Quick suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            quickObservationButton("Child seems calm", icon: "checkmark.circle")
                            quickObservationButton("Child appears frustrated", icon: "exclamationmark.triangle")
                            quickObservationButton("Child is focused", icon: "eye")
                            quickObservationButton("Transition difficulty", icon: "arrow.left.arrow.right")
                            quickObservationButton("Sensory seeking", icon: "hand.raised")
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Add Observation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        observationText = ""
                        showAddObservation = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addQuickObservation(description: observationText)
                            observationText = ""
                            showAddObservation = false
                        }
                    }
                    .disabled(observationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func quickObservationButton(_ text: String, icon: String) -> some View {
        Button(action: {
            observationText = text
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(text)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session Controls

    private func sessionControlsView(viewModel: LiveCoachViewModel) -> some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                // Duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.sessionDuration)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                }

                Spacer()

                // Suggestions count
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.suggestionsCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Permission Info

    private func permissionInfoView(viewModel: LiveCoachViewModel) -> some View {
        VStack(spacing: 8) {
            Text("Permissions")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                permissionBadge(
                    icon: "video.fill",
                    name: "Camera",
                    status: viewModel.cameraStatus
                )

                permissionBadge(
                    icon: "mic.fill",
                    name: "Microphone",
                    status: viewModel.microphoneStatus
                )
            }
        }
        .padding(.bottom, 32)
    }

    private func permissionBadge(icon: String, name: String, status: PermissionStatus) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(name)
                .font(.caption)
            Image(systemName: status == .granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(status == .granted ? .green : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Degradation Mode

    private func degradationModeNotice(mode: DegradationMode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Limited Mode")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(mode.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 32)
    }

    private func degradationModeBanner(mode: DegradationMode) -> some View {
        HStack(spacing: 8) {
            Image(systemName: mode.icon)
                .font(.caption)
            Text(mode.description)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.2))
        .foregroundColor(.orange)
        .cornerRadius(8)
    }

    // MARK: - Helper Methods

    private func colorForArousalBand(_ band: ArousalBand) -> Color {
        switch band {
        case .shutdown:
            return Color.blue
        case .green:
            return Color.green
        case .yellow:
            return Color.yellow
        case .orange:
            return Color.orange
        case .red:
            return Color.red
        }
    }

    private func movementIcon(for energy: MovementEnergy) -> String {
        switch energy {
        case .low:
            return "tortoise.fill"
        case .moderate:
            return "figure.walk"
        case .high:
            return "figure.run"
        }
    }

    private func movementColor(for energy: MovementEnergy) -> Color {
        switch energy {
        case .low:
            return Color.blue
        case .moderate:
            return Color.green
        case .high:
            return Color.orange
        }
    }

    private func movementDisplayName(for energy: MovementEnergy) -> String {
        switch energy {
        case .low:
            return "Low Energy"
        case .moderate:
            return "Moderate Energy"
        case .high:
            return "High Energy"
        }
    }
}

// MARK: - Preview

#Preview {
    LiveCoachView()
}
