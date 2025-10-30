//
//  PermissionsManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 5 - Live Coach System
//

import Foundation
import AVFoundation
import Combine

/// Main implementation of PermissionsService
/// Manages camera and microphone permissions
@MainActor
class PermissionsManager: PermissionsService, ObservableObject {
    // MARK: - Singleton

    static let shared = PermissionsManager()

    // MARK: - Published Properties

    @Published private(set) var cameraStatus: PermissionStatus = .notDetermined
    @Published private(set) var microphoneStatus: PermissionStatus = .notDetermined

    // MARK: - Computed Properties

    var permissionsPublisher: AnyPublisher<PermissionUpdate, Never> {
        permissionsSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let permissionsSubject = PassthroughSubject<PermissionUpdate, Never>()

    // MARK: - Initialization

    init() {
        checkCurrentPermissions()
    }

    // MARK: - Permission Requests

    func requestCameraPermission() async -> Bool {
        // Check current status
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch currentStatus {
        case .authorized:
            updateCameraStatus(.granted)
            return true

        case .notDetermined:
            // Request permission
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            updateCameraStatus(granted ? .granted : .denied)
            return granted

        case .denied, .restricted:
            updateCameraStatus(currentStatus == .denied ? .denied : .restricted)
            return false

        @unknown default:
            updateCameraStatus(.denied)
            return false
        }
    }

    func requestMicrophonePermission() async -> Bool {
        // Check current status
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        switch currentStatus {
        case .authorized:
            updateMicrophoneStatus(.granted)
            return true

        case .notDetermined:
            // Request permission
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            updateMicrophoneStatus(granted ? .granted : .denied)
            return granted

        case .denied, .restricted:
            updateMicrophoneStatus(currentStatus == .denied ? .denied : .restricted)
            return false

        @unknown default:
            updateMicrophoneStatus(.denied)
            return false
        }
    }

    func requestAllPermissions() async -> (camera: Bool, microphone: Bool) {
        // Request both permissions concurrently
        async let cameraGranted = requestCameraPermission()
        async let micGranted = requestMicrophonePermission()

        let results = await (cameraGranted, micGranted)
        return results
    }

    // MARK: - Degradation Mode

    func getDegradationMode() -> DegradationMode? {
        let cameraGranted = (cameraStatus == .granted)
        let micGranted = (microphoneStatus == .granted)

        // Both granted - no degradation
        if cameraGranted && micGranted {
            return nil
        }

        // Camera only
        if cameraGranted && !micGranted {
            return .cameraOnly
        }

        // Microphone only
        if !cameraGranted && micGranted {
            return .microphoneOnly
        }

        // Both denied - manual only
        return .manualOnly
    }

    // MARK: - Private Methods

    private func checkCurrentPermissions() {
        // Check camera
        let cameraAuth = AVCaptureDevice.authorizationStatus(for: .video)
        cameraStatus = mapAVAuthorizationStatus(cameraAuth)

        // Check microphone
        let micAuth = AVCaptureDevice.authorizationStatus(for: .audio)
        microphoneStatus = mapAVAuthorizationStatus(micAuth)
    }

    private func mapAVAuthorizationStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .granted
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    private func updateCameraStatus(_ status: PermissionStatus) {
        cameraStatus = status
        permissionsSubject.send(PermissionUpdate(permissionType: .camera, status: status))
        print("📹 Camera permission: \(status.displayName)")
    }

    private func updateMicrophoneStatus(_ status: PermissionStatus) {
        microphoneStatus = status
        permissionsSubject.send(PermissionUpdate(permissionType: .microphone, status: status))
        print("🎤 Microphone permission: \(status.displayName)")
    }
}

// MARK: - Permission Helpers

extension PermissionsManager {
    /// Whether both permissions are granted
    var allPermissionsGranted: Bool {
        return cameraStatus == .granted && microphoneStatus == .granted
    }

    /// Whether any permissions are denied
    var anyPermissionDenied: Bool {
        return cameraStatus == .denied || microphoneStatus == .denied
    }

    /// Whether any permissions are restricted
    var anyPermissionRestricted: Bool {
        return cameraStatus == .restricted || microphoneStatus == .restricted
    }

    /// Human-readable permission summary
    var permissionSummary: String {
        if allPermissionsGranted {
            return "All permissions granted"
        }

        var denied: [String] = []
        if cameraStatus != .granted {
            denied.append("Camera")
        }
        if microphoneStatus != .granted {
            denied.append("Microphone")
        }

        if denied.isEmpty {
            return "Permissions not determined"
        } else {
            return "\(denied.joined(separator: " and ")) not available"
        }
    }
}
