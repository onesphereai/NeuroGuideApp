//
//  ChildCameraService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System (Child Camera - Rear)
//

import Foundation
import AVFoundation
import CoreImage
import Combine

/// Service for capturing video frames from rear camera (child)
/// Processes at full frame rate (30fps) for arousal detection
@MainActor
class ChildCameraService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isCapturing = false
    @Published private(set) var lastFrameTime: Date?

    // MARK: - Private Properties

    private var videoOutput: AVCaptureVideoDataOutput?
    private let outputQueue = DispatchQueue(label: "com.neuroguide.camera.child")
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .priorityRequestLow: true
    ])

    private var frameHandler: ((CGImage) -> Void)?
    private weak var captureSession: AVCaptureSession?
    private var videoInput: AVCaptureDeviceInput?

    // MARK: - Setup

    /// Setup child camera (rear camera)
    /// - Parameters:
    ///   - session: The multi-cam session to add inputs/outputs to
    ///   - position: Camera position (should be .back)
    func setup(session: AVCaptureSession, position: AVCaptureDevice.Position) async throws {
        self.captureSession = session

        session.beginConfiguration()

        // Get rear camera device
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
        }

        session.commitConfiguration()

        print("✅ Child camera (rear) configured")
    }

    // MARK: - Capture Control

    func startCapture(frameHandler: @escaping (CGImage) -> Void) {
        self.frameHandler = frameHandler
        isCapturing = true
        print("▶️ Child camera capture started")
    }

    func stopCapture() {
        frameHandler = nil
        isCapturing = false
        print("⏸️ Child camera capture stopped")
    }

    // MARK: - Preview Port

    /// Get the video output port for preview layer connection
    func getVideoOutputPort() -> AVCaptureInput.Port? {
        return videoInput?.ports(for: .video, sourceDeviceType: .builtInWideAngleCamera, sourceDevicePosition: .back).first
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ChildCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
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
