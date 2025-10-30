//
//  BiometricAuthError.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation
import LocalAuthentication

/// Errors that can occur during biometric authentication
enum BiometricAuthError: LocalizedError {
    case notAvailable
    case notEnrolled
    case lockout
    case userCancel
    case userFallback
    case systemCancel
    case passcodeNotSet
    case authenticationFailed
    case invalidContext
    case other(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric authentication is enrolled (Face ID or Touch ID)"
        case .lockout:
            return "Biometric authentication is locked due to too many failed attempts"
        case .userCancel:
            return "User canceled the authentication"
        case .userFallback:
            return "User selected fallback authentication method"
        case .systemCancel:
            return "System canceled the authentication"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .authenticationFailed:
            return "Authentication failed"
        case .invalidContext:
            return "Authentication context is invalid"
        case .other(let error):
            return "Authentication error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAvailable:
            return "This device does not support biometric authentication."
        case .notEnrolled:
            return "Set up Face ID or Touch ID in device Settings."
        case .lockout:
            return "Enter your device passcode to unlock biometric authentication."
        case .userCancel:
            return "Try again when ready."
        case .userFallback:
            return "Use the fallback authentication method."
        case .systemCancel:
            return "Try again. The authentication was interrupted."
        case .passcodeNotSet:
            return "Set a device passcode in Settings to enable biometric authentication."
        case .authenticationFailed:
            return "Make sure you're using the correct biometric (face or fingerprint)."
        case .invalidContext:
            return "Restart the app and try again."
        case .other:
            return "Try again or contact support if the issue persists."
        }
    }

    /// Convert LAError to BiometricAuthError
    static func from(laError: LAError) -> BiometricAuthError {
        switch laError.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .authenticationFailed:
            return .authenticationFailed
        case .invalidContext:
            return .invalidContext
        default:
            return .other(laError)
        }
    }
}
