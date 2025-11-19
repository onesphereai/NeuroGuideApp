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
import Speech

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
    @Published private(set) var currentFeatureVisualization: FeatureVisualization?
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var suggestionsWithResources: [CoachingSuggestionWithResource] = []
    @Published private(set) var suggestionsCount = 0

    // Dual suggestions (child + parent)
    @Published private(set) var childSuggestion: CoachingSuggestionWithResource?
    @Published private(set) var parentSuggestion: CoachingSuggestionWithResource?
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

    // Voice Observations (Modern UI)
    @Published var isRecordingVoice = false
    @Published var voiceObservations: [VoiceObservation] = []

    // Emotional States (Modern UI)
    @Published private(set) var childEmotionalState: String?
    @Published private(set) var parentEmotionalState: String?

    // Live Coach Mode Status
    @Published private(set) var activeMode: LiveCoachMode = .standard
    @Published private(set) var hasCustomModelLoaded: Bool = false

    // Camera Stabilization Status
    @Published private(set) var isCameraStable: Bool = true
    @Published private(set) var cameraMotionDescription: String?
    @Published private(set) var isPersonDetected: Bool = true  // Track if person is in frame

    // Unit 8: Co-Regulation Feedback
    @Published private(set) var latestCoRegulationEvent: CoRegulationEvent?
    @Published private(set) var coRegulationEventsCount: Int = 0
    @Published private(set) var showCoRegulationCelebration: Bool = false

    // Suggestion Generation Status
    @Published private(set) var isGeneratingSuggestion: Bool = false

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
    private lazy var customModelManager: CustomModelManager = CustomModelManager.shared
    private lazy var bandStabilizer: StabilizedBandTracker = {
        let threshold = settingsManager.arousalBandDuration.seconds
        return StabilizedBandTracker(sustainThreshold: threshold)
    }()
    private var cancellables = Set<AnyCancellable>()
    private var durationTask: Task<Void, Never>?
    private var detectionTask: Task<Void, Never>?
    private var isProcessingFrame = false
    private var isProcessingParentFrame = false

    // Session context for LLM
    private var sessionContext: SessionContext?

    // Voice recording
    private var audioRecorder: AVAudioRecorder?
    private var currentRecordingURL: URL?

    // Frame skipping for memory management (process every Nth frame)
    private var frameCounter: Int = 0
    private let frameSkipInterval: Int = 30  // Process every 30th frame (~1fps instead of 30fps) - aggressive memory saving

    // Audio buffer management
    private var latestAudioBuffer: AVAudioPCMBuffer?
    private var audioBufferLock = NSLock()

    // Current child profile
    // Unit 9: Expose profile for navigation to recalibration
    private(set) var currentProfile: ChildProfile?

    // Track last delivered suggestions to prevent duplicates
    private var lastDeliveredChildSuggestion: String?
    private var lastDeliveredParentSuggestion: String?

    // MARK: - Initialization

    init() {
        // Empty init - services are initialized lazily when first accessed
    }

    deinit {
        // Ensure idle timer is re-enabled when view model is deallocated
        Task { @MainActor in
            UIApplication.shared.isIdleTimerDisabled = false
            print("🔒 LiveCoachViewModel deallocated - idle timer re-enabled")
        }
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

        // Request permissions if not yet determined
        if cameraStatus == .notDetermined || microphoneStatus == .notDetermined {
            print("📱 Requesting camera and microphone permissions...")
            let (cameraGranted, micGranted) = await permissionsService.requestAllPermissions()
            print("📹 Camera: \(cameraGranted ? "granted" : "denied")")
            print("🎤 Microphone: \(micGranted ? "granted" : "denied")")
        }

        // Request speech recognition permission
        await requestSpeechRecognitionPermission()

        do {
            let session = try await sessionManager.startSession(childID: profile.id)
            isSessionActive = true
            degradationMode = session.degradedMode
            startDurationTimer()

            // Initialize session context for LLM
            sessionContext = SessionContext.initial(childProfile: profile)

            // Reset camera stabilization for new session
            mlIntegration.resetStabilization()

            // Setup audio capture if microphone permission granted
            if microphoneStatus == .granted {
                try await setupAudioCapture()
            } else {
                print("⚠️ Microphone permission not granted - audio analysis disabled")
            }

            // Check if custom model is available for personalized mode
            let hasCustomModel = await customModelManager.hasCustomModel(for: profile.id)
            let currentMode = settingsManager.liveCoachMode

            // Determine active mode based on settings and model availability
            if currentMode == .personalized && hasCustomModel {
                // Load custom k-NN model for personalized detection
                do {
                    let knnModel = try await customModelManager.loadKNNModel(for: profile.id)
                    // Configure arousal classifier to use the custom k-NN model
                    ArousalBandClassifier.shared.setCustomKNNModel(knnModel)
                    activeMode = .personalized
                    hasCustomModelLoaded = true
                    print("✨ Starting in Personalized Mode with custom k-NN model")
                } catch {
                    activeMode = .standard
                    hasCustomModelLoaded = false
                    print("⚠️ Error loading custom model: \(error) - using Standard mode")
                }
            } else if currentMode == .personalized && !hasCustomModel {
                activeMode = .standard
                hasCustomModelLoaded = false
                print("⚠️ Personalized mode selected but no custom model found - using Standard mode")
            } else {
                activeMode = .standard
                hasCustomModelLoaded = false
                print("📊 Starting in Standard Mode with generic ML models")
            }

            // Setup camera if permissions granted and not in simulator
            #if targetEnvironment(simulator)
            // Always use simulated detection in simulator (no camera available)
            startSimulatedDetection()
            print("📱 Running in simulator - using simulated detection")
            #else
            // On real device, use camera if available
            if cameraStatus == .granted {
                // Check if dual camera is supported
                if DualCameraManager.supportsMultiCam() {
                    print("📱 Device supports dual camera - starting detection")
                    try await startDualCameraDetection()
                } else {
                    print("📱 Device does not support dual camera - using single camera")
                    try await startCameraDetection()
                }
            } else {
                startSimulatedDetection()
            }
            #endif

            // Disable idle timer to prevent screen lock during session
            UIApplication.shared.isIdleTimerDisabled = true
            print("🔓 Idle timer disabled - screen will stay awake during session")

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

            // Clear LLM cache
            mlIntegration.clearLLMCache()

            try await sessionManager.endSession(notes: notes)
            isSessionActive = false
            isPaused = false
            stopDurationTimer()
            resetSessionData()
            errorMessage = nil

            // Re-enable idle timer to allow screen lock
            UIApplication.shared.isIdleTimerDisabled = false
            print("🔒 Idle timer re-enabled - device can sleep normally")

            print("✅ Session ended successfully")
        } catch {
            errorMessage = "Failed to end session properly. Session data may not be saved."
            print("❌ Failed to end session: \(error)")

            // Re-enable idle timer even on error
            UIApplication.shared.isIdleTimerDisabled = false
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

    // MARK: - Voice Observations

    private func requestSpeechRecognitionPermission() async {
        let status = SFSpeechRecognizer.authorizationStatus()
        print("🎙️ Speech recognition status: \(status.rawValue)")

        if status == .notDetermined {
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { newStatus in
                    print("🎙️ Speech recognition authorization: \(newStatus.rawValue)")
                    continuation.resume()
                }
            }
        }
    }

    func startVoiceObservation() {
        isRecordingVoice = true
        print("🎤 Started voice observation recording")

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Failed to configure audio session: \(error)")
            return
        }

        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voice_observation_\(UUID().uuidString).m4a"
        let audioURL = tempDir.appendingPathComponent(fileName)
        currentRecordingURL = audioURL

        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Start recording
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.record()
            print("✅ Recording started at: \(audioURL)")
        } catch {
            print("⚠️ Failed to start recording: \(error)")
            currentRecordingURL = nil
        }
    }

    func stopVoiceObservation() async {
        isRecordingVoice = false
        print("🎤 Stopped voice observation recording")

        // Stop recording
        audioRecorder?.stop()
        audioRecorder = nil

        guard let audioURL = currentRecordingURL else {
            print("⚠️ No audio URL available")
            return
        }

        // Create observation with audio URL (transcription will be added later)
        var observation = VoiceObservation(
            timestamp: Date(),
            audioURL: audioURL,
            transcription: nil
        )

        voiceObservations.insert(observation, at: 0)  // Add to beginning
        print("✅ Voice observation added: \(observation.id)")

        // Transcribe audio
        await transcribeAudio(url: audioURL, observationID: observation.id)

        currentRecordingURL = nil
    }

    private func transcribeAudio(url: URL, observationID: UUID) async {
        print("🎙️ Starting transcription for: \(url)")

        // Check speech recognition availability
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("⚠️ Speech recognition not authorized")
            updateObservationTranscription(id: observationID, text: "Speech recognition not authorized. Please enable in Settings.")
            return
        }

        let recognizer = SFSpeechRecognizer()
        guard recognizer?.isAvailable == true else {
            print("⚠️ Speech recognizer not available")
            updateObservationTranscription(id: observationID, text: "Speech recognition not available")
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            recognizer?.recognitionTask(with: request) { result, error in
                if let error = error {
                    print("⚠️ Transcription failed: \(error)")
                    Task { @MainActor in
                        self.updateObservationTranscription(id: observationID, text: "Transcription failed")
                    }
                    continuation.resume()
                    return
                }

                if let result = result, result.isFinal {
                    let transcription = result.bestTranscription.formattedString
                    print("✅ Transcription complete: \(transcription)")
                    Task { @MainActor in
                        self.updateObservationTranscription(id: observationID, text: transcription)
                        // TODO: Feed transcription to LLM for better context
                    }
                    continuation.resume()
                }
            }
        }
    }

    private func updateObservationTranscription(id: UUID, text: String) {
        if let index = voiceObservations.firstIndex(where: { $0.id == id }) {
            voiceObservations[index].transcription = text
            voiceObservations[index].sentToLLM = false  // Mark as not yet sent

            // Add to session context
            sessionContext?.addVoiceObservation(transcription: text)

            print("✅ Updated transcription for observation \(id) and added to session context")
        }
    }

    func recordSuggestionFeedback(helpful: Bool) async {
        guard let suggestion = suggestionsWithResources.first else { return }
        print("\(helpful ? "👍" : "👎") Suggestion feedback: \(helpful ? "Helpful" : "Not Helpful")")
        // TODO: Record feedback in session history
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

        // Observe app lifecycle for idle timer management
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Re-enable idle timer when app goes to background
            if self?.isSessionActive == true {
                UIApplication.shared.isIdleTimerDisabled = false
                print("🔒 App backgrounded - idle timer re-enabled")
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Re-disable idle timer when app returns to foreground with active session
            if self?.isSessionActive == true {
                UIApplication.shared.isIdleTimerDisabled = true
                print("🔓 App foregrounded - idle timer disabled for active session")
            }
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
        suggestionsWithResources = []
        suggestionsCount = 0

        // Clear dual suggestions
        childSuggestion = nil
        parentSuggestion = nil

        // Reset suggestion tracking to prevent duplicates
        lastDeliveredChildSuggestion = nil
        lastDeliveredParentSuggestion = nil

        // Clear ML detection state
        currentFeatureVisualization = nil
        detectedBehaviors = []
        currentMovementEnergy = nil
        childEmotionalState = nil
        parentEmotionalState = nil
        currentEmotionState = nil

        // Reset detection status
        isPersonDetected = true
        isCameraStable = true
        cameraMotionDescription = nil

        // Reset mode tracking
        activeMode = .standard
        hasCustomModelLoaded = false

        // Unit 8: Reset co-regulation tracking
        latestCoRegulationEvent = nil
        coRegulationEventsCount = 0
        showCoRegulationCelebration = false

        // Reset voice observations
        voiceObservations = []
        isRecordingVoice = false
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

            // Show generation indicator
            isGeneratingSuggestion = true

            // Run new integrated ML analysis with both video and audio
            let analysis = try await mlIntegration.analyzeFrame(
                videoFrame: pixelBuffer,
                audioBuffer: audioBuffer,
                sessionContext: sessionContext
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
            currentFeatureVisualization = ArousalBandClassifier.shared.currentFeatureVisualization

            // Update camera stability status
            let stabilityInfo = mlIntegration.getCameraStabilityInfo()
            isCameraStable = stabilityInfo.isStable
            cameraMotionDescription = stabilityInfo.motion?.description

            // Update arousal band with stabilization and co-regulation detection (Unit 7 + Unit 8)
            // Extracts dual suggestions from analysis result
            await updateArousalBandWithStabilization(
                band: analysis.arousalBand,
                behaviors: analysis.detectedBehaviors,
                environmentContext: analysis.environmentContext,
                parentStress: analysis.parentStressLevel,
                analysis: analysis
            )

            // Hide generation indicator
            isGeneratingSuggestion = false

        } catch {
            print("⚠️ ML detection failed: \(error.localizedDescription)")
            // Hide generation indicator on error too
            isGeneratingSuggestion = false
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

            // Show generation indicator
            isGeneratingSuggestion = true

            // Run ML analysis with both video and audio
            let analysis = try await mlIntegration.analyzeFrame(
                videoFrame: pixelBuffer,
                audioBuffer: audioBuffer,
                sessionContext: sessionContext
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
            currentFeatureVisualization = ArousalBandClassifier.shared.currentFeatureVisualization

            // Check if person is detected (any modality available)
            if let features = currentFeatureVisualization {
                isPersonDetected = features.poseAvailable || features.facialAvailable || features.vocalAvailable

                if !isPersonDetected {
                    print("⚠️ No person detected in frame - all modalities unavailable")
                }
            }

            // Update camera stability status
            let stabilityInfo = mlIntegration.getCameraStabilityInfo()
            isCameraStable = stabilityInfo.isStable
            cameraMotionDescription = stabilityInfo.motion?.description

            // Update arousal band for both tiers and handle stabilized changes
            // Extracts dual suggestions from analysis result
            await updateArousalBandWithStabilization(
                band: analysis.arousalBand,
                behaviors: analysis.detectedBehaviors,
                environmentContext: analysis.environmentContext,
                parentStress: analysis.parentStressLevel,
                analysis: analysis
            )

            // Hide generation indicator
            isGeneratingSuggestion = false

            // Classify emotion if emotion interface is enabled
            if isEmotionInterfaceEnabled {
                do {
                    let emotionClassification = try await emotionClassifier.classifyEmotion(from: image)
                    currentEmotionState = emotionClassification
                    childEmotionalState = emotionClassification.primary.displayName

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
            // Hide generation indicator on error too
            isGeneratingSuggestion = false
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
    /// Uses suggestions from MLAnalysisResult (already generated with 5-second temporal buffer)
    private func updateArousalBandWithStabilization(
        band: ArousalBand,
        behaviors: [ChildBehavior],
        environmentContext: EnvironmentContext,
        parentStress: StressLevel,
        analysis: MLAnalysisResult?
    ) async {
        // Tier 1: Immediate update for ambient indicator
        currentArousalBand = band

        // Tier 2: Update stabilizer and only trigger suggestions on stabilized band changes
        if let stableBand = bandStabilizer.update(band: band) {
            // Store previous stabilized band to detect actual changes
            let previousStabilizedBand = stabilizedArousalBand
            stabilizedArousalBand = stableBand

            print("✅ Stabilized band changed: \(previousStabilizedBand?.rawValue ?? "nil") → \(stableBand.rawValue)")

            // Record child state for co-regulation detection
            coRegulationDetector.recordChildState(stableBand)

            // Check for co-regulation events (Unit 8: Co-Regulation Feedback)
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

            // ONLY update suggestions when the stabilized band actually changes
            // This prevents rapid suggestion updates on every frame
            if previousStabilizedBand != stableBand {
                await updateSuggestionsForStabilizedBand(stableBand, analysis: analysis)
            }
        }
    }

    /// Update suggestions for a new stabilized band
    /// Only called when stabilized band actually changes
    private func updateSuggestionsForStabilizedBand(_ stableBand: ArousalBand, analysis: MLAnalysisResult?) async {
        print("💡 Updating suggestions for new stabilized band: \(stableBand.rawValue)")

        // Extract child and parent suggestions from analysis
        if let analysis = analysis {
            self.childSuggestion = analysis.childSuggestion
            self.parentSuggestion = analysis.parentSuggestion

            // Update legacy arrays for backwards compatibility
            let newSuggestionsWithResources = analysis.suggestionsWithResources
            self.suggestionsWithResources = newSuggestionsWithResources
            self.suggestions = newSuggestionsWithResources.map { $0.text }

            // Record suggestions in session history ONLY if they're different from the last ones
            // This prevents duplicate suggestion recording during rapid band fluctuations
            if let childSugg = analysis.childSuggestion,
               childSugg.text != lastDeliveredChildSuggestion {
                do {
                    try await sessionManager.recordDeliveredSuggestion(
                        contentItemID: UUID(),
                        suggestionText: childSugg.text,
                        arousalBand: stableBand
                    )
                    lastDeliveredChildSuggestion = childSugg.text
                    print("📝 Recorded new child suggestion")
                } catch {
                    print("⚠️ Failed to record child suggestion: \(error)")
                }
            } else if let childSugg = analysis.childSuggestion {
                print("⏭️ Skipping duplicate child suggestion")
            }

            if let parentSugg = analysis.parentSuggestion,
               parentSugg.text != lastDeliveredParentSuggestion {
                do {
                    try await sessionManager.recordDeliveredSuggestion(
                        contentItemID: UUID(),
                        suggestionText: parentSugg.text,
                        arousalBand: stableBand
                    )
                    lastDeliveredParentSuggestion = parentSugg.text
                    print("📝 Recorded new parent suggestion")
                } catch {
                    print("⚠️ Failed to record parent suggestion: \(error)")
                }
            } else if let parentSugg = analysis.parentSuggestion {
                print("⏭️ Skipping duplicate parent suggestion")
            }

            print("💡 Dual suggestions updated for stabilized band change")
            if let child = childSuggestion {
                print("   Child: \(child.text.prefix(50))...")
            }
            if let parent = parentSuggestion {
                print("   Parent: \(parent.text.prefix(50))...")
            }
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
