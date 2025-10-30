//
//  ParentCameraService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System (Parent Camera - Front)
//

import Foundation
import AVFoundation
import CoreImage
import Combine

/// Service for capturing video frames from front camera (parent)
/// Processes at reduced frame rate (15fps) for parent state detection
@MainActor
class ParentCameraService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isCapturing = false
    @Published private(set) var lastFrameTime: Date?

    // MARK: - Private Properties

    private var videoOutput: AVCaptureVideoDataOutput?
    private let outputQueue = DispatchQueue(label: "com.neuroguide.camera.parent")
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .priorityRequestLow: true
    ])

    private var frameHandler: ((CGImage) -> Void)?
    private weak var captureSession: AVCaptureSession?
    private var videoInput: AVCaptureDeviceInput?

    // Frame rate throttling (process every other frame for ~15fps)
    private var frameCounter = 0
    private let frameSkipInterval = 2 // Process every 2nd frame

    // MARK: - Setup

    /// Setup parent camera (front camera)
    /// - Parameters:
    ///   - session: The multi-cam session to add inputs/outputs to
    ///   - position: Camera position (should be .front)
    func setup(session: AVCaptureSession, position: AVCaptureDevice.Position) async throws {
        self.captureSession = session

        session.beginConfiguration()

        // Get front camera device
        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: position
        ) else {
            session.commitConfiguration()
            throw CameraCaptureError.deviceNotFound
        }

        // Create video input
        let input = try AVCaptureDeviceInput(device: videoDevice)
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw CameraCaptureError.cannotAddInput
        }
        session.addInput(input)
        self.videoInput = input

        // Create video output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: outputQueue)
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            throw CameraCaptureError.cannotAddOutput
        }
        session.addOutput(output)
        self.videoOutput = output

        // Set orientation
        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            // Mirror front camera for natural preview
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        session.commitConfiguration()

        print("✅ Parent camera (front) configured")
    }

    // MARK: - Capture Control

    func startCapture(frameHandler: @escaping (CGImage) -> Void) {
        self.frameHandler = frameHandler
        self.frameCounter = 0
        isCapturing = true
        print("▶️ Parent camera capture started")
    }

    func stopCapture() {
        frameHandler = nil
        isCapturing = false
        frameCounter = 0
        print("⏸️ Parent camera capture stopped")
    }

    // MARK: - Preview Port

    /// Get the video output port for preview layer connection
    func getVideoOutputPort() -> AVCaptureInput.Port? {
        return videoInput?.ports(for: .video, sourceDeviceType: .builtInWideAngleCamera, sourceDevicePosition: .front).first
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ParentCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Frame rate throttling - process every Nth frame
        Task { @MainActor in
            self.frameCounter += 1

            guard self.frameCounter % self.frameSkipInterval == 0 else {
                return
            }
        }

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
