//
//  CameraCaptureService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 5 - Live Coach System (Camera Integration)
//

import Foundation
import AVFoundation
import CoreImage
import Combine

/// Service for capturing video frames from the camera
/// Provides frames to ML pipeline for arousal detection
@MainActor
class CameraCaptureService: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = CameraCaptureService()

    // MARK: - Lifecycle

    deinit {
        removeInterruptionObservers()
    }

    // MARK: - Published Properties

    @Published private(set) var isCapturing = false
    @Published private(set) var lastFrameTime: Date?

    // MARK: - Private Properties

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let outputQueue = DispatchQueue(label: "com.neuroguide.camera.output")
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .priorityRequestLow: true
    ])

    private var frameHandler: ((CGImage) -> Void)?
    private var preferredPosition: AVCaptureDevice.Position = .front
    private nonisolated(unsafe) var interruptionObserver: NSObjectProtocol?
    private nonisolated(unsafe) var interruptionEndObserver: NSObjectProtocol?

    // MARK: - Setup

    func setup(position: AVCaptureDevice.Position = .front) async throws {
        preferredPosition = position

        // Configure session
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium  // 480p for balance of quality and performance

        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw CameraCaptureError.deviceNotFound
        }

        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        guard captureSession.canAddInput(videoInput) else {
            throw CameraCaptureError.cannotAddInput
        }
        captureSession.addInput(videoInput)

        // Add video output
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true  // Drop frames if processing is slow

        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraCaptureError.cannotAddOutput
        }
        captureSession.addOutput(videoOutput)

        // Set orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
        }

        captureSession.commitConfiguration()

        // Setup session interruption observers
        setupInterruptionObservers()

        print("✅ Camera capture configured")
    }

    // MARK: - Interruption Handling

    private func setupInterruptionObservers() {
        // Session interrupted (e.g., phone call, FaceTime)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionWasInterrupted,
            object: captureSession,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            if let reason = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? AVCaptureSession.InterruptionReason {
                switch reason {
                case .videoDeviceNotAvailableInBackground:
                    print("⚠️ Camera session interrupted: App in background")
                case .audioDeviceInUseByAnotherClient:
                    print("⚠️ Camera session interrupted: Audio device in use")
                case .videoDeviceInUseByAnotherClient:
                    print("⚠️ Camera session interrupted: Camera in use by another app")
                case .videoDeviceNotAvailableWithMultipleForegroundApps:
                    print("⚠️ Camera session interrupted: Multiple foreground apps")
                @unknown default:
                    print("⚠️ Camera session interrupted: Unknown reason")
                }
            }

            Task { @MainActor in
                self.isCapturing = false
            }
        }

        // Session interruption ended
        interruptionEndObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionInterruptionEnded,
            object: captureSession,
            queue: .main
        ) { [weak self] _ in
            print("✅ Camera session interruption ended")
            Task { @MainActor in
                self?.isCapturing = true
            }
        }
    }

    nonisolated private func removeInterruptionObservers() {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = interruptionEndObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Capture Control

    func startCapture(frameHandler: @escaping (CGImage) -> Void) {
        self.frameHandler = frameHandler

        if !captureSession.isRunning {
            // Start capture session on background queue to avoid blocking main thread
            Task.detached { [weak self] in
                guard let self = self else { return }

                self.captureSession.startRunning()

                await MainActor.run {
                    self.isCapturing = true
                }
                print("▶️ Camera capture started")
            }
        }
    }

    func stopCapture() {
        if captureSession.isRunning {
            // Stop capture session on background queue
            Task.detached { [weak self] in
                guard let self = self else { return }

                self.captureSession.stopRunning()

                await MainActor.run {
                    self.isCapturing = false
                    self.frameHandler = nil
                }
                print("⏸️ Camera capture stopped")
            }
        }
    }

    // MARK: - Preview Layer

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }

    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Extract image from sample buffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)

        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }

        // Call frame handler on main thread
        Task { @MainActor in
            self.lastFrameTime = Date()
            self.frameHandler?(cgImage)
        }
    }
}

// MARK: - Errors

enum CameraCaptureError: LocalizedError {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case captureSessionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Camera device not found"
        case .cannotAddInput:
            return "Cannot add camera input to session"
        case .cannotAddOutput:
            return "Cannot add video output to session"
        case .captureSessionFailed(let error):
            return "Camera capture failed: \(error.localizedDescription)"
        }
    }
}
