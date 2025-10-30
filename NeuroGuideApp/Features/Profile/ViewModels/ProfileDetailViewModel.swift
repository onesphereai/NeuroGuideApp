//
//  ProfileDetailViewModel.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Enhancement)
//

import Foundation
import Combine

/// View model for profile detail view
@MainActor
class ProfileDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var profile: ChildProfile

    // MARK: - Dependencies

    private let profileManager = ChildProfileManager.shared

    // MARK: - Initialization

    init(profile: ChildProfile) {
        self.profile = profile
    }

    // MARK: - Public Methods

    /// Reload profile from storage
    func reloadProfile() async {
        do {
            if let updatedProfile = try await profileManager.getProfile() {
                profile = updatedProfile
            }
        } catch {
            print("Error reloading profile: \(error)")
        }
    }
}
