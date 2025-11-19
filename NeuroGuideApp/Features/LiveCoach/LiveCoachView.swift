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
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var lastSpokenSuggestion: String?
    @State private var showAnalyticsSheet = false
    @EnvironmentObject var navigationState: NavigationState

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
                            .foregroundColor(viewModel.isSessionActive ? .primary : .white)
                        }
                        .accessibilityLabel("Back to Home")
                    }
                }
                .toolbarBackground(viewModel.isSessionActive ? .visible : .hidden, for: .navigationBar)
                .toolbarColorScheme(viewModel.isSessionActive ? .light : .dark, for: .navigationBar)
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
    }

    // MARK: - Start Session View

    private func startSessionView(viewModel: LiveCoachViewModel) -> some View {
        ZStack {
            // Purple gradient background
            LinearGradient(
                colors: [
                    Color.ngBackgroundGradientTop,
                    Color.ngBackgroundGradientBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon with modern styling
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 120, height: 120)

                    Image(systemName: "figure.walk")
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Title
                VStack(spacing: 12) {
                    if let childName = viewModel.childName {
                        Text("Ready to Start a Session with \(childName)?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else {
                        Text("Ready to Start a Session?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Description
                    Text("The Live Coach will provide real-time guidance based on your child's current state.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

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
                    HStack(spacing: 12) {
                        if viewModel.isStarting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .ngIconForeground))
                        } else {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        Text(viewModel.isStarting ? "Starting..." : "Start Session")
                            .font(.headline)
                    }
                    .foregroundColor(.ngIconForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                }
                .disabled(viewModel.isStarting)
                .padding(.horizontal, 32)

                Spacer()

                // Permission info
                permissionInfoView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Active Session View

    private func activeSessionView(viewModel: LiveCoachViewModel) -> some View {
        ZStack {
            // Purple gradient background
            LinearGradient(
                colors: [
                    Color.ngBackgroundGradientTop,
                    Color.ngBackgroundGradientBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
            // Session header
            sessionHeaderView(viewModel: viewModel)

            // Main content area - MODERNIZED UI
            ScrollView(showsIndicators: false) {
                VStack(spacing: viewModel.isGeneratingSuggestion ? 8 : 12) {
                    // 1. MODERN DUAL CAMERA SECTION - Picture-in-Picture (FaceTime style)
                    if viewModel.isCameraActive {
                        if viewModel.isDualCameraMode,
                           let childSession = viewModel.getCaptureSession(),
                           let parentSession = viewModel.getParentCaptureSession() {
                            // FaceTime-style PiP: Large child camera with small parent overlay
                            ZStack(alignment: .topLeading) {
                                // Main view: Child camera (rear camera)
                                ModernCameraCard(
                                    session: childSession,
                                    title: "Child Camera",
                                    emotionalState: viewModel.childEmotionalState,
                                    arousalBand: viewModel.currentArousalBand,
                                    confidence: viewModel.currentConfidence,
                                    featureVisualization: viewModel.currentFeatureVisualization,
                                    showStability: true,
                                    stabilityInfo: (
                                        isStable: viewModel.isCameraStable,
                                        motion: nil
                                    ),
                                    isPersonDetected: viewModel.isPersonDetected
                                )
                                .frame(height: 400)

                                // Overlay: Parent camera (front camera) - fixed at bottom right INSIDE child camera
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        ModernCameraCard(
                                            session: parentSession,
                                            title: "Parent",
                                            emotionalState: viewModel.parentEmotionalState,
                                            arousalBand: nil,
                                            confidence: nil,
                                            featureVisualization: nil,
                                            showStability: false,
                                            stabilityInfo: nil,
                                            isPersonDetected: true  // Parent camera less critical
                                        )
                                        .frame(width: 120, height: 160)
                                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                }
                                .padding(12)
                            }
                            .padding(.horizontal)
                        } else if let session = viewModel.getCaptureSession() {
                            // Single camera mode
                            ModernCameraCard(
                                session: session,
                                title: "Child Camera",
                                emotionalState: viewModel.childEmotionalState,
                                arousalBand: viewModel.currentArousalBand,
                                confidence: viewModel.currentConfidence,
                                featureVisualization: viewModel.currentFeatureVisualization,
                                showStability: true,
                                stabilityInfo: (
                                    isStable: viewModel.isCameraStable,
                                    motion: nil
                                ),
                                isPersonDetected: viewModel.isPersonDetected
                            )
                            .frame(height: 400)
                            .padding(.horizontal)
                        }
                    }

                    // AI Generation Indicator - shows when generating suggestions
                    if viewModel.isGeneratingSuggestion {
                        AIGenerationIndicator()
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .scale))
                    }

                    // 2. DUAL SUGGESTION CARDS (Child + Parent) with Feedback & Resources
                    if let childSuggestion = viewModel.childSuggestion {
                        VStack(spacing: 12) {
                            // Child Care Suggestion
                            ModernSuggestionCard(
                                suggestion: childSuggestion,
                                onFeedback: { isPositive in
                                    Task {
                                        await viewModel.recordSuggestionFeedback(helpful: isPositive)
                                    }
                                }
                            )
                            .onAppear {
                                speakSuggestion(childSuggestion.text)
                            }
                            .onChange(of: childSuggestion.text) { newText in
                                speakSuggestion(newText)
                            }

                            // Parent Care Suggestion
                            if let parentSuggestion = viewModel.parentSuggestion {
                                ModernSuggestionCard(
                                    suggestion: parentSuggestion,
                                    onFeedback: { isPositive in
                                        Task {
                                            await viewModel.recordSuggestionFeedback(helpful: isPositive)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 3. VOICE OBSERVATION SECTION
                    VoiceObservationCard(
                        isRecording: $viewModel.isRecordingVoice,
                        recordedObservations: $viewModel.voiceObservations,
                        onStartRecording: {
                            viewModel.startVoiceObservation()
                        },
                        onStopRecording: {
                            Task {
                                await viewModel.stopVoiceObservation()
                            }
                        }
                    )
                    .padding(.horizontal)

                    // 4. CO-REGULATION SUMMARY - Hidden per user request
                    // CoRegulationSummaryCard(
                    //     eventsCount: viewModel.coRegulationEventsCount,
                    //     successRate: viewModel.getCoRegulationStats().successRate,
                    //     latestEvent: viewModel.latestCoRegulationEvent
                    // )
                    // .padding(.horizontal)

                    // 5. VIEW DETAILS BUTTON - Opens analytics sheet
                    if viewModel.currentFeatureVisualization != nil {
                        Button(action: {
                            showAnalyticsSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("View Detailed Analytics")
                                    .font(.system(size: 15, weight: .semibold))

                                Spacer()

                                Image(systemName: "chevron.up")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.blue)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            // Bottom controls
            sessionControlsView(viewModel: viewModel)
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isGeneratingSuggestion)
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
        .sheet(isPresented: $showAnalyticsSheet) {
            analyticsSheetView
        }
    }

    // MARK: - Analytics Sheet View

    private var analyticsSheetView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let features = viewModel.currentFeatureVisualization {
                        // Header
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text("Detailed Analytics")
                                    .font(.system(size: 24, weight: .bold))
                            }

                            Text("Real-time ML detection data")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)

                        // Feature Visualization Panel (always expanded in sheet)
                        FeatureVisualizationPanel(features: features)
                            .padding(.horizontal)

                        // Privacy note
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("On-Device Processing")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("All analysis happens on your device. Nothing is uploaded.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAnalyticsSheet = false
                    }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
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
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Text(viewModel.sessionDuration)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
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
                        .foregroundColor(.white)
                }

                // End session button
                Button(action: {
                    showEndSessionConfirmation = true
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)

            // Degradation mode banner
            if let mode = viewModel.degradationMode {
                degradationModeBanner(mode: mode)
            }
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
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

                    // Camera Stability Indicator (left side)
                    HStack {
                        VStack {
                            CameraStabilityIndicator(
                                isStable: viewModel.isCameraStable,
                                motionDescription: viewModel.cameraMotionDescription
                            )
                            .padding(.leading, 12)
                            .padding(.top, 12)
                            Spacer()
                        }
                        Spacer()
                    }
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

                // Camera Stability Indicator (left side of child camera)
                HStack {
                    VStack {
                        CameraStabilityIndicator(
                            isStable: viewModel.isCameraStable,
                            motionDescription: viewModel.cameraMotionDescription
                        )
                        .padding(.leading, 12)
                        .padding(.top, 12)
                        Spacer()
                    }
                    Spacer()
                }
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
            HStack {
                Text("Suggestion")
                    .font(.headline)

                Spacer()

                // Speaker icon to indicate audio is playing
                if speechSynthesizer.isSpeaking {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Speaking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Show only the first suggestion
            if let firstSuggestion = viewModel.suggestionsWithResources.first {
                suggestionCardWithResource(suggestion: firstSuggestion)
                    .onAppear {
                        speakSuggestion(firstSuggestion.text)
                    }
                    .onChange(of: firstSuggestion.text) { newText in
                        speakSuggestion(newText)
                    }
            }
        }
    }

    // MARK: - Text-to-Speech

    private func speakSuggestion(_ text: String) {
        // Don't repeat the same suggestion
        guard text != lastSpokenSuggestion else { return }

        // Stop any ongoing speech
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        // Create speech utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5  // Slightly slower for clarity
        utterance.volume = 0.8

        // Speak the suggestion
        speechSynthesizer.speak(utterance)
        lastSpokenSuggestion = text

        print("🔊 Speaking suggestion: \(text)")
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
                .background(.white.opacity(0.3))

            HStack {
                // Duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session Duration")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(viewModel.sessionDuration)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                Spacer()

                // Suggestions count
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Suggestions")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(viewModel.suggestionsCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Permission Info

    private func permissionInfoView(viewModel: LiveCoachViewModel) -> some View {
        VStack(spacing: 12) {
            Text("Permissions")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

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
                .foregroundColor(status == .granted ? .white : .white.opacity(0.5))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.2))
        .cornerRadius(8)
    }

    // MARK: - Degradation Mode

    private func degradationModeNotice(mode: DegradationMode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text("Limited Mode")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(mode.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding()
        .background(.white.opacity(0.2))
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
        .background(.white.opacity(0.2))
        .foregroundColor(.white)
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

// MARK: - AI Generation Indicator

/// Animated indicator showing when AI is generating suggestions
struct AIGenerationIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            // Animated sparkles icon with gradient and pulsing effect
            ZStack {
                // Background circle with pulse
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.5 : 1.0)

                // AI sparkles icon with rotating animation
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Analyzing...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Generating personalized suggestions")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Loading dots animation
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 6, height: 6)
                        .opacity(isAnimating ? 0.3 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.blue.opacity(0.15), radius: 12, x: 0, y: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LiveCoachView()
}
