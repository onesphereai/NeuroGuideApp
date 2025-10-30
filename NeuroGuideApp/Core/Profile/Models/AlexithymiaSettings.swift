//
//  AlexithymiaSettings.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import Foundation

/// Settings related to alexithymia (difficulty identifying emotions)
/// Informs how the app approaches emotion vocabulary and labeling
struct AlexithymiaSettings: Codable {
    /// Does the child have difficulty naming their own feelings?
    var hasDifficultyNamingFeelings: Bool

    /// Prefer body cues over emotion labels (e.g., "tight chest" vs "anxious")
    var preferBodyCues: Bool

    /// Additional notes about the child's emotional awareness
    var notes: String?

    init(
        hasDifficultyNamingFeelings: Bool = false,
        preferBodyCues: Bool = false,
        notes: String? = nil
    ) {
        self.hasDifficultyNamingFeelings = hasDifficultyNamingFeelings
        self.preferBodyCues = preferBodyCues
        self.notes = notes
    }

    /// Determine if body-based language should be prioritized
    func shouldUseBodyLanguage() -> Bool {
        return hasDifficultyNamingFeelings || preferBodyCues
    }
}
