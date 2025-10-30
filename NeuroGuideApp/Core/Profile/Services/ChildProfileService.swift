//
//  ChildProfileService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation

/// Service for managing child profiles
protocol ChildProfileService {
    /// Create a new child profile
    func createProfile(profile: ChildProfile) async throws

    /// Get the current child profile
    func getProfile() async throws -> ChildProfile?

    /// Update an existing profile
    func updateProfile(profile: ChildProfile) async throws

    /// Delete the current profile
    func deleteProfile() async throws

    /// Check if profile is complete (has required fields)
    func isProfileComplete() async -> Bool

    /// Check if a profile exists
    func hasProfile() async -> Bool
}
