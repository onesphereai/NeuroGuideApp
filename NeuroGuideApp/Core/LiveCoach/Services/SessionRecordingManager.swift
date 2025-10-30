//
//  SessionRecordingManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Unit 5 - Live Coach Record-First Flow
//

import Foundation
import AVFoundation
import UIKit
import Combine

/// Manages dual camera recording for Live Coach sessions
@MainActor
class SessionRecordingManager: ObservableObject {
    // MARK: - Singleton

    static let shared = SessionRecordingManager()

    // MARK: - Published Properties

    @Published private(set) var isRecording = false
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published private(set) var batteryLevel: Float = 1.0
    @Published private(set) var batteryWarning: String?

    // MARK: - Private Properties

    private var childWriter: AVAssetWriter?
    private var parentWriter: AVAssetWriter?
    private var childVideoInput: AVAssetWriterInput?
    private var parentVideoInput: AVAssetWriterInput?
    private var childAudioInput: AVAssetWriterInput?

    private var recordingStartTime: Date?
    private let maxRecordingDuration: TimeInterval = 60.0  // 1 minute max

    private var recordingTimer: Timer?
    private var childOutputURL: URL?
    private var parentOutputURL: URL?

    // MARK: - Initialization

    private init() {
        setupBatteryMonitoring()
    }

    // MARK: - Battery Monitoring

    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )

        updateBatteryLevel()
    }

    @objc private func batteryLevelChanged() {
        updateBatteryLevel()
    }

    private func updateBatteryLevel() {
        batteryLevel = UIDevice.current.batteryLevel

        if batteryLevel < 0.20 && batteryLevel > 0 {  // -1 means unknown
            batteryWarning = "Battery is below 20%. Recording may drain battery quickly."
        } else {
            batteryWarning = nil
        }
    }

    // MARK: - Recording

    /// Start dual camera recording
    func startRecording(
        childSession: AVCaptureSession,
        parentSession: AVCaptureSession
    ) async throws -> (childURL: URL, parentURL: URL) {
        guard !isRecording else {
            throw RecordingError.alreadyRecording
        }

        // Check battery
        if batteryLevel < 0.10 && batteryLevel > 0 {
            throw RecordingError.batteryTooLow
        }

        // Create output URLs
        let childURL = createTempVideoURL(prefix: "child")
        let parentURL = createTempVideoURL(prefix: "parent")

        self.childOutputURL = childURL
        self.parentOutputURL = parentURL

        // Setup writers
        try setupWriter(for: childSession, outputURL: childURL, isChild: true)
        try setupWriter(for: parentSession, outputURL: parentURL, isChild: false)

        // Start recording
        guard let childWriter = childWriter, let parentWriter = parentWriter else {
            throw RecordingError.failedToSetupWriter
        }

        childWriter.startWriting()
        parentWriter.startWriting()

        recordingStartTime = Date()
        isRecording = true

        // Start duration timer
        startDurationTimer()

        print("📹 Started dual camera recording")
        print("   Child: \(childURL.path)")
        print("   Parent: \(parentURL.path)")

        // Auto-stop after max duration
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(maxRecordingDuration * 1_000_000_000))
            await self?.stopRecording()
        }

        return (childURL, parentURL)
    }

    /// Stop recording
    func stopRecording() async -> (childURL: URL, parentURL: URL)? {
        guard isRecording else { return nil }

        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Stop writers
        guard let childWriter = childWriter,
              let parentWriter = parentWriter,
              let childURL = childOutputURL,
              let parentURL = parentOutputURL else {
            return nil
        }

        await withCheckedContinuation { continuation in
            var completed = 0

            childVideoInput?.markAsFinished()
            childAudioInput?.markAsFinished()
            parentVideoInput?.markAsFinished()

            childWriter.finishWriting {
                completed += 1
                if completed == 2 {
                    continuation.resume()
                }
            }

            parentWriter.finishWriting {
                completed += 1
                if completed == 2 {
                    continuation.resume()
                }
            }
        }

        // Clean up
        self.childWriter = nil
        self.parentWriter = nil
        self.childVideoInput = nil
        self.parentVideoInput = nil
        self.childAudioInput = nil
        self.recordingStartTime = nil

        let duration = recordingDuration
        recordingDuration = 0

        print("✅ Stopped recording after \(String(format: "%.1f", duration))s")
        print("   Child video: \(childURL.path)")
        print("   Parent video: \(parentURL.path)")

        return (childURL, parentURL)
    }

    /// Cancel recording and delete files
    func cancelRecording() async {
        guard isRecording else { return }

        let urls = await stopRecording()

        // Delete the files
        if let (childURL, parentURL) = urls {
            try? FileManager.default.removeItem(at: childURL)
            try? FileManager.default.removeItem(at: parentURL)
            print("🗑️ Cancelled recording - files deleted")
        }
    }

    // MARK: - Writer Setup

    private func setupWriter(
        for session: AVCaptureSession,
        outputURL: URL,
        isChild: Bool
    ) throws {
        // Create asset writer
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        // Video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1280,
            AVVideoHeightKey: 720,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2_000_000,  // 2 Mbps
                AVVideoMaxKeyFrameIntervalKey: 30
            ]
        ]

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true

        if writer.canAdd(videoInput) {
            writer.add(videoInput)
        }

        // Audio settings (only for child camera)
        if isChild {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 64000
            ]

            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput.expectsMediaDataInRealTime = true

            if writer.canAdd(audioInput) {
                writer.add(audioInput)
                self.childAudioInput = audioInput
            }
        }

        // Store writer and input
        if isChild {
            self.childWriter = writer
            self.childVideoInput = videoInput
        } else {
            self.parentWriter = writer
            self.parentVideoInput = videoInput
        }

        // Setup capture session output for this writer
        setupCaptureOutput(for: session, writer: writer, videoInput: videoInput, audioInput: isChild ? childAudioInput : nil)
    }

    private func setupCaptureOutput(
        for session: AVCaptureSession,
        writer: AVAssetWriter,
        videoInput: AVAssetWriterInput,
        audioInput: AVAssetWriterInput?
    ) {
        // Add video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(
            SampleBufferDelegate(writer: writer, videoInput: videoInput, audioInput: audioInput),
            queue: DispatchQueue(label: "com.neuroguide.recording")
        )

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // Add audio data output (if audio input exists)
        if let audioInput = audioInput {
            let audioOutput = AVCaptureAudioDataOutput()
            audioOutput.setSampleBufferDelegate(
                SampleBufferDelegate(writer: writer, videoInput: videoInput, audioInput: audioInput),
                queue: DispatchQueue(label: "com.neuroguide.audio")
            )

            if session.canAddOutput(audioOutput) {
                session.addOutput(audioOutput)
            }
        }
    }

    // MARK: - Duration Timer

    private func startDurationTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }

            Task { @MainActor in
                self.recordingDuration = Date().timeIntervalSince(startTime)

                // Auto-stop at max duration
                if self.recordingDuration >= self.maxRecordingDuration {
                    await self.stopRecording()
                }
            }
        }
    }

    // MARK: - Utilities

    private func createTempVideoURL(prefix: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "\(prefix)_\(UUID().uuidString).mp4"
        return tempDir.appendingPathComponent(filename)
    }

    /// Clean up old temp videos (older than 24 hours)
    static func cleanupOldTempVideos() {
        let tempDir = FileManager.default.temporaryDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let now = Date()
        let cutoff = now.addingTimeInterval(-24 * 60 * 60)  // 24 hours ago

        for fileURL in files {
            guard fileURL.pathExtension == "mp4" else { continue }

            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let creationDate = attributes[.creationDate] as? Date,
               creationDate < cutoff {
                try? FileManager.default.removeItem(at: fileURL)
                print("🗑️ Cleaned up old temp video: \(fileURL.lastPathComponent)")
            }
        }
    }
}

