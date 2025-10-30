//
//  BiometricAuthManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import Foundation
import LocalAuthentication

/// Implementation of BiometricAuthService using LocalAuthentication framework
class BiometricAuthManager: BiometricAuthService {

    // MARK: - Singleton

    static let shared = BiometricAuthManager()

    // MARK: - Properties

    private let keychainService: KeychainService
    private let biometricEnabledKey = "com.neuroguide.biometric.enabled"

    // MARK: - Initialization

    init(keychainService: KeychainService = KeychainManager.shared) {
        self.keychainService = keychainService
    }

    // MARK: - Availability

    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    // MARK: - Authentication

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()

        // Set context properties
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"

        // Check if biometric is available
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                throw BiometricAuthError.from(laError: LAError(_nsError: error))
            }
            throw BiometricAuthError.notAvailable
        }

        // Perform authentication
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            throw BiometricAuthError.from(laError: error)
        } catch {
            throw BiometricAuthError.other(error)
        }
    }

    // MARK: - Settings

    func isEnabled() -> Bool {
        return (try? keychainService.load(key: biometricEnabledKey)) != nil
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            // Save enabled flag to keychain
            let data = Data([1])
            try keychainService.save(
                data: data,
                forKey: biometricEnabledKey,
                accessible: .afterFirstUnlockThisDeviceOnly
            )
        } else {
            // Remove enabled flag from keychain
            try keychainService.delete(key: biometricEnabledKey)
        }
    }
}

// MARK: - Convenience Methods

extension BiometricAuthManager {
    /// Authenticate with custom error handling
    func authenticateWithFallback(reason: String) async -> Result<Bool, BiometricAuthError> {
        do {
            let success = try await authenticate(reason: reason)
            return .success(success)
        } catch let error as BiometricAuthError {
            return .failure(error)
        } catch {
            return .failure(.other(error))
        }
    }

    /// Check if device has biometric capability and user has enrolled
    var canUseBiometric: Bool {
        return isBiometricAvailable() && biometricType() != .none
    }

    /// Get user-facing description of biometric availability
    func availabilityDescription() -> String {
        let type = biometricType()

        guard isBiometricAvailable() else {
            if type == .none {
                return "This device does not support biometric authentication"
            }
            return "\(type.displayName) is not set up. Go to Settings to enable it."
        }

        return "\(type.displayName) is available"
    }
}
