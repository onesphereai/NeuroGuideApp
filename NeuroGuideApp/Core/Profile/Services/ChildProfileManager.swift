//
//  ChildProfileManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation
import Combine

/// Main implementation of ChildProfileService
/// Manages child profile storage using secure encrypted storage
@MainActor
class ChildProfileManager: ChildProfileService, ObservableObject {
    // MARK: - Singleton

    static let shared = ChildProfileManager()

    // MARK: - Published Properties

    @Published private(set) var currentProfile: ChildProfile?
    @Published private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private let secureStorage: SecureStorageService
    private let storageKey = SecureStorageKeys.childProfile
    private let profilesListKey = SecureStorageKeys.profilesList
    private let activeProfileIDKey = SecureStorageKeys.activeProfileID

    // MARK: - Initialization

    init(secureStorage: SecureStorageService = SecureStorageManager.shared) {
        self.secureStorage = secureStorage
    }

    // MARK: - ChildProfileService Implementation

    func createProfile(profile: ChildProfile) async throws {
        // Validate profile
        guard !profile.name.isEmpty else {
            throw ProfileError.invalidName
        }

        guard profile.age >= 2 && profile.age <= 8 else {
            throw ProfileError.invalidAge(age: profile.age)
        }

        // Save to secure storage
        isLoading = true
        defer { isLoading = false }

        do {
            // Save to profile-specific key
            let profileKey = profileStorageKey(for: profile.id)
            try await secureStorage.save(profile, forKey: profileKey)

            // Add to profiles list
            try await addProfileToList(profile)

            // Set as active profile
            try await setActiveProfile(profile)

            currentProfile = profile
            print("✅ Profile created: \(profile.name)")
        } catch {
            throw ProfileError.saveFailed(underlying: error)
        }
    }

