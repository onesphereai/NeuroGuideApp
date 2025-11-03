//
//  DualCameraManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System (Dual Camera Support)
//

import Foundation
import AVFoundation
import Combine

/// Device capability for multi-camera support
enum CameraCapability {
    case dualCameraSupported
    case singleCameraOnly

    var description: String {
        switch self {
        case .dualCameraSupported:
            return "Dual camera supported"
        case .singleCameraOnly:
            return "Single camera only"
        }
    }
}

/// Manager for coordinating dual camera capture
/// Handles device compatibility and orchestrates child + parent camera services
@MainActor
class DualCameraManager: ObservableObject {
    // MARK: - Singleton

    static let shared = DualCameraManager()

    // MARK: - Published Properties

    @Published private(set) var capability: CameraCapability
    @Published private(set) var isCapturing = false

    // MARK: - Private Properties

    private var multiCamSession: AVCaptureMultiCamSession?
    private var childCameraService: ChildCameraService?
    private var parentCameraService: ParentCameraService?

    // MARK: - Initialization

    private init() {
        self.capability = Self.checkDeviceCompatibility()
        print("📱 Device camera capability: \(capability.description)")
    }

    // MARK: - Device Compatibility

    /// Check if device supports multi-camera capture
    static func supportsMultiCam() -> Bool {
        if #available(iOS 13.0, *) {
            return AVCaptureMultiCamSession.isMultiCamSupported
        }
        return false
    }

    /// Check device compatibility and return capability level
    static func checkDeviceCompatibility() -> CameraCapability {
        // Check if multi-cam is supported on this device
        guard supportsMultiCam() else {
            return .singleCameraOnly
        }

        // Check if both front and rear cameras are available
        let frontCam = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        )
        let rearCam = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )

        if frontCam != nil && rearCam != nil {
            return .dualCameraSupported
        }

        return .singleCameraOnly
    }

    // MARK: - Session Management

    /// Setup dual camera session
    /// - Returns: True if setup successful, false otherwise
    func setupDualCamera() async throws -> Bool {
        guard capability == .dualCameraSupported else {
            print("⚠️ Device does not support dual camera")
            return false
        }

        // Create multi-cam session
        if #available(iOS 13.0, *) {
            let session = AVCaptureMultiCamSession()
            multiCamSession = session

            // Initialize camera services
            childCameraService = ChildCameraService()
            parentCameraService = ParentCameraService()

            // Setup child camera (rear)
            try await childCameraService?.setup(session: session, position: .back)

            // Setup parent camera (front)
            try await parentCameraService?.setup(session: session, position: .front)

            print("✅ Dual camera setup complete")
            return true
        }

        return false
    }

    /// Start dual camera capture
    func startCapture(
        childFrameHandler: @escaping (CGImage) -> Void,
        parentFrameHandler: @escaping (CGImage) -> Void
    ) {
        guard let multiCamSession = multiCamSession else {
            print("❌ Multi-cam session not initialized")
            return
        }

        // Start child camera capture
        childCameraService?.startCapture(frameHandler: childFrameHandler)

        // Start parent camera capture
        parentCameraService?.startCapture(frameHandler: parentFrameHandler)

        // Start session if not running
        if !multiCamSession.isRunning {
            Task.detached { [weak self] in
                multiCamSession.startRunning()

                await MainActor.run {
                    self?.isCapturing = true
                }
                print("▶️ Dual camera capture started")
            }
        }
    }

    /// Stop dual camera capture
    func stopCapture() {
        childCameraService?.stopCapture()
        parentCameraService?.stopCapture()

        if let session = multiCamSession, session.isRunning {
            Task.detached { [weak self] in
                session.stopRunning()

                await MainActor.run {
                    self?.isCapturing = false
                    // Clean up the session and camera services
                    self?.cleanupSession()
                }
                print("⏸️ Dual camera capture stopped")
            }
        } else {
            // Clean up even if session wasn't running
            cleanupSession()
        }
    }

    /// Clean up camera session and services
    private func cleanupSession() {
        // Remove all inputs and outputs from the session
        if let session = multiCamSession {
            session.beginConfiguration()

            // Remove all inputs
            for input in session.inputs {
                session.removeInput(input)
            }

            // Remove all outputs
            for output in session.outputs {
                session.removeOutput(output)
            }

            session.commitConfiguration()
        }

        // Reset references
        multiCamSession = nil
        childCameraService = nil
        parentCameraService = nil

        print("🧹 Camera session cleaned up")
    }

    // MARK: - Preview Access

    /// Get child camera capture session (for preview)
    func getChildCaptureSession() -> AVCaptureSession? {
        return multiCamSession
    }

    /// Get parent camera capture session (for preview)
    func getParentCaptureSession() -> AVCaptureSession? {
        return multiCamSession
    }

    // MARK: - Fallback Mode

    /// Setup single camera fallback (child camera only)
    func setupSingleCameraFallback() async throws {
        // For single camera mode, use existing CameraCaptureService
        // This will be handled by LiveCoachViewModel
        print("⚠️ Using single camera fallback mode")
    }
}

// MARK: - Errors

enum DualCameraError: LocalizedError {
    case multiCamNotSupported
    case cameraNotAvailable
    case setupFailed(Error)

    var errorDescription: String? {
        switch self {
        case .multiCamNotSupported:
            return "Multi-camera is not supported on this device"
        case .cameraNotAvailable:
            return "Required camera is not available"
        case .setupFailed(let error):
            return "Dual camera setup failed: \(error.localizedDescription)"
        }
    }
}
