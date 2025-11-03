//
//  EmergencyResource.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.3 - Settings & Help System
//

import Foundation
import Combine

/// Supported regions for emergency resources
enum Region: String, CaseIterable {
    case unitedStates = "US"
    case unitedKingdom = "GB"
    case canada = "CA"
    case australia = "AU"
    case international = "INT"  // Available worldwide

    var displayName: String {
        switch self {
        case .unitedStates: return "United States"
        case .unitedKingdom: return "United Kingdom"
        case .canada: return "Canada"
        case .australia: return "Australia"
        case .international: return "International"
        }
    }
}

/// Represents an emergency resource or crisis hotline
struct EmergencyResource: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let phoneNumber: String
    let category: ResourceCategory
    let availability: String  // e.g., "24/7", "Mon-Fri 9am-5pm"
    let isNeurodiversityFocused: Bool
    let region: Region  // Which region this resource serves

    enum ResourceCategory: String, CaseIterable {
        case crisis = "Crisis Support"
        case autism = "Autism Support"
        case mental = "Mental Health"
        case local = "Local Resources"
    }

    // MARK: - United States Resources

    static let nationalSuicidePreventionLifeline = EmergencyResource(
        id: "us_988",
        name: "988 Suicide & Crisis Lifeline",
        description: "Free, confidential support for people in distress, prevention and crisis resources",
        phoneNumber: "988",
        category: .crisis,
        availability: "24/7",
        isNeurodiversityFocused: false,
        region: .unitedStates
    )

    static let autismCrisisLine = EmergencyResource(
        id: "us_autism_crisis",
        name: "Autism Crisis Line",
        description: "Specialized support for autistic individuals and families in crisis",
        phoneNumber: "1-800-273-8255",
        category: .autism,
        availability: "24/7",
        isNeurodiversityFocused: true,
        region: .unitedStates
    )

    static let nami = EmergencyResource(
        id: "us_nami",
        name: "NAMI HelpLine",
        description: "National Alliance on Mental Illness - Information and referrals",
        phoneNumber: "1-800-950-6264",
        category: .mental,
        availability: "Mon-Fri 10am-10pm ET",
        isNeurodiversityFocused: false,
        region: .unitedStates
    )

    static let crisisTextLine = EmergencyResource(
        id: "us_crisis_text",
        name: "Crisis Text Line",
        description: "Text-based crisis support - Text HOME to 741741",
        phoneNumber: "741741",
        category: .crisis,
        availability: "24/7",
        isNeurodiversityFocused: false,
        region: .unitedStates
    )

    static let autismSociety = EmergencyResource(
        id: "us_autism_society",
        name: "Autism Society Helpline",
        description: "Support, information, and referrals for autism community",
        phoneNumber: "1-800-328-8476",
        category: .autism,
        availability: "Mon-Fri 9am-5pm ET",
        isNeurodiversityFocused: true,
        region: .unitedStates
    )

    // MARK: - United Kingdom Resources

    static let samaritansUK = EmergencyResource(
        id: "uk_samaritans",
        name: "Samaritans",
        description: "24/7 emotional support for anyone struggling to cope",
        phoneNumber: "116 123",
        category: .crisis,
        availability: "24/7",
        isNeurodiversityFocused: false,
        region: .unitedKingdom
    )

    static let mindUK = EmergencyResource(
        id: "uk_mind",
        name: "Mind Infoline",
        description: "Mental health information and support",
        phoneNumber: "0300 123 3393",
        category: .mental,
        availability: "Mon-Fri 9am-6pm",
        isNeurodiversityFocused: false,
        region: .unitedKingdom
    )

    static let nationalAutisticSocietyUK = EmergencyResource(
        id: "uk_nas",
        name: "National Autistic Society Helpline",
        description: "Support for autistic people and families",
        phoneNumber: "0808 800 4104",
        category: .autism,
        availability: "Mon-Fri 9am-5pm",
        isNeurodiversityFocused: true,
        region: .unitedKingdom
    )

    // MARK: - Canada Resources

    static let crisisCenterCanada = EmergencyResource(
        id: "ca_crisis",
        name: "Crisis Services Canada",
        description: "24/7 support for people in distress",
        phoneNumber: "1-833-456-4566",
        category: .crisis,
        availability: "24/7",
        isNeurodiversityFocused: false,
        region: .canada
    )

    static let autismCanada = EmergencyResource(
        id: "ca_autism",
        name: "Autism Canada",
        description: "Support and information for autism community",
        phoneNumber: "1-800-983-1795",
        category: .autism,
        availability: "Mon-Fri 9am-5pm ET",
        isNeurodiversityFocused: true,
        region: .canada
    )

    // MARK: - Australia Resources

    static let lifelineAustralia = EmergencyResource(
        id: "au_lifeline",
        name: "Lifeline Australia",
        description: "24/7 crisis support and suicide prevention",
        phoneNumber: "13 11 14",
        category: .crisis,
        availability: "24/7",
        isNeurodiversityFocused: false,
        region: .australia
    )

    static let autismAwareness = EmergencyResource(
        id: "au_autism",
        name: "Autism Awareness Australia",
        description: "Support and advocacy for autism community",
        phoneNumber: "1300 288 476",
        category: .autism,
        availability: "Mon-Fri 9am-5pm AEST",
        isNeurodiversityFocused: true,
        region: .australia
    )

    /// All default emergency resources
    static let allResources: [EmergencyResource] = [
        // US
        .nationalSuicidePreventionLifeline,
        .autismCrisisLine,
        .crisisTextLine,
        .nami,
        .autismSociety,
        // UK
        .samaritansUK,
        .mindUK,
        .nationalAutisticSocietyUK,
        // Canada
        .crisisCenterCanada,
        .autismCanada,
        // Australia
        .lifelineAustralia,
        .autismAwareness
    ]

    /// Get resources for a specific region
    static func resources(for region: Region) -> [EmergencyResource] {
        return allResources.filter { $0.region == region || $0.region == .international }
    }

    /// Resources grouped by category for a specific region
    static func groupedByCategory(for region: Region) -> [ResourceCategory: [EmergencyResource]] {
        Dictionary(grouping: resources(for: region), by: { $0.category })
    }
}