    func getProfile() async throws -> ChildProfile? {
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await secureStorage.load(forKey: storageKey, as: ChildProfile.self)
            currentProfile = profile
            return profile
        } catch {
            // Check if file exists - if not, return nil (no profile yet)
            if secureStorage.exists(forKey: storageKey) {
                throw ProfileError.loadFailed(underlying: error)
            }
            return nil
        }
    }

    func updateProfile(profile: ChildProfile) async throws {
        // Create updated profile with new timestamp
        var updatedProfile = profile
        updatedProfile.updateTimestamp()

        isLoading = true
        defer { isLoading = false }

        do {
            try await secureStorage.save(updatedProfile, forKey: storageKey)
            currentProfile = updatedProfile
        } catch {
            throw ProfileError.saveFailed(underlying: error)
        }
    }

    func deleteProfile() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await secureStorage.delete(forKey: storageKey)
            currentProfile = nil
        } catch {
            throw ProfileError.deleteFailed(underlying: error)
        }
    }

    func isProfileComplete() async -> Bool {
        guard let profile = try? await getProfile() else {
            return false
        }
        return profile.isComplete()
    }

    func hasProfile() async -> Bool {
        return secureStorage.exists(forKey: storageKey)
    }

    // MARK: - Additional Helper Methods

    /// Load profile synchronously from cache
    func getCachedProfile() -> ChildProfile? {
        return currentProfile
    }

    /// Add a trigger to the current profile
    func addTrigger(_ trigger: Trigger) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        guard !trigger.description.isEmpty else {
            throw ProfileError.invalidTrigger(reason: "Description cannot be empty")
        }

        profile.addTrigger(trigger)
        try await updateProfile(profile: profile)
    }

    /// Remove a trigger from the current profile
    func removeTrigger(id: UUID) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        profile.removeTrigger(id: id)
        try await updateProfile(profile: profile)
    }

    /// Add a strategy to the current profile
    func addStrategy(_ strategy: Strategy) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        guard !strategy.description.isEmpty else {
            throw ProfileError.invalidStrategy(reason: "Description cannot be empty")
        }

        profile.addStrategy(strategy)
        try await updateProfile(profile: profile)
    }

    /// Remove a strategy from the current profile
    func removeStrategy(id: UUID) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        profile.removeStrategy(id: id)
        try await updateProfile(profile: profile)
    }

    /// Update strategy effectiveness rating
    func updateStrategyEffectiveness(id: UUID, rating: Int) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        profile.updateStrategyEffectiveness(id: id, rating: rating)
        try await updateProfile(profile: profile)
    }

    /// Update sensory preferences
    func updateSensoryPreferences(_ preferences: SensoryPreferences) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        profile.sensoryPreferences = preferences
        try await updateProfile(profile: profile)
    }

    /// Update communication mode
    func updateCommunicationMode(_ mode: CommunicationMode, notes: String? = nil) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        profile.communicationMode = mode
        profile.communicationNotes = notes
        try await updateProfile(profile: profile)
    }

    /// Update alexithymia settings
    func updateAlexithymiaSettings(_ settings: AlexithymiaSettings) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        profile.alexithymiaSettings = settings
        try await updateProfile(profile: profile)
    }

    /// Update baseline calibration
    func updateBaselineCalibration(_ calibration: BaselineCalibration) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        profile.baselineCalibration = calibration
        try await updateProfile(profile: profile)
    }

    /// Record a co-regulation session
    func recordCoRegulationSession(strategies: [UUID], helpfulness: Int) async throws {
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        profile.coRegulationHistory.recordSession(strategies: strategies, helpfulness: helpfulness)
        try await updateProfile(profile: profile)
    }

    // MARK: - Multi-Profile Support

    func getAllProfiles() async throws -> [ChildProfile] {
        isLoading = true
        defer { isLoading = false }

        // Try to load profiles list
        do {
            guard let profileIDs = try await secureStorage.load(
                forKey: profilesListKey,
                as: [UUID].self
            ) else {
                return []
            }

            var profiles: [ChildProfile] = []
            for id in profileIDs {
                if let profile = try? await getProfile(id: id) {
                    profiles.append(profile)
                }
            }

            return profiles
        } catch {
            // If no profiles list exists, return empty array
            return []
        }
    }

    func setActiveProfile(_ profile: ChildProfile) async throws {
        // Save the profile ID as active
        try await secureStorage.save(profile.id, forKey: activeProfileIDKey)

        // Also save to the legacy single-profile key for backward compatibility
        try await secureStorage.save(profile, forKey: storageKey)

        currentProfile = profile
        print("✅ Active profile set: \(profile.name)")
    }

    func getProfile(id: UUID) async throws -> ChildProfile? {
        let profileKey = profileStorageKey(for: id)

        do {
            let profile = try await secureStorage.load(forKey: profileKey, as: ChildProfile.self)
            return profile
        } catch {
            return nil
        }
    }

    func deleteProfile(id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        // Delete the profile
        let profileKey = profileStorageKey(for: id)
        try await secureStorage.delete(forKey: profileKey)

        // Update profiles list
        if var profileIDs = try? await secureStorage.load(
            forKey: profilesListKey,
            as: [UUID].self
        ) {
            profileIDs.removeAll { $0 == id }
            try await secureStorage.save(profileIDs, forKey: profilesListKey)
        }

        // If this was the active profile, clear it
        if currentProfile?.id == id {
            currentProfile = nil
            try? await secureStorage.delete(forKey: activeProfileIDKey)
            try? await secureStorage.delete(forKey: storageKey)
        }

        print("✅ Profile deleted: \(id)")
    }

    // MARK: - Private Helpers

    private func profileStorageKey(for id: UUID) -> String {
        return "child.profile.\(id.uuidString)"
    }

    private func addProfileToList(_ profile: ChildProfile) async throws {
        var profileIDs = (try? await secureStorage.load(
            forKey: profilesListKey,
            as: [UUID].self
        )) ?? []

        if !profileIDs.contains(profile.id) {
            profileIDs.append(profile.id)
            try await secureStorage.save(profileIDs, forKey: profilesListKey)
        }
    }
}

// MARK: - Storage Keys Extension

extension SecureStorageKeys {
    static let childProfile = "child.profile"
    static let profilesList = "child.profiles.list"
    static let activeProfileID = "child.profile.active.id"
}
