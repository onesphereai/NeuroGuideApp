//
//  EmotionProfileManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation
import Combine

/// Manager for emotion expression profiles
@MainActor
class EmotionProfileManager: EmotionProfileService, ObservableObject {
    // MARK: - Singleton

    static let shared = EmotionProfileManager()

    // MARK: - Published Properties

    @Published private(set) var profiles: [UUID: EmotionExpressionProfile] = [:]

    // MARK: - Private Properties

    private let storage: EmotionStorageService
    private let storageKey = "EmotionExpressionProfiles"

    // MARK: - Initialization

    init(storage: EmotionStorageService = UserDefaults.standard) {
        self.storage = storage
        loadProfiles()
    }

    // MARK: - Profile Management

    func getProfile(childID: UUID) async throws -> EmotionExpressionProfile {
        if let existing = profiles[childID] {
            return existing
        }

        // Create new profile
        let newProfile = EmotionExpressionProfile(childID: childID)
        profiles[childID] = newProfile
        try await save()

        return newProfile
    }

    func updateProfile(childID: UUID, profile: EmotionExpressionProfile) async throws {
        profiles[childID] = profile
        try await save()

        print("✅ Updated emotion expression profile for child \(childID)")
    }

    func isProfileComplete(childID: UUID) async -> Bool {
        guard let profile = profiles[childID] else {
            return false
        }

        return profile.isComplete
    }

    // MARK: - Storage

    private func loadProfiles() {
        guard let data = storage.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([UUID: EmotionExpressionProfile].self, from: data) else {
            return
        }

        profiles = decoded
        print("📊 Loaded \(profiles.count) emotion expression profiles")
    }

    private func save() async throws {
        let data = try JSONEncoder().encode(profiles)
        storage.set(data, forKey: storageKey)
    }
}