/// Manager for emergency resources and user-added local contacts
class EmergencyResourcesManager: ObservableObject {

    // MARK: - Published Properties

    /// User-added local emergency contacts
    @Published var localContacts: [EmergencyResource] = []

    /// Currently detected region
    @Published var currentRegion: Region = .unitedStates

    // MARK: - Computed Properties

    /// Region-specific resources (filtered + local)
    var regionalResources: [EmergencyResource] {
        return EmergencyResource.resources(for: currentRegion) + localContacts
    }

    /// All resources (unfiltered + local)
    var allResourcesWithLocal: [EmergencyResource] {
        return EmergencyResource.allResources + localContacts
    }

    /// Resources by category for current region including local
    var resourcesByCategory: [EmergencyResource.ResourceCategory: [EmergencyResource]] {
        return Dictionary(grouping: regionalResources, by: { $0.category })
    }

    // MARK: - Public Methods

    /// Detect user's region based on device locale
    func detectRegion() {
        let countryCode = Locale.current.region?.identifier ?? "US"

        switch countryCode {
        case "US":
            currentRegion = .unitedStates
        case "GB":
            currentRegion = .unitedKingdom
        case "CA":
            currentRegion = .canada
        case "AU":
            currentRegion = .australia
        default:
            // Default to US for unsupported regions
            currentRegion = .unitedStates
        }

        print("🌍 Detected region: \(currentRegion.displayName) (\(countryCode))")
    }

    /// Add a local emergency contact
    func addLocalContact(name: String, phoneNumber: String, description: String) {
        let contact = EmergencyResource(
            id: UUID().uuidString,
            name: name,
            description: description,
            phoneNumber: phoneNumber,
            category: .local,
            availability: "User-defined",
            isNeurodiversityFocused: false,
            region: currentRegion
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
