//
//  ProfileCreationViewModel.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation
import SwiftUI
import Combine

/// View model for profile creation wizard
@MainActor
class ProfileCreationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentStep: ProfileCreationStep = .basicInfo
    @Published var showError: Bool = false
    @Published var error: Error?
    @Published var isComplete: Bool = false

    // Basic Info
    @Published var name: String = ""
    @Published var age: Int = 5
    @Published var pronouns: String = ""
    @Published var photoData: Data?
    @Published var profileColor: String = "#4A90E2"  // Default blue

    // Sensory Preferences (Bolt 3.2)
    @Published var sensoryPreferences: SensoryPreferences = SensoryPreferences()
    @Published var specificSensoryTriggers: String = ""

    // Communication (Bolt 3.2)
    @Published var communicationMode: CommunicationMode = .verbal
    @Published var communicationNotes: String = ""
    @Published var alexithymiaSettings: AlexithymiaSettings = AlexithymiaSettings()

    // Triggers & Strategies (Bolt 3.3)
    @Published var triggers: [Trigger] = []
    @Published var strategies: [Strategy] = []

    // Calibration (will be used in Bolt 3.4)
    @Published var skipCalibration: Bool = false

    // MARK: - Dependencies

    private let profileManager: ChildProfileService

    // MARK: - State

    private var isEditingExistingProfile: Bool = false
    private var existingProfile: ChildProfile?

    // MARK: - Initialization

    init(profileManager: ChildProfileService = ChildProfileManager.shared, existingProfile: ChildProfile? = nil) {
        self.profileManager = profileManager

        // Load existing profile data if editing
        if let profile = existingProfile {
            isEditingExistingProfile = true
            self.existingProfile = profile
            loadProfile(profile)
        }
    }

    // MARK: - Profile Loading

    /// Load data from an existing profile for editing
    private func loadProfile(_ profile: ChildProfile) {
        // Basic Info
        name = profile.name
        age = profile.age
        pronouns = profile.pronouns ?? ""
        photoData = profile.photoData
        profileColor = profile.profileColor

        // Sensory Preferences
        sensoryPreferences = profile.sensoryPreferences
        specificSensoryTriggers = profile.sensoryPreferences.specificTriggers.joined(separator: "\n")

        // Communication
        communicationMode = profile.communicationMode
        communicationNotes = profile.communicationNotes ?? ""
        alexithymiaSettings = profile.alexithymiaSettings ?? AlexithymiaSettings()

        // Triggers & Strategies
        triggers = profile.triggers
        strategies = profile.soothingStrategies

        // Calibration
        skipCalibration = profile.baselineCalibration == nil
    }

    // MARK: - Computed Properties

    var progress: Double {
        let totalSteps = Double(ProfileCreationStep.allCases.count)
        let currentStepIndex = Double(currentStep.rawValue + 1)
        return currentStepIndex / totalSteps
    }

    var canGoNext: Bool {
        switch currentStep {
        case .basicInfo:
            return !name.isEmpty && age >= 2 && age <= 8
        case .sensoryPreferences:
            return true // Optional step
        case .communication:
            return true // Optional step
        case .triggers:
            return true // Optional step
        case .calibration:
            return true // Can skip calibration
        }
    }

    var canGoBack: Bool {
        return currentStep.rawValue > 0
    }

    var nextButtonTitle: String {
        switch currentStep {
        case .calibration:
            return skipCalibration ? "Skip & Finish" : "Finish"
        default:
            return "Next"
        }
    }

    var wizardTitle: String {
        return isEditingExistingProfile ? "Edit Profile" : "Create Profile"
    }

    // MARK: - Navigation

    func goNext() async {
        // Validate current step
        guard canGoNext else { return }

        // If on last step, save profile
        if currentStep == .calibration {
            await saveProfile()
            return
        }

        // Move to next step
        if let nextStep = ProfileCreationStep(rawValue: currentStep.rawValue + 1) {
            withAnimation {
                currentStep = nextStep
            }
        }
    }

    func goBack() {
        guard canGoBack else { return }

        if let previousStep = ProfileCreationStep(rawValue: currentStep.rawValue - 1) {
            withAnimation {
                currentStep = previousStep
            }
        }
    }

    // MARK: - Profile Creation

    private func saveProfile() async {
        do {
            var profile: ChildProfile

            if isEditingExistingProfile, let existing = existingProfile {
                // Update existing profile (preserves ID, createdAt, coRegulationHistory)
                profile = ChildProfile(
                    id: existing.id,
                    name: name,
                    age: age,
                    pronouns: pronouns.isEmpty ? nil : pronouns,
                    photoData: photoData,
                    profileColor: profileColor
                )
                profile.createdAt = existing.createdAt
                profile.coRegulationHistory = existing.coRegulationHistory
            } else {
                // Create new profile
                profile = ChildProfile(
                    name: name,
                    age: age,
                    pronouns: pronouns.isEmpty ? nil : pronouns,
                    photoData: photoData,
                    profileColor: profileColor
                )
            }

            // Add sensory preferences
            profile.sensoryPreferences = sensoryPreferences
            if !specificSensoryTriggers.isEmpty {
                profile.sensoryPreferences.specificTriggers = specificSensoryTriggers.components(separatedBy: "\n").filter { !$0.isEmpty }
            }

            // Add communication mode
            profile.communicationMode = communicationMode
            profile.communicationNotes = communicationNotes.isEmpty ? nil : communicationNotes

            // Add alexithymia settings
            profile.alexithymiaSettings = alexithymiaSettings

            // Add triggers and strategies
            profile.triggers = triggers
            profile.soothingStrategies = strategies

            // Save profile (create or update)
            if isEditingExistingProfile {
                try await profileManager.updateProfile(profile: profile)
            } else {
                try await profileManager.createProfile(profile: profile)
            }

            // Mark as complete
            isComplete = true

        } catch {
            self.error = error
            showError = true
        }
    }

    // MARK: - Photo Management

    func setPhoto(_ data: Data?) {
        photoData = data
    }

    // MARK: - Trigger Management

    func addTrigger(_ trigger: Trigger) {
        triggers.append(trigger)
    }

    func removeTrigger(id: UUID) {
        triggers.removeAll { $0.id == id }
    }

    // MARK: - Strategy Management

    func addStrategy(_ strategy: Strategy) {
        strategies.append(strategy)
    }

    func removeStrategy(id: UUID) {
        strategies.removeAll { $0.id == id }
    }
}

// MARK: - Profile Creation Steps

enum ProfileCreationStep: Int, CaseIterable {
    case basicInfo = 0
    case sensoryPreferences = 1
    case communication = 2
    case triggers = 3
    case calibration = 4

    var title: String {
        switch self {
        case .basicInfo: return "Basic Information"
        case .sensoryPreferences: return "Sensory Preferences"
        case .communication: return "Communication"
        case .triggers: return "Triggers & Strategies"
        case .calibration: return "Baseline Calibration"
        }
    }

    var description: String {
        switch self {
        case .basicInfo:
            return "Tell us about your child"
        case .sensoryPreferences:
            return "What are your child's sensory preferences?"
        case .communication:
            return "How does your child communicate?"
        case .triggers:
            return "What triggers dysregulation?"
        case .calibration:
            return "Let's capture a calm baseline (optional)"
        }
    }
}
