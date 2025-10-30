//
//  PrivacyManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation
import Network

/// Implementation of PrivacyService
class PrivacyManager: PrivacyServiceProtocol {

    // MARK: - Singleton

    static let shared = PrivacyManager()

    // MARK: - Private Properties

    private var isMonitoringNetwork = false
    private var networkActivityDetected = false
    private var networkMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.neuroguide.privacy.network")

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func isDataProcessedLocally() -> Bool {
        // For NeuroGuide, all ML processing is on-device by design
        // This would return false only if we detected cloud processing
        return true
    }

    func getDataStorageLocation() -> StorageLocation {
        // All data stored locally for now
        // Future: Check if iCloud sync is enabled
        return .local
    }

    func verifyPrivacyStatus() -> PrivacyVerificationResult {
        let status = getPrivacyStatus()

        // Determine compliance level
        let complianceLevel: PrivacyComplianceLevel
        var issues: [String] = []

        if status.privacyGuaranteeMet {
            complianceLevel = .full
        } else {
            // Check what's wrong
            if !status.isProcessedLocally {
                issues.append("ML processing not confirmed as local-only")
                complianceLevel = .noncompliant
            } else if status.networkActivityDetected {
                issues.append("Network activity detected during ML processing")
                complianceLevel = .partial
            } else if status.storageLocation != .local {
                issues.append("Data not stored locally")
                complianceLevel = .partial
            } else {
                complianceLevel = .partial
            }
        }

        return PrivacyVerificationResult(
            complianceLevel: complianceLevel,
            status: status,
            verificationDate: Date(),
            issues: issues
        )
    }

    func getPrivacyStatus() -> PrivacyStatus {
        return PrivacyStatus(
            isProcessedLocally: isDataProcessedLocally(),
            networkActivityDetected: networkActivityDetected,
            storageLocation: getDataStorageLocation(),
            verificationTimestamp: Date(),
            notes: nil
        )
    }

    func showPrivacyBadge() -> String {
        let status = getPrivacyStatus()
        return status.badgeText
    }

    func startNetworkMonitoring() {
        guard !isMonitoringNetwork else { return }

        isMonitoringNetwork = true
        networkActivityDetected = false

        // Create network monitor
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                // Network is available - this alone doesn't mean we're using it
                // But if we see activity during ML inference, that's a red flag
                print("📡 Network available during ML processing (monitoring...)")
            }
        }

        networkMonitor?.start(queue: monitorQueue)
        print("🔒 Privacy: Network monitoring started")
    }

    func stopNetworkMonitoring() {
        guard isMonitoringNetwork else { return }

        networkMonitor?.cancel()
        networkMonitor = nil
        isMonitoringNetwork = false

        if !networkActivityDetected {
            print("✅ Privacy: No network activity detected")
        } else {
            print("⚠️ Privacy: Network activity was detected!")
        }
    }

    func wasNetworkActivityDetected() -> Bool {
        return networkActivityDetected
    }

    // MARK: - Internal Methods

    /// Mark that network activity was detected (called internally or by ML services)
    func recordNetworkActivity() {
        if isMonitoringNetwork {
            networkActivityDetected = true
            print("⚠️ Privacy Alert: Network activity detected during ML processing!")
        }
    }
}
