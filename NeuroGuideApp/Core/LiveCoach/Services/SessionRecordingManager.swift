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

    // Track outputs we add so we can remove them later
    private var childVideoOutput: AVCaptureVideoDataOutput?
    private var parentVideoOutput: AVCaptureVideoDataOutput?
    private var childAudioOutput: AVCaptureAudioDataOutput?
    private var childSession: AVCaptureSession?
    private var parentSession: AVCaptureSession?

    // Retain delegates (important - otherwise they get deallocated!)
    private var childVideoDelegate: SampleBufferDelegate?
    private var parentVideoDelegate: SampleBufferDelegate?
    private var childAudioDelegate: SampleBufferDelegate?

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
        self.childSession = childSession
        self.parentSession = parentSession

        // Setup writers
        try setupWriter(for: childSession, outputURL: childURL, isChild: true)
        try setupWriter(for: parentSession, outputURL: parentURL, isChild: false)

        // Start recording
        guard let childWriter = childWriter, let parentWriter = parentWriter else {
            throw RecordingError.failedToSetupWriter
        }

        print("✅ Starting AVAssetWriters...")
        childWriter.startWriting()
        print("   Child writer status: \(childWriter.status.rawValue)")
        parentWriter.startWriting()
        print("   Parent writer status: \(parentWriter.status.rawValue)")

        recordingStartTime = Date()
        isRecording = true

        // Start duration timer
        startDurationTimer()

        print("📹 Started dual camera recording (isRecording=true)")
        print("   Child: \(childURL.path)")
        print("   Parent: \(parentURL.path)")
        print("   Max duration: \(maxRecordingDuration)s")

        // Auto-stop after max duration
        Task { [weak self] in
            print("⏰ Auto-stop timer started for \(self?.maxRecordingDuration ?? 0)s")
            try? await Task.sleep(nanoseconds: UInt64(maxRecordingDuration * 1_000_000_000))
            print("⏰ Auto-stop timer fired")
            await self?.stopRecording()
        }

        return (childURL, parentURL)
    }

    /// Stop recording
    func stopRecording() async -> (childURL: URL, parentURL: URL)? {
        guard isRecording else {
            print("⚠️ stopRecording called but isRecording=false")
            return nil
        }

        print("🛑 Stopping recording (isRecording was true)")
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Stop writers - check what's missing
        guard let childWriter = childWriter else {
            print("❌ childWriter is nil!")
            return nil
        }
        guard let parentWriter = parentWriter else {
            print("❌ parentWriter is nil!")
            return nil
        }
        guard let childURL = childOutputURL else {
            print("❌ childOutputURL is nil!")
            return nil
        }
        guard let parentURL = parentOutputURL else {
            print("❌ parentOutputURL is nil!")
            return nil
        }

        print("✅ All recording components present, stopping writers...")

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

        // Remove recording outputs from sessions
        if let childSession = childSession, let childVideoOutput = childVideoOutput {
            childSession.beginConfiguration()
            if childSession.outputs.contains(childVideoOutput) {
                childSession.removeOutput(childVideoOutput)
                print("🔄 Removed child video output")
            }
            if let audioOutput = childAudioOutput, childSession.outputs.contains(audioOutput) {
                childSession.removeOutput(audioOutput)
                print("🔄 Removed child audio output")
            }
            childSession.commitConfiguration()
        }

        if let parentSession = parentSession, let parentVideoOutput = parentVideoOutput {
            parentSession.beginConfiguration()
            if parentSession.outputs.contains(parentVideoOutput) {
                parentSession.removeOutput(parentVideoOutput)
                print("🔄 Removed parent video output")
            }
            parentSession.commitConfiguration()
        }

        // Clean up
        self.childWriter = nil
        self.parentWriter = nil
        self.childVideoInput = nil
        self.parentVideoInput = nil
        self.childAudioInput = nil
        self.recordingStartTime = nil
        self.childVideoOutput = nil
        self.parentVideoOutput = nil
        self.childAudioOutput = nil
        self.childSession = nil
        self.parentSession = nil

        // Clean up delegates
        self.childVideoDelegate = nil
        self.parentVideoDelegate = nil
        self.childAudioDelegate = nil

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
        print("🔧 Setting up \(isChild ? "child" : "parent") writer for: \(outputURL.lastPathComponent)")

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
            print("✅ Child writer stored")
        } else {
            self.parentWriter = writer
            self.parentVideoInput = videoInput
            print("✅ Parent writer stored")
        }

        // Setup capture session output for this writer
        setupCaptureOutput(for: session, writer: writer, videoInput: videoInput, audioInput: isChild ? childAudioInput : nil, isChild: isChild)
        print("✅ Capture output setup complete for \(isChild ? "child" : "parent")")
    }

    private func setupCaptureOutput(
        for session: AVCaptureSession,
        writer: AVAssetWriter,
        videoInput: AVAssetWriterInput,
        audioInput: AVAssetWriterInput?,
        isChild: Bool
    ) {
        session.beginConfiguration()

        // DON'T remove existing outputs - keep preview outputs active
        // Just add our recording output alongside them

        // Add video data output for recording
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        // Create and RETAIN delegate (critical - otherwise it gets deallocated!)
        let videoDelegate = SampleBufferDelegate(writer: writer, videoInput: videoInput, audioInput: audioInput)
        videoOutput.setSampleBufferDelegate(
            videoDelegate,
            queue: DispatchQueue(label: "com.neuroguide.recording.\(UUID().uuidString)")
        )

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            // Store references to remove later
            if isChild {
                self.childVideoOutput = videoOutput
                self.childVideoDelegate = videoDelegate
            } else {
                self.parentVideoOutput = videoOutput
                self.parentVideoDelegate = videoDelegate
            }
            print("✅ Added video output for recording (keeping preview active)")
        } else {
            print("⚠️ Could not add video output for recording")
        }

        // Add audio data output (if audio input exists)
        if let audioInput = audioInput, isChild {
            let audioOutput = AVCaptureAudioDataOutput()

            // Create and RETAIN delegate
            let audioDelegate = SampleBufferDelegate(writer: writer, videoInput: videoInput, audioInput: audioInput)
            audioOutput.setSampleBufferDelegate(
                audioDelegate,
                queue: DispatchQueue(label: "com.neuroguide.audio.\(UUID().uuidString)")
            )

            if session.canAddOutput(audioOutput) {
                session.addOutput(audioOutput)
                self.childAudioOutput = audioOutput
                self.childAudioDelegate = audioDelegate
                print("✅ Added audio output for recording")
            } else {
                print("⚠️ Could not add audio output for recording")
            }
        }

        session.commitConfiguration()
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

        guard let writer = writer else { return }

        // Initialize session start time
        if sessionStartTime == nil {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

            // Only start session if writer is ready
            if writer.status == .writing {
                writer.startSession(atSourceTime: timestamp)
                sessionStartTime = timestamp  // Mark as started
                print("✅ Session started at time: \(timestamp.seconds)")
            } else {
                // Writer not ready yet, skip this frame and try again on next one
                print("⚠️ Writer not ready yet (status: \(writer.status.rawValue)), waiting...")
                return  // Don't append samples until session starts
            }
        }

        // Only write samples if session has been started
        guard sessionStartTime != nil else {
            return  // Session not started yet
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
