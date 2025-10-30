//
//  EmergencyResource.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.3 - Settings & Help System
//

import Foundation
import Combine

/// Represents an emergency resource or crisis hotline
struct EmergencyResource: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let phoneNumber: String
    let category: ResourceCategory
    let availability: String  // e.g., "24/7", "Mon-Fri 9am-5pm"
    let isNeurodiversityFocused: Bool

    enum ResourceCategory: String, CaseIterable {
        case crisis = "Crisis Support"
        case autism = "Autism Support"
        case mental = "Mental Health"
        case local = "Local Resources"
    }

    // MARK: - Predefined Resources

    static let nationalSuicidePreventionLifeline = EmergencyResource(
        id: "nspl",
        name: "988 Suicide & Crisis Lifeline",
        description: "Free, confidential support for people in distress, prevention and crisis resources",
        phoneNumber: "988",
        category: .crisis,
        availability: "24/7",
        isNeurodiversityFocused: false
    )

    static let autismCrisisLine = EmergencyResource(
        id: "autism_crisis",
        name: "Autism Crisis Line",
        description: "Specialized support for autistic individuals and families in crisis",
        phoneNumber: "1-800-273-8255",
        category: .autism,
        availability: "24/7",
        isNeurodiversityFocused: true
    )

    static let nami = EmergencyResource(
        id: "nami",
        name: "NAMI HelpLine",
        description: "National Alliance on Mental Illness - Information and referrals",
        phoneNumber: "1-800-950-6264",
        category: .mental,
        availability: "Mon-Fri 10am-10pm ET",
        isNeurodiversityFocused: false
    )

    static let crisisTextLine = EmergencyResource(
        id: "crisis_text",
        name: "Crisis Text Line",
        description: "Text-based crisis support - Text HOME to 741741",
        phoneNumber: "741741",
        category: .crisis,
        availability: "24/7",
        isNeurodiversityFocused: false
    )

    static let autismSociety = EmergencyResource(
        id: "autism_society",
        name: "Autism Society Helpline",
        description: "Support, information, and referrals for autism community",
        phoneNumber: "1-800-328-8476",
        category: .autism,
        availability: "Mon-Fri 9am-5pm ET",
        isNeurodiversityFocused: true
    )

    /// All default emergency resources
    static let defaultResources: [EmergencyResource] = [
        .nationalSuicidePreventionLifeline,
        .autismCrisisLine,
        .crisisTextLine,
        .nami,
        .autismSociety
    ]

    /// Resources grouped by category
    static func groupedByCategory() -> [ResourceCategory: [EmergencyResource]] {
        Dictionary(grouping: defaultResources, by: { $0.category })
    }
}

/// Manager for emergency resources and user-added local contacts
class EmergencyResourcesManager: ObservableObject {

    // MARK: - Published Properties

    /// User-added local emergency contacts
    @Published var localContacts: [EmergencyResource] = []

    // MARK: - Computed Properties

    /// All resources (default + local)
    var allResources: [EmergencyResource] {
        return EmergencyResource.defaultResources + localContacts
    }

    /// Resources by category including local
    var resourcesByCategory: [EmergencyResource.ResourceCategory: [EmergencyResource]] {
        return Dictionary(grouping: allResources, by: { $0.category })
    }

    // MARK: - Public Methods

    /// Add a local emergency contact
    func addLocalContact(name: String, phoneNumber: String, description: String) {
        let contact = EmergencyResource(
            id: UUID().uuidString,
            name: name,
            description: description,
            phoneNumber: phoneNumber,
            category: .local,
            availability: "User-defined",
            isNeurodiversityFocused: false
        )
        localContacts.append(contact)
        saveLocalContacts()
    }

    /// Remove a local contact
    func removeLocalContact(_ contact: EmergencyResource) {
        localContacts.removeAll { $0.id == contact.id }
        saveLocalContacts()
    }

    /// Load local contacts from UserDefaults
    func loadLocalContacts() {
        // TODO: Implement persistence
        // For now, local contacts are session-only
    }

    /// Save local contacts to UserDefaults
    private func saveLocalContacts() {
        // TODO: Implement persistence
    }
}
