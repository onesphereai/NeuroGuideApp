//
//  BiometricAuthService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation

/// Protocol defining biometric authentication operations
protocol BiometricAuthService {
    /// Check if biometric authentication is available
    func isBiometricAvailable() -> Bool

    /// Get the type of biometric authentication available
    func biometricType() -> BiometricType

    /// Authenticate user with biometric (Face ID or Touch ID)
    /// - Parameter reason: Reason to show to the user
    /// - Returns: True if authentication succeeded
    func authenticate(reason: String) async throws -> Bool

    /// Check if biometric authentication is enabled in app settings
    func isEnabled() -> Bool

    /// Enable or disable biometric authentication
    /// - Parameter enabled: Whether to enable biometric auth
    func setEnabled(_ enabled: Bool) throws
}

/// Types of biometric authentication
enum BiometricType {
    case faceID
    case touchID
    case none

    var displayName: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "None"
        }
    }

    var iconName: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock"
        }
    }
}
