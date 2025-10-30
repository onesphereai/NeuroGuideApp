//
//  PrivacyStatus.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation

/// Privacy verification status for ML processing
struct PrivacyStatus {

    // MARK: - Properties

    /// Whether data is processed locally
    let isProcessedLocally: Bool

    /// Whether any network activity detected during ML processing
    let networkActivityDetected: Bool

    /// Data storage location
    let storageLocation: StorageLocation

    /// Privacy verification timestamp
    let verificationTimestamp: Date

    /// Additional privacy notes
    let notes: String?

    // MARK: - Computed Properties

    /// Whether privacy guarantees are met
    var privacyGuaranteeMet: Bool {
        return isProcessedLocally && !networkActivityDetected && storageLocation == .local
    }

    /// Privacy badge text
    var badgeText: String {
        if privacyGuaranteeMet {
            return "🔒 Processing Locally"
        } else {
            return "⚠️ Privacy Check Failed"
        }
    }

    /// Detailed privacy status message
    var statusMessage: String {
        if privacyGuaranteeMet {
            return "All ML processing happens on your device. Your data never leaves your iPhone."
        } else {
            var issues: [String] = []
            if !isProcessedLocally {
                issues.append("Data not processed locally")
            }
            if networkActivityDetected {
                issues.append("Network activity detected")
            }
            if storageLocation != .local {
                issues.append("Data stored remotely")
            }
            return "Privacy issues detected: \(issues.joined(separator: ", "))"
        }
    }

    // MARK: - Initialization

    init(
        isProcessedLocally: Bool = true,
        networkActivityDetected: Bool = false,
        storageLocation: StorageLocation = .local,
        verificationTimestamp: Date = Date(),
        notes: String? = nil
    ) {
        self.isProcessedLocally = isProcessedLocally
        self.networkActivityDetected = networkActivityDetected
        self.storageLocation = storageLocation
        self.verificationTimestamp = verificationTimestamp
        self.notes = notes
    }
}

/// Data storage location types
enum StorageLocation: String, Codable {
    case local = "local"           // On-device only
    case iCloudPrivate = "icloud"  // iCloud private storage
    case remote = "remote"         // Remote server (should not be used)

    var displayName: String {
        switch self {
        case .local:
            return "On Device"
        case .iCloudPrivate:
            return "iCloud (Private)"
        case .remote:
            return "Remote Server"
        }
    }

    var isPrivacyCompliant: Bool {
        switch self {
        case .local, .iCloudPrivate:
            return true
        case .remote:
            return false
        }
    }

    var description: String {
        switch self {
        case .local:
            return "All data stored locally on your device"
        case .iCloudPrivate:
            return "Data encrypted and stored in your private iCloud"
        case .remote:
            return "Data stored on remote servers (not recommended)"
        }
    }
}

/// Privacy compliance levels
enum PrivacyComplianceLevel: String {
    case full = "full"               // All guarantees met
    case partial = "partial"         // Some guarantees met
    case noncompliant = "noncompliant" // Privacy guarantees not met

    var displayName: String {
        switch self {
        case .full:
            return "Fully Compliant"
        case .partial:
            return "Partially Compliant"
        case .noncompliant:
            return "Non-Compliant"
        }
    }

    var emoji: String {
        switch self {
        case .full:
            return "✅"
        case .partial:
            return "⚠️"
        case .noncompliant:
            return "❌"
        }
    }
}

/// Privacy verification result
struct PrivacyVerificationResult {
    let complianceLevel: PrivacyComplianceLevel
    let status: PrivacyStatus
    let verificationDate: Date
    let issues: [String]

    var isPassing: Bool {
        return complianceLevel == .full
    }

    var summary: String {
        return "\(complianceLevel.emoji) \(complianceLevel.displayName)"
    }
}