// MARK: - Sample Buffer Delegate

private class SampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    private weak var writer: AVAssetWriter?
    private weak var videoInput: AVAssetWriterInput?
    private weak var audioInput: AVAssetWriterInput?
    private var sessionStartTime: CMTime?

    init(writer: AVAssetWriter, videoInput: AVAssetWriterInput, audioInput: AVAssetWriterInput?) {
        self.writer = writer
        self.videoInput = videoInput
        self.audioInput = audioInput
        super.init()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }

        // Initialize session start time
        if sessionStartTime == nil {
            sessionStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            writer?.startSession(atSourceTime: sessionStartTime!)
        }

        // Write video samples
        if output is AVCaptureVideoDataOutput {
            if let videoInput = videoInput, videoInput.isReadyForMoreMediaData {
                videoInput.append(sampleBuffer)
            }
        }

        // Write audio samples
        if output is AVCaptureAudioDataOutput {
            if let audioInput = audioInput, audioInput.isReadyForMoreMediaData {
                audioInput.append(sampleBuffer)
            }
        }
    }
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case alreadyRecording
    case batteryTooLow
    case failedToSetupWriter
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "A recording is already in progress."
        case .batteryTooLow:
            return "Battery is too low to start recording. Please charge your device."
        case .failedToSetupWriter:
            return "Failed to setup video recording. Please try again."
        case .recordingFailed:
            return "Recording failed. Please try again."
        }
    }
}
