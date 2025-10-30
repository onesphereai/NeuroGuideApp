//
//  EmotionServices.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation
import Combine
import CoreGraphics

/// Service for managing emotion interface consent and state
@MainActor
protocol EmotionInterfaceService: AnyObject {
    /// Whether emotion interface is currently enabled
    var isEnabled: Bool { get }

    /// Current consent status
    var consentStatus: EmotionConsentStatus { get }

    /// Publisher for consent status changes
    var consentPublisher: AnyPublisher<EmotionConsentStatus, Never> { get }

    /// Enable emotion interface (grants consent)
    func enable() async throws

    /// Disable emotion interface (revokes consent)
    func disable() async throws

    /// Show demo video
    func showDemoVideo() async

    /// Mark model card as viewed
    func markModelCardViewed() async

    /// Get current model card
    func getModelCard() -> EmotionModelCard

    /// Enable parent emotion monitoring
    func enableParentMonitoring() async throws

    /// Disable parent emotion monitoring
    func disableParentMonitoring() async throws
}

/// Service for classifying emotion states
@MainActor
protocol EmotionStateClassifierService: AnyObject {
    /// Classify emotion from image
    func classifyEmotion(from image: CGImage) async throws -> EmotionClassification

    /// Get current emotion state
    func getCurrentEmotion() -> EmotionClassification?

    /// Clear emotion history
    func clearHistory()
}

/// Service for parent validation of emotion predictions
@MainActor
protocol ValidationService: AnyObject {
    /// Submit validation (parent confirms or corrects)
    func submitValidation(predicted: EmotionLabel, actual: EmotionLabel, childID: UUID) async throws

    /// Get validation history for child
    func getValidationHistory(childID: UUID) async throws -> [ValidationRecord]

    /// Get model improvement statistics
    func getImprovementStats(childID: UUID) async throws -> CalibrationStats

    /// Whether validation prompt should be shown
    func shouldShowValidationPrompt() -> Bool
}

/// Service for managing emotion expression profiles
@MainActor
protocol EmotionProfileService: AnyObject {
    /// Get emotion expression profile for child
    func getProfile(childID: UUID) async throws -> EmotionExpressionProfile

    /// Update emotion expression profile
    func updateProfile(childID: UUID, profile: EmotionExpressionProfile) async throws

    /// Whether profile is complete
    func isProfileComplete(childID: UUID) async -> Bool
}

/// Service for emotion model calibration
@MainActor
protocol CalibrationService: AnyObject {
    /// Whether model is calibrated for child
    func isCalibrated(childID: UUID) async -> Bool

    /// Get calibration status
    func getCalibrationStatus(childID: UUID) async throws -> CalibrationStatus

    /// Recalibrate model for child
    func recalibrate(childID: UUID) async throws

    /// Reset calibration (start over)
    func resetCalibration(childID: UUID) async throws
}

// MARK: - Errors

enum EmotionInterfaceError: LocalizedError {
    case consentNotGranted
    case modelNotLoaded
    case calibrationFailed(Error)
    case profileIncomplete
    case validationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .consentNotGranted:
            return "Emotion interface consent not granted"
        case .modelNotLoaded:
            return "Emotion detection model not loaded"
        case .calibrationFailed(let error):
            return "Calibration failed: \(error.localizedDescription)"
        case .profileIncomplete:
            return "Emotion expression profile is incomplete"
        case .validationFailed(let error):
            return "Validation submission failed: \(error.localizedDescription)"
        }
    }
}
