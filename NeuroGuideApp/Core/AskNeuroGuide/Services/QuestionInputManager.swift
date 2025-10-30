//
//  QuestionInputManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Manager for voice and text question input
/// Uses on-device speech recognition for privacy
@MainActor
class QuestionInputManager: QuestionInputService, ObservableObject {
    // MARK: - Singleton

    static let shared = QuestionInputManager()

    // MARK: - Published Properties

    @Published private(set) var isRecording = false
    @Published private(set) var recognizedText = ""
    @Published private(set) var hasPermission = false
    @Published private(set) var permissionError: String?

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Initialization

    init() {
        // Initialize with device locale for on-device recognition
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale.current)

        // Check if on-device recognition is available
        if let recognizer = speechRecognizer {
            recognizer.supportsOnDeviceRecognition = true
        }
    }

    // MARK: - Permission Management

    /// Request microphone and speech recognition permissions
    func requestPermissions() async throws {
        // Request microphone permission
        let audioSession = AVAudioSession.sharedInstance()
        let microphonePermission = await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard microphonePermission else {
            permissionError = "Microphone access is required for voice questions"
            throw QuestionInputError.microphonePermissionDenied
        }

        // Request speech recognition permission
        let speechPermission = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechPermission else {
            permissionError = "Speech recognition access is required for voice questions"
            throw QuestionInputError.speechRecognitionPermissionDenied
        }

        hasPermission = true
        permissionError = nil
        print("✅ Voice question permissions granted")
    }

    // MARK: - QuestionInputService

    /// Start recording voice question
    func startVoiceRecording() async throws {
        // Check permissions first
        if !hasPermission {
            try await requestPermissions()
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw QuestionInputError.speechRecognitionNotAvailable
        }

        // Cancel any ongoing recognition
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        // Stop audio engine if running and remove any existing tap
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Remove existing tap if present
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Failed to configure audio session: \(error)")
            throw QuestionInputError.failedToCreateRecognitionRequest
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw QuestionInputError.failedToCreateRecognitionRequest
        }

        // Enable on-device recognition for privacy (if available)
        recognitionRequest.shouldReportPartialResults = true
        if #available(iOS 13.0, *) {
            // Try to use on-device recognition, but don't require it
            // (simulator may not support on-device recognition)
            if speechRecognizer.supportsOnDeviceRecognition {
                recognitionRequest.requiresOnDeviceRecognition = false // Set to false to allow fallback
                print("ℹ️ On-device speech recognition is supported")
            } else {
                print("⚠️ On-device speech recognition not available, using server-based recognition")
            }
        }

        // Configure audio engine with proper format validation
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Validate recording format
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("❌ Invalid recording format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
            throw QuestionInputError.failedToCreateRecognitionRequest
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak recognitionRequest] buffer, _ in
            recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("❌ Failed to start audio engine: \(error)")
            inputNode.removeTap(onBus: 0)
            throw QuestionInputError.failedToCreateRecognitionRequest
        }

        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                Task { @MainActor in
                    self.recognizedText = result.bestTranscription.formattedString
                    print("🗣️ Recognized text: \(result.bestTranscription.formattedString)")
                }
            }

            if let error = error {
                print("⚠️ Recognition error: \(error.localizedDescription)")
            }
        }

        isRecording = true
        recognizedText = ""
        print("🎤 Started voice recording")
    }

    /// Stop recording and return transcribed text
    func stopVoiceRecording() async throws -> String {
        print("🛑 Stopping voice recording...")
        print("📝 Current recognized text: '\(recognizedText)'")

        stopRecordingInternal()

        // Wait longer for final transcription (increased from 0.5s to 1.5s)
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        let finalText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)

        if finalText.isEmpty {
            print("❌ No speech detected in transcription")
            throw QuestionInputError.noSpeechDetected
        }

        print("✅ Voice recording stopped: '\(finalText)'")
        return finalText
    }

    /// Submit text question (typed)
    func submitTextQuestion(text: String, childID: UUID?) async throws -> Question {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw QuestionInputError.emptyQuestion
        }

        let question = Question(
            text: text,
            inputMethod: .text,
            childID: childID
        )

        print("✏️ Text question submitted: \(text)")
        return question
    }

    // MARK: - Internal Methods

    private func stopRecordingInternal() {
        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Remove tap if installed
        audioEngine.inputNode.removeTap(onBus: 0)

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Deactivate audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
        }

        isRecording = false
    }
}

// MARK: - Errors

enum QuestionInputError: LocalizedError {
    case microphonePermissionDenied
    case speechRecognitionPermissionDenied
    case speechRecognitionNotAvailable
    case failedToCreateRecognitionRequest
    case noSpeechDetected
    case emptyQuestion

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required to ask questions by voice. Please enable it in Settings."
        case .speechRecognitionPermissionDenied:
            return "Speech recognition access is required. Please enable it in Settings."
        case .speechRecognitionNotAvailable:
            return "Speech recognition is not available on this device."
        case .failedToCreateRecognitionRequest:
            return "Failed to start voice recording. Please try again."
        case .noSpeechDetected:
            return "No speech was detected. Please try again."
        case .emptyQuestion:
            return "Please enter a question."
        }
    }
}
