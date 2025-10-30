//
//  PrivacyService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation

/// Protocol for verifying privacy guarantees for ML processing
protocol PrivacyServiceProtocol {

    /// Check if data is processed locally
    /// - Returns: True if all ML processing happens on-device
    func isDataProcessedLocally() -> Bool

    /// Get data storage location
    /// - Returns: Current storage location
    func getDataStorageLocation() -> StorageLocation

    /// Verify privacy status
    /// - Returns: Complete privacy verification result
    func verifyPrivacyStatus() -> PrivacyVerificationResult

    /// Get privacy status for display
    /// - Returns: Current privacy status
    func getPrivacyStatus() -> PrivacyStatus

    /// Generate privacy badge text
    /// - Returns: Badge text for UI display
    func showPrivacyBadge() -> String

    /// Start network monitoring (to detect any network calls during ML)
    func startNetworkMonitoring()

    /// Stop network monitoring
    func stopNetworkMonitoring()

    /// Check if network activity was detected
    /// - Returns: True if any network activity detected during monitoring
    func wasNetworkActivityDetected() -> Bool
}
