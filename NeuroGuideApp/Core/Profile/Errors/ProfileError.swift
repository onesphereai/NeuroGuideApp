//
//  ProfileError.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation

/// Errors related to child profile operations
enum ProfileError: LocalizedError {
    case profileNotFound
    case invalidAge(age: Int)
    case invalidName
    case saveFailed(underlying: Error)
    case loadFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case calibrationFailed(reason: String)
    case storageUnavailable
    case invalidTrigger(reason: String)
    case invalidStrategy(reason: String)

    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "Profile not found"
        case .invalidAge(let age):
            return "Age must be between 2 and 18 (got \(age))"
        case .invalidName:
            return "Please enter your child's name"
        case .saveFailed(let error):
            return "Failed to save profile: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load profile: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete profile: \(error.localizedDescription)"
        case .calibrationFailed(let reason):
            return "Calibration failed: \(reason)"
        case .storageUnavailable:
            return "Storage is currently unavailable"
        case .invalidTrigger(let reason):
            return "Invalid trigger: \(reason)"
        case .invalidStrategy(let reason):
            return "Invalid strategy: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .profileNotFound:
            return "Please create a new profile to get started."
        case .invalidAge:
            return "attune is designed for children ages 2-18."
        case .invalidName:
            return "Your child's name helps personalize the experience."
        case .saveFailed, .loadFailed, .deleteFailed:
            return "Please try again. If the problem persists, restart the app."
        case .calibrationFailed:
            return "You can skip calibration and try again later from Settings."
        case .storageUnavailable:
            return "Please check your device storage and try again."
        case .invalidTrigger:
            return "Please provide a description for the trigger."
        case .invalidStrategy:
            return "Please provide a description for the strategy."
        }
    }
}
