//
//  AudioCaptureService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach: Audio Capture Service
//
//  Captures microphone audio for vocal stress and ambient noise analysis
//

import Foundation
import AVFoundation
import Combine

/// Service for capturing microphone audio for ML analysis
class AudioCaptureService: ObservableObject {

    // MARK: - Singleton

    static let shared = AudioCaptureService()

    // MARK: - Published Properties
    // These must be updated on main thread only

    @Published private(set) var isCapturing = false
    @Published private(set) var audioLevel: Float = 0.0  // 0.0 to 1.0

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioBufferCallback: ((AVAudioPCMBuffer) -> Void)?

    // Store latest buffer for on-demand access
    private var latestBuffer: AVAudioPCMBuffer?
    private let bufferLock = NSLock()

    // Audio queue for engine operations
    private let audioQueue = DispatchQueue(label: "com.neuroguide.audioCapture", qos: .userInitiated)

    // Audio format for analysis
    private let sampleRate: Double = 44100.0  // Standard sample rate
    private let channelCount: AVAudioChannelCount = 1  // Mono

    // MARK: - Initialization

    private init() {
        print("✅ AudioCaptureService initialized")
    }

    // MARK: - Setup

    /// Setup audio engine and request microphone permission
    func setup() async throws {
        // Request microphone permission
        let granted = await requestMicrophonePermission()

        guard granted else {
            throw AudioCaptureError.permissionDenied
        }

        // Configure audio session and engine on background thread
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            audioQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: AudioCaptureError.engineSetupFailed)
                    return
                }

                do {
                    // Configure audio session
                    try self.configureAudioSession()

                    // Setup audio engine
                    try self.setupAudioEngine()

                    print("✅ Audio capture setup complete")
                    continuation.resume()
                } catch {
                    print("❌ Audio setup failed: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Request microphone permission
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Configure audio session for recording
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetooth]
        )

        try session.setActive(true)

        print("✅ Audio session configured")
    }

    /// Setup AVAudioEngine for microphone input
    private func setupAudioEngine() throws {
        audioEngine = AVAudioEngine()

        guard let engine = audioEngine else {
            throw AudioCaptureError.engineSetupFailed
        }

        inputNode = engine.inputNode

        guard let input = inputNode else {
            throw AudioCaptureError.noInputNode
        }

        // IMPORTANT: Use the input node's hardware format directly
        // Don't try to force a custom format - iOS will reject format mismatches
        let inputFormat = input.inputFormat(forBus: 0)

        // Validate format
        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            throw AudioCaptureError.formatCreationFailed
        }

        // Install tap on input node using the hardware format
        // Buffer size: 4096 samples (~93ms at 44.1kHz, varies by device)
        // This callback runs on audio thread, not main thread
        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            // Process buffer on background thread
            self?.processAudioBuffer(buffer)
        }

        print("✅ Audio engine configured with hardware format: \(inputFormat)")
        print("   Sample rate: \(inputFormat.sampleRate) Hz")
        print("   Channels: \(inputFormat.channelCount)")
        print("   Format: \(inputFormat.commonFormat.rawValue)")
    }

    // MARK: - Capture Control

    /// Start capturing audio from microphone
    /// - Parameter callback: Callback that receives audio buffers for analysis
    func startCapture(callback: @escaping (AVAudioPCMBuffer) -> Void) throws {
        guard let engine = audioEngine else {
            throw AudioCaptureError.engineNotSetup
        }

        guard !isCapturing else {
            print("⚠️ Audio capture already active")
            return
        }

        audioBufferCallback = callback

        // Start engine on background thread
        audioQueue.async { [weak self] in
            do {
                try engine.start()
                print("✅ Audio capture started")

                // Update published property on main thread
                DispatchQueue.main.async {
                    self?.isCapturing = true
                }
            } catch {
                print("❌ Failed to start audio engine: \(error)")
            }
        }
    }

    /// Stop capturing audio
    func stopCapture() {
        guard let engine = audioEngine else { return }

        guard isCapturing else { return }

        // Stop engine on background thread
        audioQueue.async { [weak self] in
            // Stop engine
            engine.stop()

            // Remove tap
            self?.inputNode?.removeTap(onBus: 0)

            self?.audioBufferCallback = nil

            print("✅ Audio capture stopped")

            // Update published property on main thread
            DispatchQueue.main.async {
                self?.isCapturing = false
            }
        }
    }

    /// Cleanup audio engine and session
    func cleanup() {
        stopCapture()

        audioEngine = nil
        inputNode = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)

        print("✅ Audio capture cleaned up")
    }

    // MARK: - Private Methods

    /// Process audio buffer from microphone
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Store latest buffer for on-demand access
        bufferLock.lock()
        latestBuffer = buffer
        bufferLock.unlock()

        // Calculate audio level (for UI feedback)
        updateAudioLevel(buffer)

        // Pass buffer to callback for ML analysis
        audioBufferCallback?(buffer)
    }

    /// Update audio level for UI visualization
    private func updateAudioLevel(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataPointer = channelData[0]
        let frameLength = Int(buffer.frameLength)

        // Calculate RMS (root mean square) for audio level
        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelDataPointer[i]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))

        // Convert to 0.0 - 1.0 range (assuming max RMS ~0.5)
        let level = min(rms * 2.0, 1.0)

        // Update published property on main thread
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = level
        }
    }

    // MARK: - Utilities

    /// Get current audio format
    func getAudioFormat() -> AVAudioFormat? {
        return inputNode?.inputFormat(forBus: 0)
    }

    /// Check if microphone is available
    func isMicrophoneAvailable() -> Bool {
        return AVAudioSession.sharedInstance().isInputAvailable
    }

    /// Get current audio level in dB
    func getAudioLevelInDB() -> Float {
        // Convert RMS to dB
        // dB = 20 * log10(rms)
        guard audioLevel > 0 else { return -Float.infinity }

        return 20.0 * log10(audioLevel)
    }

    /// Get the latest audio buffer
    /// - Returns: Most recent audio buffer, or nil if none available
    func getLatestBuffer() -> AVAudioPCMBuffer? {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        return latestBuffer
    }
}

// MARK: - Errors

enum AudioCaptureError: LocalizedError {
    case permissionDenied
    case engineSetupFailed
    case engineNotSetup
    case noInputNode
    case formatCreationFailed
    case captureStartFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .engineSetupFailed:
            return "Failed to setup audio engine"
        case .engineNotSetup:
            return "Audio engine not setup"
        case .noInputNode:
            return "No audio input node available"
        case .formatCreationFailed:
            return "Failed to create audio format"
        case .captureStartFailed:
            return "Failed to start audio capture"
        }
    }
}

// MARK: - Audio Session Observer

extension AudioCaptureService {

    /// Setup audio session interruption observer
    func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    /// Handle audio session interruption (phone call, etc.)
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began (e.g., phone call)
            print("🔇 Audio session interrupted")
            stopCapture()

        case .ended:
            // Interruption ended
            print("🔊 Audio session interruption ended")

            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }

            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            if options.contains(.shouldResume) {
                // Resume capture if appropriate
                print("🔊 Resuming audio capture")
                try? audioEngine?.start()
                isCapturing = true
            }

        @unknown default:
            break
        }
    }

    /// Handle audio route change (headphones plugged/unplugged, etc.)
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .newDeviceAvailable:
            print("🎧 New audio device available")

        case .oldDeviceUnavailable:
            print("🎧 Audio device unavailable")

        default:
            break
        }
    }
}
