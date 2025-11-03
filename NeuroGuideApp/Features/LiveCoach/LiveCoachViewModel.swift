//
//  LiveCoachViewModel.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 5 - Live Coach System
//

import Foundation
import AVFoundation
import CoreImage
import Combine
import UIKit

/// ViewModel for LiveCoachView
/// Manages session state and user interactions
@MainActor
class LiveCoachViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isSessionActive = false
    @Published private(set) var isStarting = false
    @Published private(set) var isPaused = false
    @Published private(set) var sessionDuration = "0:00"
    @Published private(set) var currentArousalBand: ArousalBand?  // Tier 1: Real-time (3 Hz)
    @Published private(set) var stabilizedArousalBand: ArousalBand?  // Tier 2: Stabilized (15-30s)
    @Published private(set) var currentConfidence: Double?
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var suggestionsWithResources: [CoachingSuggestionWithResource] = []
    @Published private(set) var suggestionsCount = 0
    @Published private(set) var degradationMode: DegradationMode?
    @Published private(set) var cameraStatus: PermissionStatus = .notDetermined
    @Published private(set) var microphoneStatus: PermissionStatus = .notDetermined
    @Published private(set) var childName: String?
    @Published var errorMessage: String?
    @Published private(set) var isCameraActive = false
    @Published private(set) var currentParentState: ParentState?
    @Published private(set) var parentConfidence: Double?
    @Published private(set) var isDualCameraMode = false
    @Published private(set) var currentEmotionState: EmotionClassification?
    @Published private(set) var isEmotionInterfaceEnabled = false
    @Published private(set) var validationPrompt: ValidationPrompt?
    @Published private(set) var currentMovementEnergy: MovementEnergy?
    @Published private(set) var detectedBehaviors: [ChildBehavior] = []

    // Camera Stabilization Status
    @Published private(set) var isCameraStable: Bool = true
    @Published private(set) var cameraMotionDescription: String?

    // Unit 8: Co-Regulation Feedback
    @Published private(set) var latestCoRegulationEvent: CoRegulationEvent?
    @Published private(set) var coRegulationEventsCount: Int = 0
    @Published private(set) var showCoRegulationCelebration: Bool = false

    // Unit 9: Baseline Staleness Check
    @Published var showBaselineStaleAlert: Bool = false
    @Published private(set) var baselineDaysOld: Int = 0
    private var bypassStaleBaselineCheck: Bool = false

    // MARK: - Private Properties

    private lazy var sessionManager: LiveCoachService = LiveCoachSessionManager.shared
    private lazy var permissionsService: PermissionsService = PermissionsManager.shared
    private lazy var cameraService: CameraCaptureService = CameraCaptureService.shared
    private lazy var dualCameraManager: DualCameraManager = DualCameraManager.shared
    private lazy var audioCapture: AudioCaptureService = AudioCaptureService.shared
    private lazy var mlIntegration: LiveCoachMLIntegration = LiveCoachMLIntegration.shared
    private lazy var coRegulationDetector = CoRegulationDetector()
    private lazy var contentLibrary: ContentLibraryService = ContentLibraryManager.shared
    private lazy var profileService: ChildProfileService = ChildProfileManager.shared
    private lazy var emotionClassifier: EmotionStateClassifier = EmotionStateClassifier.shared
    private lazy var emotionInterface: EmotionInterfaceManager = EmotionInterfaceManager.shared
    private lazy var validationManager: ValidationManager = ValidationManager.shared
    private lazy var settingsManager: SettingsManager = SettingsManager()
    private lazy var recordingManager: SessionRecordingManager = SessionRecordingManager.shared
    private lazy var bandStabilizer = StabilizedBandTracker(sustainThreshold: 20.0)  // Unit 7: Multi-tier display
    private var cancellables = Set<AnyCancellable>()
    private var durationTask: Task<Void, Never>?
    private var detectionTask: Task<Void, Never>?
    private var isProcessingFrame = false
    private var isProcessingParentFrame = false

    // Frame skipping for memory management (process every Nth frame)
    private var frameCounter: Int = 0
    private let frameSkipInterval: Int = 10  // Process every 10th frame (~3fps instead of 30fps) - aggressive memory saving

    // Audio buffer management
    private var latestAudioBuffer: AVAudioPCMBuffer?
    private var audioBufferLock = NSLock()

    // Current child profile
    // Unit 9: Expose profile for navigation to recalibration
    private(set) var currentProfile: ChildProfile?

    // MARK: - Initialization

    init() {
        // Empty init - services are initialized lazily when first accessed
    }

    // Setup method to be called after view appears
    func setup() {
        setupObservers()
        updatePermissionStatus()
        loadChildProfile()
    }

    // MARK: - Session Management

    func startSession() async {
        isStarting = true
        errorMessage = nil
        defer { isStarting = false }

        // Ensure we have a child profile
        guard let profile = currentProfile else {
            errorMessage = "Please create a child profile first."
            print("❌ No child profile found. Please create a profile first.")
            return
        }

        // Unit 9: Check if baseline needs recalibration (blocking unless bypassed)
        if !bypassStaleBaselineCheck && profile.needsCalibration() {
            let daysOld = getDaysOld(profile.baselineCalibration?.calibratedAt)
            baselineDaysOld = daysOld

            if daysOld > 30 {
                print("⚠️ Baseline is \(daysOld) days old - showing recalibration prompt")
                showBaselineStaleAlert = true
                // Block session start - wait for user decision
                return
            } else if profile.baselineCalibration == nil {
                print("⚠️ No baseline calibration found - using defaults")
            }
        } else if bypassStaleBaselineCheck {
            print("ℹ️ User chose to continue with stale baseline")
            bypassStaleBaselineCheck = false // Reset for next time
        }

        // Request permissions if not yet determined
        if cameraStatus == .notDetermined || microphoneStatus == .notDetermined {
            print("📱 Requesting camera and microphone permissions...")
            let (cameraGranted, micGranted) = await permissionsService.requestAllPermissions()
            print("📹 Camera: \(cameraGranted ? "granted" : "denied")")
            print("🎤 Microphone: \(micGranted ? "granted" : "denied")")
        }

        do {
            let session = try await sessionManager.startSession(childID: profile.id)
            isSessionActive = true
            degradationMode = session.degradedMode
            startDurationTimer()

            // Reset camera stabilization for new session
            mlIntegration.resetStabilization()

            // Setup audio capture if microphone permission granted
            if microphoneStatus == .granted {
                try await setupAudioCapture()
            } else {
                print("⚠️ Microphone permission not granted - audio analysis disabled")
            }

            // Check Live Coach mode
            let isRecordFirstMode = settingsManager.liveCoachMode == .recordFirst

            // Setup camera if permissions granted and not in simulator
            #if targetEnvironment(simulator)
            // Always use simulated detection in simulator (no camera available)
            if isRecordFirstMode {
                print("📱 Running in simulator - record-first mode not supported, using simulated detection")
            }
            startSimulatedDetection()
            print("📱 Running in simulator - using simulated detection")
            #else
            // On real device, use camera if available
            if cameraStatus == .granted {
                // Check if dual camera is supported
                if DualCameraManager.supportsMultiCam() {
                    print("📱 Device supports dual camera")
                    if isRecordFirstMode {
                        print("🎬 Starting in record-first mode")
                        try await startDualCameraRecording()
                    } else {
                        print("⚡ Starting in real-time mode")
                        try await startDualCameraDetection()
                    }
                } else {
                    print("📱 Device does not support dual camera - using single camera")
                    try await startCameraDetection()
                }
            } else {
                startSimulatedDetection()
            }
            #endif

            print("✅ Session started successfully for \(profile.name)")
        } catch {
            errorMessage = "Unable to start session. Please try again."
            print("❌ Failed to start session: \(error)")
        }
    }

    func endSession(notes: String?) async {
        do {
            // Stop detection
            stopDetection()

            try await sessionManager.endSession(notes: notes)
            isSessionActive = false
            isPaused = false
            stopDurationTimer()
            resetSessionData()
            errorMessage = nil

            print("✅ Session ended successfully")
        } catch {
            errorMessage = "Failed to end session properly. Session data may not be saved."
            print("❌ Failed to end session: \(error)")
        }
    }

    func togglePause() async {
        do {
            if isPaused {
                try await sessionManager.resumeSession()
                isPaused = false
                errorMessage = nil
            } else {
                try await sessionManager.pauseSession()
                isPaused = true
                errorMessage = nil
            }
        } catch {
            errorMessage = "Failed to \(isPaused ? "resume" : "pause") session."
            print("❌ Failed to toggle pause: \(error)")
        }
    }

    // MARK: - Observations

    func addQuickObservation(description: String) async {
        do {
            try await sessionManager.addObservation(
                description: description,
                arousalBand: currentArousalBand,
                emotionState: nil
            )
            print("✅ Added observation: \(description)")
        } catch {
            print("❌ Failed to add observation: \(error)")
        }
    }

    // MARK: - Emotion Validation

    func submitValidation(for prompt: ValidationPrompt, actual: EmotionLabel) async {
        guard let childID = currentProfile?.id else { return }

        do {
            try await validationManager.submitValidation(
                predicted: prompt.classification.primary,
                actual: actual,
                childID: childID
            )
            print("✅ Emotion validation submitted")
        } catch {
            print("❌ Failed to submit validation: \(error)")
        }

        // Clear the prompt
        validationPrompt = nil
    }

    func skipValidation() {
        validationPrompt = nil
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe session changes
        sessionManager.sessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.handleSessionUpdate(session)
            }
            .store(in: &cancellables)

        // Observe permission changes
        permissionsService.permissionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePermissionStatus()
            }
            .store(in: &cancellables)

        // Observe memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("⚠️ Memory warning received - clearing caches")
            self?.handleMemoryWarning()
        }
    }

    private func handleSessionUpdate(_ session: LiveCoachSession?) {
        guard let session = session else {
            isSessionActive = false
            return
        }

        isSessionActive = session.isActive
        isPaused = (session.sessionState == .paused)
        degradationMode = session.degradedMode
        suggestionsCount = session.suggestionsDelivered.count

        // Update current arousal band
        if let reading = session.arousalBandHistory.last {
            updateArousalBand(reading.arousalBand)  // Unit 7: Multi-tier update
            currentConfidence = reading.confidence
        }

        // TODO: Generate suggestions based on arousal band (Unit 5 - US-010)
        // For now, show placeholder suggestions
        if session.isActive && suggestions.isEmpty {
            generatePlaceholderSuggestions()
        }
    }

    private func updatePermissionStatus() {
        cameraStatus = permissionsService.cameraStatus
        microphoneStatus = permissionsService.microphoneStatus
        degradationMode = permissionsService.getDegradationMode()
    }

    private func loadChildProfile() {
        Task { @MainActor in
            do {
                currentProfile = try await profileService.getProfile()
                childName = currentProfile?.name

                // Check emotion interface status
                isEmotionInterfaceEnabled = emotionInterface.isEnabled

                // Configure ML integration with child profile for diagnosis-aware detection
                mlIntegration.setChildProfile(currentProfile)

                // Configure coaching engine with child name for LLM personalization
                mlIntegration.configureCoaching(childName: childName, useLLM: true)

                // Configure arousal classifier with baseline calibration for personalized thresholds
                if let profile = currentProfile {
                    ArousalBandClassifier.shared.setBaselineCalibration(profile.baselineCalibration)

                    if profile.baselineCalibration != nil {
                        print("✅ Arousal detection personalized with baseline calibration")
                    } else {
                        print("⚠️ No baseline calibration - using default thresholds")
                        print("   Tip: Complete baseline calibration in profile settings for more accurate detection")
                    }
                }

                if let name = childName {
                    print("✅ Loaded profile for \(name)")
                    print("🎭 Emotion interface: \(isEmotionInterfaceEnabled ? "enabled" : "disabled")")
                } else {
                    print("⚠️ No child profile found")
                }
            } catch {
                print("❌ Failed to load child profile: \(error)")
            }
        }
    }

    private func startDurationTimer() {
        durationTask?.cancel()
        durationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                updateDuration()
            }
        }
    }

    private func stopDurationTimer() {
        durationTask?.cancel()
        durationTask = nil
    }

    private func updateDuration() {
        guard let session = sessionManager.currentSession else { return }
        sessionDuration = session.durationString
    }

    private func resetSessionData() {
        sessionDuration = "0:00"
        currentArousalBand = nil
        stabilizedArousalBand = nil  // Unit 7: Reset stabilized band
        bandStabilizer.reset()       // Unit 7: Reset tracker
        currentConfidence = nil
        suggestions = []
        suggestionsCount = 0

        // Unit 8: Reset co-regulation tracking
        latestCoRegulationEvent = nil
        coRegulationEventsCount = 0
        showCoRegulationCelebration = false

        // Unit 9: Reset baseline bypass flag
        bypassStaleBaselineCheck = false
    }

    private func handleMemoryWarning() {
        print("🧹 Clearing ML caches due to memory warning")

        // Clear ML analyzer histories
        mlIntegration.clearHistory()
        coRegulationDetector.clearHistory()

        // Clear audio buffer
        audioBufferLock.lock()
        latestAudioBuffer = nil
        audioBufferLock.unlock()

        // Reset frame counter
        frameCounter = 0

        print("✅ Memory caches cleared")
    }

    private func generatePlaceholderSuggestions() {
        // Generate suggestions from content library based on arousal band
        guard let band = currentArousalBand else { return }

        Task {
            do {
                // Get content filtered by child's profile and current arousal band
                let context: ContentFilterContext
                if let profile = currentProfile {
                    // Use profile-based filtering (includes age, sensory preferences)
                    context = ContentFilterContext.from(
                        profile: profile,
                        arousalBand: band,
                        emotionState: nil
                    )
                } else {
                    // Fallback to basic filtering if no profile
                    context = ContentFilterContext(
                        ageRange: 2...8,
                        arousalBand: band,
                        emotionState: nil,
                        sensoryPreferences: nil,
                        tags: nil
                    )
                }

                let content = try await contentLibrary.getFilteredContent(context: context)

                // Take first 3 items and extract titles/summaries
                let newSuggestions = content.prefix(3).map { item in
                    item.summary ?? item.title
                }

                await MainActor.run {
                    if !newSuggestions.isEmpty {
                        suggestions = newSuggestions
                    } else {
                        // Fallback to placeholder
                        suggestions = getDefaultSuggestions(for: band)
                    }
                }
            } catch {
                print("⚠️ Failed to get suggestions: \(error)")
                suggestions = getDefaultSuggestions(for: band)
            }
        }
    }

    private func getDefaultSuggestions(for band: ArousalBand) -> [String] {
        switch band {
        case .shutdown:
            return [
                "Try alerting activities like jumping or dancing",
                "Engage with preferred sensory input"
            ]
        case .green:
            return [
                "Great regulation! Continue current activities",
                "This is a good time for learning tasks"
            ]
        case .yellow:
            return [
                "Early warning signs detected",
                "Consider a calming break or sensory input"
            ]
        case .orange:
            return [
                "Try deep pressure or weighted blanket",
                "Move to a quieter, less stimulating space"
            ]
        case .red:
            return [
                "Prioritize safety and reduce demands",
                "Provide space and minimize sensory input"
            ]
        }
    }

    // MARK: - Camera Access

    func getCaptureSession() -> AVFoundation.AVCaptureSession? {
        guard isCameraActive else { return nil }

        if isDualCameraMode {
            return dualCameraManager.getChildCaptureSession()
        } else {
            return cameraService.getCaptureSession()
        }
    }

    func getParentCaptureSession() -> AVFoundation.AVCaptureSession? {
        guard isDualCameraMode && isCameraActive else { return nil }
        return dualCameraManager.getParentCaptureSession()
    }

    // MARK: - Audio Capture

    /// Setup audio capture from microphone
    private func setupAudioCapture() async throws {
        do {
            // Setup audio engine
            try await audioCapture.setup()

            // Setup interruption observer
            audioCapture.setupInterruptionObserver()

            // Start capturing audio with callback
            try audioCapture.startCapture { [weak self] buffer in
                Task { @MainActor in
                    self?.handleAudioBuffer(buffer)
                }
            }

            print("✅ Audio capture started for ML analysis")
        } catch {
            print("❌ Failed to setup audio capture: \(error)")
            throw error
        }
    }

    /// Handle incoming audio buffer from microphone
    private func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Store latest audio buffer for frame processing
        audioBufferLock.lock()
        latestAudioBuffer = buffer
        audioBufferLock.unlock()
    }

    /// Get latest audio buffer (thread-safe)
    private func getLatestAudioBuffer() -> AVAudioPCMBuffer? {
        audioBufferLock.lock()
        defer { audioBufferLock.unlock() }
        return latestAudioBuffer
    }

    // MARK: - ML Detection

    private func startCameraDetection() async throws {
        // Setup camera
        try await cameraService.setup(position: .front)

        // Start capturing frames
        cameraService.startCapture { [weak self] cgImage in
            Task { @MainActor in
                guard let self = self, !self.isProcessingFrame else { return }
                self.isProcessingFrame = true
                defer { self.isProcessingFrame = false }
                await self.processFrame(cgImage)
            }
        }

        isCameraActive = true
        print("📹 Started camera-based arousal detection")
    }

    private func startDualCameraDetection() async throws {
        // Setup dual camera system
        let success = try await dualCameraManager.setupDualCamera()

        guard success else {
            // Fallback to single camera if dual camera setup fails
            print("⚠️ Dual camera setup failed, falling back to single camera")
            try await startCameraDetection()
            return
        }

        // Start capturing from both cameras
        dualCameraManager.startCapture(
            childFrameHandler: { [weak self] cgImage in
                Task { @MainActor in
                    guard let self = self, !self.isProcessingFrame else { return }
                    self.isProcessingFrame = true
                    defer { self.isProcessingFrame = false }
                    await self.processChildFrame(cgImage)
                }
            },
            parentFrameHandler: { [weak self] cgImage in
                Task { @MainActor in
                    guard let self = self, !self.isProcessingParentFrame else { return }
                    self.isProcessingParentFrame = true
                    defer { self.isProcessingParentFrame = false }
                    await self.processParentFrame(cgImage)
                }
            }
        )

        isDualCameraMode = true
        isCameraActive = true
        print("📹📹 Started dual camera detection (child + parent)")
    }

    private func startDualCameraRecording() async throws {
        // Setup dual camera system for preview
        let success = try await dualCameraManager.setupDualCamera()

        guard success else {
            // Fallback to single camera if dual camera setup fails
            print("⚠️ Dual camera setup failed, falling back to single camera")
            try await startCameraDetection()
            return
        }

        // Start camera capture (for preview) WITHOUT frame processing
        // We pass empty frame handlers because we're recording, not analyzing in real-time
        dualCameraManager.startCapture(
            childFrameHandler: { _ in
                // No-op - we're recording, not analyzing
            },
            parentFrameHandler: { _ in
                // No-op - we're recording, not analyzing
            }
        )

        // Get sessions for recording
        guard let childSession = dualCameraManager.getChildCaptureSession(),
              let parentSession = dualCameraManager.getParentCaptureSession() else {
            throw NSError(domain: "LiveCoach", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get capture sessions"])
        }

        // Start recording to video files
        let _ = try await recordingManager.startRecording(
            childSession: childSession,
            parentSession: parentSession
        )

        isDualCameraMode = true
        isCameraActive = true
        print("🎬 Started dual camera recording (record-first mode)")
    }

    private func startSimulatedDetection() {
        // Start task for simulated detection (for demo without camera)
        detectionTask?.cancel()
        detectionTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { break }
                await simulateArousalDetection()
            }
        }

        print("🎲 Started simulated arousal detection")
    }

    private func stopDetection() {
        // Stop camera capture
        if isDualCameraMode {
            dualCameraManager.stopCapture()
        } else {
            cameraService.stopCapture()
        }

        // Stop audio capture
        audioCapture.stopCapture()

        // Clear audio buffer
        audioBufferLock.lock()
        latestAudioBuffer = nil
        audioBufferLock.unlock()

        detectionTask?.cancel()
        detectionTask = nil
        isProcessingFrame = false
        isProcessingParentFrame = false
        isCameraActive = false
        isDualCameraMode = false

        mlIntegration.clearHistory()
        coRegulationDetector.clearHistory()
    }

    private func processFrame(_ image: CGImage) async {
        guard isSessionActive && !isPaused else { return }

        // Skip frames to reduce memory pressure
        frameCounter += 1
        guard frameCounter % frameSkipInterval == 0 else { return }

        do {
            // Convert CGImage to CVPixelBuffer for ML analysis
            // Use autoreleasepool for memory-intensive conversion
            let pixelBuffer: CVPixelBuffer? = autoreleasepool {
                return image.toPixelBuffer()
            }

            guard let pixelBuffer = pixelBuffer else {
                print("⚠️ Failed to convert image to pixel buffer")
                return
            }

            // Get latest audio buffer (if available)
            let audioBuffer = getLatestAudioBuffer()

            // Run new integrated ML analysis with both video and audio
            let analysis = try await mlIntegration.analyzeFrame(
                videoFrame: pixelBuffer,
                audioBuffer: audioBuffer
            )

            // Record arousal band in session
            try await sessionManager.recordArousalBandReading(
                arousalBand: analysis.arousalBand,
                confidence: analysis.confidence,
                source: .mlModel
            )

            // Record parent state for co-regulation detection (from audio analysis)
            let parentState = mapStressToParentState(analysis.parentStressLevel)
            let parentEngagement = calculateParentEngagement(analysis.parentStressLevel)
            coRegulationDetector.recordParentState(parentState, engagement: parentEngagement)

            // Update UI (real-time indicators)
            currentConfidence = analysis.confidence
            currentMovementEnergy = analysis.movementEnergy
            detectedBehaviors = analysis.detectedBehaviors

            // Update camera stability status
            let stabilityInfo = mlIntegration.getCameraStabilityInfo()
            isCameraStable = stabilityInfo.isStable
            cameraMotionDescription = stabilityInfo.motion?.description

            // Update arousal band with stabilization and co-regulation detection (Unit 7 + Unit 8)
            await updateArousalBandWithStabilization(
                band: analysis.arousalBand,
                suggestions: analysis.suggestions,
                suggestionsWithResources: analysis.suggestionsWithResources
            )

            // Record LLM suggestions in session history
            for suggestion in analysis.suggestionsWithResources {
                do {
                    try await sessionManager.recordDeliveredSuggestion(
                        contentItemID: UUID(), // Generate UUID for LLM suggestion
                        suggestionText: suggestion.text,
                        arousalBand: analysis.arousalBand
                    )
                } catch {
                    print("⚠️ Failed to record suggestion: \(error)")
                }
            }

        } catch {
            print("⚠️ ML detection failed: \(error.localizedDescription)")
        }
    }

    private func simulateArousalDetection() async {
        guard isSessionActive && !isPaused else { return }

        // Simple simulated arousal band for testing without camera
        let simulatedBands: [ArousalBand] = [.green, .green, .yellow, .green, .orange]
        let randomBand = simulatedBands.randomElement() ?? .green
        let simulatedConfidence = 0.65

        do {
            // Record in session
            try await sessionManager.recordArousalBandReading(
                arousalBand: randomBand,
                confidence: simulatedConfidence,
                source: .fallback
            )

            // Update UI
            updateArousalBand(randomBand)  // Unit 7: Multi-tier update
            currentConfidence = simulatedConfidence

            // Generate suggestions
            generatePlaceholderSuggestions()

        } catch {
            print("⚠️ Failed to record simulated reading: \(error)")
        }
    }

    // MARK: - Dual Camera Processing

    private func processChildFrame(_ image: CGImage) async {
        guard isSessionActive && !isPaused else { return }

        // Skip frames to reduce memory pressure
        frameCounter += 1
        guard frameCounter % frameSkipInterval == 0 else { return }

        do {
            // Convert CGImage to CVPixelBuffer for ML analysis
            // Use autoreleasepool for memory-intensive conversion
            let pixelBuffer: CVPixelBuffer? = autoreleasepool {
                return image.toPixelBuffer()
            }

            guard let pixelBuffer = pixelBuffer else {
                print("⚠️ Failed to convert image to pixel buffer")
                return
            }

            // Get latest audio buffer (if available)
            let audioBuffer = getLatestAudioBuffer()

            // Run new integrated ML analysis with parent monitoring if in dual camera mode
            mlIntegration.setParentMonitoring(enabled: isDualCameraMode)

            // Run ML analysis with both video and audio
            let analysis = try await mlIntegration.analyzeFrame(
                videoFrame: pixelBuffer,
                audioBuffer: audioBuffer
            )

            // Record arousal band in session
            try await sessionManager.recordArousalBandReading(
                arousalBand: analysis.arousalBand,
                confidence: analysis.confidence,
                source: .mlModel
            )

            // Record parent state for co-regulation detection (continuous monitoring)
            let parentState = mapStressToParentState(analysis.parentStressLevel)
            let parentEngagement = calculateParentEngagement(analysis.parentStressLevel)
            coRegulationDetector.recordParentState(parentState, engagement: parentEngagement)

            // Update UI (real-time indicators)
            currentConfidence = analysis.confidence
            currentMovementEnergy = analysis.movementEnergy
            detectedBehaviors = analysis.detectedBehaviors

            // Update camera stability status
            let stabilityInfo = mlIntegration.getCameraStabilityInfo()
            isCameraStable = stabilityInfo.isStable
            cameraMotionDescription = stabilityInfo.motion?.description

            // Update arousal band for both tiers and handle stabilized changes
            await updateArousalBandWithStabilization(
                band: analysis.arousalBand,
                suggestions: analysis.suggestions,
                suggestionsWithResources: analysis.suggestionsWithResources
            )

            // Record LLM suggestions in session history
            for suggestion in analysis.suggestionsWithResources {
                do {
                    try await sessionManager.recordDeliveredSuggestion(
                        contentItemID: UUID(), // Generate UUID for LLM suggestion
                        suggestionText: suggestion.text,
                        arousalBand: analysis.arousalBand
                    )
                } catch {
                    print("⚠️ Failed to record suggestion: \(error)")
                }
            }

            // Classify emotion if emotion interface is enabled
            if isEmotionInterfaceEnabled {
                do {
                    let emotionClassification = try await emotionClassifier.classifyEmotion(from: image)
                    currentEmotionState = emotionClassification

                    // Check if validation prompt should be shown
                    if validationManager.shouldShowValidationPrompt(),
                       let childID = currentProfile?.id {
                        validationPrompt = validationManager.createValidationPrompt(
                            for: emotionClassification,
                            childID: childID
                        )
                    }
                } catch {
                    print("⚠️ Emotion classification failed: \(error.localizedDescription)")
                }
            }

        } catch {
            print("⚠️ Child ML detection failed: \(error.localizedDescription)")
        }
    }

    private func processParentFrame(_ image: CGImage) async {
        guard isSessionActive && !isPaused else { return }

        // Parent frame processing is handled in processChildFrame via MLIntegration
        // when parent monitoring is enabled. This method is kept for compatibility
        // but currently doesn't perform additional analysis.

        // Future: Could add separate parent-specific UI feedback here
        print("📹 Parent frame received (analysis handled in child frame processing)")
    }

    // MARK: - Unit 7: Multi-Tier Display Helpers

    /// Update arousal band for both tiers (real-time and stabilized)
    /// Triggers co-regulation detection and suggestion updates ONLY on stabilized changes
    private func updateArousalBandWithStabilization(
        band: ArousalBand,
        suggestions: [String],
        suggestionsWithResources: [CoachingSuggestionWithResource]
    ) async {
        // Tier 1: Immediate update for ambient indicator
        currentArousalBand = band

        // Tier 2: Update stabilizer and get stable band if sustained
        if let stableBand = bandStabilizer.update(band: band) {
            stabilizedArousalBand = stableBand
            print("✅ Stabilized band updated: \(stableBand.rawValue)")

            // Only update these when stabilized band changes (not on every frame):

            // 1. Record child state for co-regulation detection
            coRegulationDetector.recordChildState(stableBand)

            // 2. Check for co-regulation events (Unit 8: Co-Regulation Feedback)
            if let session = sessionManager.currentSession,
               let event = coRegulationDetector.detectCoRegulationEvent(sessionID: session.id) {
                do {
                    try await sessionManager.recordCoRegulationEvent(event)

                    // Trigger celebration feedback
                    await handleCoRegulationEvent(event)
                } catch {
                    print("⚠️ Failed to record co-regulation event: \(error)")
                }
            }

            // 3. Update suggestions (synced with stabilized band changes)
            self.suggestions = suggestions
            self.suggestionsWithResources = suggestionsWithResources
            print("💡 Suggestions updated with stabilized band change")
        }
    }

    /// Simple arousal band update (for session restore, camera-only, mock modes)
    /// Does NOT trigger co-regulation detection or suggestion updates
    private func updateArousalBand(_ band: ArousalBand) {
        // Tier 1: Immediate update for ambient indicator
        currentArousalBand = band

        // Tier 2: Update stabilizer (no additional actions)
        if let stableBand = bandStabilizer.update(band: band) {
            stabilizedArousalBand = stableBand
            print("✅ Stabilized band updated: \(stableBand.rawValue)")
        }
    }

    // MARK: - Unit 8: Co-Regulation Feedback Handlers

    /// Handle detected co-regulation event with celebration feedback
    private func handleCoRegulationEvent(_ event: CoRegulationEvent) async {
        // Update state
        latestCoRegulationEvent = event
        coRegulationEventsCount += 1

        // Trigger haptic feedback
        triggerSuccessHaptic()

        // Show celebration UI
        showCoRegulationCelebration = true

        // Log success
        print("🎉 Co-regulation event #\(coRegulationEventsCount): \(event.eventDescription)")

        // Auto-dismiss celebration after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showCoRegulationCelebration = false
            }
        }
    }

    /// Trigger haptic feedback for successful co-regulation
    private func triggerSuccessHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    /// Get session co-regulation statistics
    func getCoRegulationStats() -> (total: Int, successRate: Double) {
        let total = coRegulationEventsCount
        // For now, all detected events are considered successful
        // In the future, filter by event.wasSuccessful
        let successful = total
        let rate = total > 0 ? Double(successful) / Double(total) : 0.0
        return (total, rate)
    }

    // MARK: - Unit 9: Baseline Staleness Helpers

    /// Calculate how many days old the baseline is
    private func getDaysOld(_ date: Date?) -> Int {
        guard let date = date else { return 999 } // Very old if no baseline
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 999
        return max(days, 0)
    }

    /// User chose to continue with stale baseline
    func continueWithStaleBaseline() {
        showBaselineStaleAlert = false
        bypassStaleBaselineCheck = true
        print("ℹ️ User chose to continue with stale baseline - restarting session")
        // Restart session with bypass flag set
        Task {
            await startSession()
        }
    }

    /// User chose to recalibrate - navigate to calibration
    func requestRecalibration() {
        showBaselineStaleAlert = false
        // Navigation will be handled by LiveCoachView
        print("🎯 User requested baseline recalibration")
    }

    // MARK: - Co-Regulation Mapping Helpers

    /// Map StressLevel to ParentState for co-regulation detection
    private func mapStressToParentState(_ stressLevel: StressLevel) -> ParentState {
        switch stressLevel {
        case .calm:
            return .calm
        case .building:
            return .coRegulating  // Assume building stress = actively co-regulating
        case .high:
            return .stressed
        }
    }

    /// Calculate parent engagement level from stress
    /// Lower stress typically indicates better capacity for co-regulation
    private func calculateParentEngagement(_ stressLevel: StressLevel) -> Double {
        switch stressLevel {
        case .calm:
            return 0.85  // Calm parent = high engagement capacity
        case .building:
            return 0.70  // Building stress = moderate engagement
        case .high:
            return 0.40  // High stress = low engagement capacity
        }
    }
}
